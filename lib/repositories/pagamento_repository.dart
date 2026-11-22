import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/formas_pagamento.dart';
import '../models/comanda.dart';
import '../models/pagamento.dart';
import '../models/perfil_usuario.dart';
import '../models/produto.dart';
import '../utils/datas.dart';
import '../utils/dinheiro.dart';

class _Movimento {
  final DocumentReference<Map<String, dynamic>> ref;
  final Produto produto;
  final ItemProduto item;

  _Movimento(this.ref, this.produto, this.item);
}

class PagamentoRepository {
  PagamentoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pagamentos');
  CollectionReference<Map<String, dynamic>> get _comandas =>
      _firestore.collection('comandas');
  CollectionReference<Map<String, dynamic>> get _produtos =>
      _firestore.collection('produtos');
  CollectionReference<Map<String, dynamic>> get _movimentos =>
      _firestore.collection('movimentosEstoque');

  Stream<List<Pagamento>> observarDaComanda(
    String comandaId,
    PerfilUsuario perfil,
  ) {
    Query<Map<String, dynamic>> consulta =
        _col.where('comandaId', isEqualTo: comandaId);

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map((snap) {
      final lista = snap.docs.map(Pagamento.doDocumento).toList();
      lista.sort((a, b) {
        final x = a.criadoEm ?? DateTime.now();
        final y = b.criadoEm ?? DateTime.now();
        return x.compareTo(y);
      });
      return lista;
    });
  }

