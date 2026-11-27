import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/parametros.dart';
import '../models/cliente.dart';
import '../models/comanda.dart';
import '../models/perfil_usuario.dart';
import '../models/produto.dart';
import '../models/servico.dart';
import '../utils/datas.dart';
import '../utils/percentual.dart';
import '../utils/totais_comanda.dart';
import 'pacote_uso_repository.dart';

part 'comanda_repository_desconto.dart';
part 'comanda_repository_produtos.dart';

class ComandaRepository {
  ComandaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('comandas');

  CollectionReference<Map<String, dynamic>> get _produtos =>
      _firestore.collection('produtos');

  List<Comanda> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(Comanda.doDocumento).toList();
    lista.sort((a, b) => b.numero.compareTo(a.numero));
    return lista;
  }

  /// Administrador vê todas as abertas; os demais, só as próprias.
  Stream<List<Comanda>> observarAbertas(PerfilUsuario perfil) {
    Query<Map<String, dynamic>> consulta =
        _col.where('status', isEqualTo: 'aberta');

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map(_ordenar);
  }

  /// Comandas finalizadas hoje (administrador: todas; demais: as próprias).
  Stream<List<Comanda>> observarPagasHoje(PerfilUsuario perfil) {
    Query<Map<String, dynamic>> consulta = _col
        .where('status', isEqualTo: 'paga')
        .where('finalizadaDia', isEqualTo: diaIso(DateTime.now()));

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map(_ordenar);
  }

  /// Comandas abertas com pedido de desconto aguardando o administrador.
  Stream<List<Comanda>> observarPendentes() {
    return _col
        .where('status', isEqualTo: 'aberta')
        .where('descontoStatus', isEqualTo: 'pendente')
        .snapshots()
        .map(_ordenar);
  }

  Stream<Comanda?> observarUma(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? Comanda.doDocumento(d) : null);
  }

  /// Abre a comanda e gera o número sequencial em uma única transação.
  Future<String> criar(PerfilUsuario perfil, {Cliente? cliente}) async {
    final contador = _firestore.collection('contadores').doc('comandas');
    final novaRef = _col.doc();

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(contador);
      final numero =
          snap.exists ? ((snap.data()?['proximo'] as num?)?.toInt() ?? 1) : 1;

      if (snap.exists) {
        tx.update(contador, {'proximo': numero + 1});
      } else {
        tx.set(contador, {'proximo': 2});
      }

      tx.set(novaRef, {
        'numero': numero,
        'status': 'aberta',
        'barbeiroUid': perfil.uid,
        'barbeiroNome': perfil.nome,
        'clienteId': cliente?.id ?? '',
        'clienteNome': cliente?.nome ?? '',
        'servicos': <Map<String, dynamic>>[],
        'produtos': <Map<String, dynamic>>[],
        'subtotalServicosCentavos': 0,
        'subtotalProdutosCentavos': 0,
        'descontoBp': 0,
        'descontoCentavos': 0,
        'descontoAprovadoBp': 0,
        'descontoStatus': '',
        'descontoSolicitadoBp': 0,
        'totalCentavos': 0,
        'pagoCentavos': 0,
        'valorUsosCentavos': 0,
        'coberta': false,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });

    return novaRef.id;
  }

  Map<String, dynamic> _camposAtualizados(
    List<ItemComanda> servicos,
    List<ItemProduto> produtos,
    int descontoBp,
    int pagoCentavos,
  ) {
    return camposTotais(servicos, produtos, descontoBp, pagoCentavos);
  }

  Future<void> _alterar(
    String id,
    Map<String, dynamic> Function(Comanda c) monta,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      tx.update(ref, monta(c));
    });
  }

  // ---------------- Serviços ----------------

  Future<void> adicionarServico(String comandaId, Servico s) {
    final item = ItemComanda(
      id: _col.doc().id,
      servicoId: s.id,
      nome: s.nome,
      categoria: s.categoria,
      precoCatalogoCentavos: s.precoCentavos,
      precoCentavos: s.precoCentavos,
      aPartir: s.aPartir,
    );

    return _alterar(
      comandaId,
      (c) => _camposAtualizados(
        [...c.servicos, item],
        c.produtos,
        c.descontoBp,
        c.pagoCentavos,
      ),
    );
  }

  /// Remover um uso de pacote devolve o uso ao pacote.
  Future<void> removerServico(String comandaId, String itemId) async {
    final snap = await _col.doc(comandaId).get();

    if (snap.exists) {
      final c = Comanda.doDocumento(snap);
      final alvo = c.servicos.where((i) => i.id == itemId).toList();

      if (alvo.isNotEmpty && alvo.first.ehUso) {
        await PacoteUsoRepository(firestore: _firestore)
            .removerUso(comandaId, itemId);
        return;
      }
    }

    await _alterar(comandaId, (c) {
      final servicos = c.servicos.where((i) => i.id != itemId).toList();
      return _camposAtualizados(
        servicos,
        c.produtos,
        servicos.isEmpty ? 0 : c.descontoBp,
        c.pagoCentavos,
      );
    });
  }

  /// Só serviços "a partir de" podem ter o preço alterado, e só para cima.
  Future<void> ajustarPreco(String comandaId, String itemId, int novo) {
    return _alterar(comandaId, (c) {
      final servicos = c.servicos.map((i) {
        if (i.id != itemId) return i;
        if (!i.aPartir) throw Exception('O preço deste serviço é fixo.');
        if (novo < i.precoCatalogoCentavos) {
          throw Exception('O valor não pode ser menor que o do catálogo.');
        }
        return i.comPreco(novo);
      }).toList();

      return _camposAtualizados(
        servicos,
        c.produtos,
        c.descontoBp,
        c.pagoCentavos,
      );
    });
  }

  // ---------------- Cancelamento ----------------

  /// Cancela sem apagar: o histórico fica registrado. Os usos de pacote
  /// lançados na comanda são devolvidos aos pacotes.
  Future<void> cancelar(
    String id,
    PerfilUsuario perfil, {
    String motivo = '',
  }) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (c.pagoCentavos > 0) {
        throw Exception(
          'Não é possível cancelar uma comanda com pagamento registrado. '
          'Peça ao administrador para estornar o pagamento.',
        );
      }

      final usos = c.servicos.where((i) => i.ehUso).toList();
      final escritas = usos.isEmpty
          ? <Escrita>[]
          : await prepararLiberacoes(tx, _firestore, usos);

      tx.update(ref, {
        'status': 'cancelada',
        'motivoCancelamento': motivo,
        'canceladoPor': perfil.uid,
        'canceladoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      for (final e in escritas) {
        e(tx);
      }
    });
  }
}
