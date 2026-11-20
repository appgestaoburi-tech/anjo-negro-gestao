import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cliente.dart';
import '../models/comanda.dart';
import '../models/perfil_usuario.dart';
import '../models/servico.dart';

class ComandaRepository {
  ComandaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('comandas');

  /// Administrador vê todas as abertas; os demais, só as próprias.
  Stream<List<Comanda>> observarAbertas(PerfilUsuario perfil) {
    Query<Map<String, dynamic>> consulta =
        _col.where('status', isEqualTo: 'aberta');

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map((snap) {
      final lista = snap.docs.map(Comanda.doDocumento).toList();
      lista.sort((a, b) => b.numero.compareTo(a.numero));
      return lista;
    });
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
        'subtotalServicosCentavos': 0,
        'subtotalProdutosCentavos': 0,
        'descontoCentavos': 0,
        'totalCentavos': 0,
        'pagoCentavos': 0,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });

    return novaRef.id;
  }

  Future<void> _alterarServicos(
    String id,
    List<ItemComanda> Function(List<ItemComanda>) transforma,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(snap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final novos = transforma(c.servicos);
      final subtotal = novos.fold<int>(0, (soma, i) => soma + i.precoCentavos);
      final total =
          subtotal + c.subtotalProdutosCentavos - c.descontoCentavos;

      tx.update(ref, {
        'servicos': novos.map((i) => i.paraMapa()).toList(),
        'subtotalServicosCentavos': subtotal,
        'totalCentavos': total,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

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
    return _alterarServicos(comandaId, (lista) => [...lista, item]);
  }

  Future<void> removerItem(String comandaId, String itemId) {
    return _alterarServicos(
      comandaId,
      (lista) => lista.where((i) => i.id != itemId).toList(),
    );
  }

  /// Só serviços "a partir de" podem ter o preço alterado, e só para cima.
  Future<void> ajustarPreco(String comandaId, String itemId, int novo) {
    return _alterarServicos(comandaId, (lista) {
      return lista.map((i) {
        if (i.id != itemId) return i;
        if (!i.aPartir) throw Exception('O preço deste serviço é fixo.');
        if (novo < i.precoCatalogoCentavos) {
          throw Exception('O valor não pode ser menor que o do catálogo.');
        }
        return i.comPreco(novo);
      }).toList();
    });
  }

  /// Cancela sem apagar: o histórico fica registrado.
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
          'Não é possível cancelar uma comanda com pagamento registrado.',
        );
      }

      tx.update(ref, {
        'status': 'cancelada',
        'motivoCancelamento': motivo,
        'canceladoPor': perfil.uid,
        'canceladoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    });
  }
}