  /// Registra o pagamento. Se ele quitar a comanda, finaliza e dá baixa
  /// no estoque na MESMA operação (tudo ou nada).
  Future<void> registrar({
    required String comandaId,
    required String forma,
    required int valorCentavos,
    required int recebidoCentavos,
    required PerfilUsuario perfil,
  }) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _comandas.doc(comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (!perfil.permissaoTotal && c.barbeiroUid != perfil.uid) {
        throw Exception(
          'Somente o barbeiro responsável ou o administrador pode receber.',
        );
      }
      if (c.descontoPendente) {
        throw Exception(
          'Há um pedido de desconto aguardando autorização. '
          'Aguarde a decisão do administrador.',
        );
      }
      if (c.totalCentavos <= 0) {
        throw Exception('A comanda não tem valor a receber.');
      }
      if (!formasPagamento.any((f) => f.chave == forma)) {
        throw Exception('Forma de pagamento inválida.');
      }
      if (valorCentavos <= 0) {
        throw Exception('Informe um valor maior que zero.');
      }
      if (valorCentavos > c.saldoCentavos) {
        throw Exception(
          'O valor é maior que o saldo '
          '(${Dinheiro.formatar(c.saldoCentavos)}).',
        );
      }

            if (forma == 'dinheiro' && valorCentavos != c.saldoCentavos) {
        throw Exception(
          'O pagamento em dinheiro deve quitar todo o saldo '
          '(${Dinheiro.formatar(c.saldoCentavos)}). '
          'Para pagar parcialmente, use Pix ou cartão.',
        );
            }
      final novoPago = c.pagoCentavos + valorCentavos;
      final quita = novoPago == c.totalCentavos;

      // Todas as leituras antes de qualquer escrita.
      final baixas = <_Movimento>[];
      if (quita) {
        for (final item in c.produtos) {
          final ref = _produtos.doc(item.produtoId);
          final snap = await tx.get(ref);

          if (!snap.exists) {
            throw Exception(
              'O produto "${item.nome}" não existe mais no cadastro.',
            );
          }

          final p = Produto.doDocumento(snap);
          if (p.estoqueQtd < item.quantidade) {
            throw Exception(
              'Estoque insuficiente de ${item.nome}: há ${p.estoqueQtd} '
              'e a comanda tem ${item.quantidade}.',
            );
          }
          baixas.add(_Movimento(ref, p, item));
        }
      }

      final agora = DateTime.now();
      final troco = (forma == 'dinheiro' && recebidoCentavos > valorCentavos)
          ? recebidoCentavos - valorCentavos
          : 0;

      tx.set(_col.doc(), {
        'comandaId': c.id,
        'comandaNumero': c.numero,
        'barbeiroUid': c.barbeiroUid,
        'barbeiroNome': c.barbeiroNome,
        'clienteNome': c.clienteNome,
        'forma': forma,
        'valorCentavos': valorCentavos,
        'recebidoCentavos': forma == 'dinheiro' ? recebidoCentavos : 0,
        'trocoCentavos': troco,
        'registradoPorUid': perfil.uid,
        'registradoPorNome': perfil.nome,
        'estornado': false,
        'dia': diaIso(agora),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      final campos = <String, dynamic>{
        'pagoCentavos': novoPago,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (quita) {
        campos['status'] = 'paga';
        campos['finalizadaEm'] = FieldValue.serverTimestamp();
        campos['finalizadaPorUid'] = perfil.uid;
        campos['finalizadaDia'] = diaIso(agora);
      }

      tx.update(comandaRef, campos);

      for (final b in baixas) {
        tx.update(b.ref, {
          'estoqueQtd': b.produto.estoqueQtd - b.item.quantidade,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
        tx.set(_movimentos.doc(), {
          'produtoId': b.produto.id,
          'produtoNome': b.produto.nome,
          'tipo': 'saida',
          'quantidade': b.item.quantidade,
          'motivo': 'Venda - comanda #${c.numero}',
          'comandaId': c.id,
          'usuarioUid': perfil.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Só o administrador. O pagamento continua no histórico, marcado como
  /// estornado. Se a comanda estava paga, ela reabre e o estoque volta.
  Future<void> estornar(
    String pagamentoId,
    PerfilUsuario perfil, {
    String motivo = '',
  }) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode estornar pagamentos.');
    }

    await _firestore.runTransaction((tx) async {
      final pagRef = _col.doc(pagamentoId);
      final pagSnap = await tx.get(pagRef);

      if (!pagSnap.exists) throw Exception('Pagamento não encontrado.');

      final pag = Pagamento.doDocumento(pagSnap);
      if (pag.estornado) throw Exception('Este pagamento já foi estornado.');

      final comandaRef = _comandas.doc(pag.comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);
      if (c.status == 'cancelada') {
        throw Exception('A comanda está cancelada.');
      }

      final reabre = c.status == 'paga';

      final devolucoes = <_Movimento>[];
      if (reabre) {
        for (final item in c.produtos) {
          final ref = _produtos.doc(item.produtoId);
          final snap = await tx.get(ref);
          if (snap.exists) {
            devolucoes.add(_Movimento(ref, Produto.doDocumento(snap), item));
          }
        }
      }

      tx.update(pagRef, {
        'estornado': true,
        'estornadoPorUid': perfil.uid,
        'estornadoPorNome': perfil.nome,
        'estornadoEm': FieldValue.serverTimestamp(),
        'motivoEstorno': motivo,
      });

      final novoPago = c.pagoCentavos - pag.valorCentavos;

      final campos = <String, dynamic>{
        'pagoCentavos': novoPago < 0 ? 0 : novoPago,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (reabre) {
        campos['status'] = 'aberta';
        campos['reabertaEm'] = FieldValue.serverTimestamp();
        campos['reabertaPorUid'] = perfil.uid;
        campos['finalizadaEm'] = FieldValue.delete();
        campos['finalizadaDia'] = FieldValue.delete();
      }

      tx.update(comandaRef, campos);

      for (final d in devolucoes) {
        tx.update(d.ref, {
          'estoqueQtd': d.produto.estoqueQtd + d.item.quantidade,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
        tx.set(_movimentos.doc(), {
          'produtoId': d.produto.id,
          'produtoNome': d.produto.nome,
          'tipo': 'entrada',
          'quantidade': d.item.quantidade,
          'motivo': 'Estorno - comanda #${c.numero}',
          'comandaId': c.id,
          'usuarioUid': perfil.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
