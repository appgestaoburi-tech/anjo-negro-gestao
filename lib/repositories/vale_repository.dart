import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/perfil_usuario.dart';
import '../models/vale.dart';
import '../utils/datas.dart';
import '../utils/dinheiro.dart';

class ValeRepository {
  ValeRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('vales');
  CollectionReference<Map<String, dynamic>> get _despesas =>
      _firestore.collection('despesas');

  List<Vale> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(Vale.doDocumento).toList();
    lista.sort((a, b) {
      final x = a.criadoEm ?? Timestamp.now();
      final y = b.criadoEm ?? Timestamp.now();
      return y.compareTo(x);
    });
    return lista;
  }

  Stream<List<Vale>> observarDoBarbeiro(String barbeiroUid) {
    return _col
        .where('barbeiroUid', isEqualTo: barbeiroUid)
        .snapshots()
        .map(_ordenar);
  }

  /// Só o administrador consegue ler todos (regra do Firebase).
  Stream<List<Vale>> observarTodos() => _col.snapshots().map(_ordenar);

  Stream<List<Vale>> observarPendentes() {
    return _col.where('status', isEqualTo: 'pendente').snapshots().map(_ordenar);
  }

  Future<void> criar({
    required PerfilUsuario perfil,
    required int valorCentavos,
    required String motivo,
  }) async {
    if (valorCentavos <= 0) throw Exception('Informe um valor válido.');
    if (motivo.trim().isEmpty) throw Exception('Informe o motivo do vale.');

    await _col.add({
      'barbeiroUid': perfil.uid,
      'barbeiroNome': perfil.nome,
      'valorCentavos': valorCentavos,
      'motivo': motivo.trim(),
      'status': 'pendente',
      'descontadoCentavos': 0,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _transicao(
    String id,
    void Function(
      Transaction tx,
      DocumentReference<Map<String, dynamic>> ref,
      Vale vale,
    ) acao,
  ) async {
    await _firestore.runTransaction((tx) async {
      final ref = _col.doc(id);
      final snap = await tx.get(ref);

      if (!snap.exists) throw Exception('Vale não encontrado.');

      acao(tx, ref, Vale.doDocumento(snap));
    });
  }

  /// O barbeiro cancela o próprio pedido pendente; o administrador cancela
  /// pendente ou aprovado (ainda não pago).
  Future<void> cancelar(String id, PerfilUsuario perfil) {
    return _transicao(id, (tx, ref, v) {
      final dono = v.barbeiroUid == perfil.uid;

      if (!dono && !perfil.permissaoTotal) {
        throw Exception('Você não pode cancelar este vale.');
      }
      if (v.status != 'pendente' &&
          !(perfil.permissaoTotal && v.status == 'aprovado')) {
        throw Exception('Este vale não pode mais ser cancelado.');
      }

      tx.update(ref, {
        'status': 'cancelado',
        'canceladoEm': FieldValue.serverTimestamp(),
        'canceladoPorUid': perfil.uid,
        'canceladoPorNome': perfil.nome,
      });
    });
  }

  Future<void> decidir(
    String id,
    bool aprovar,
    PerfilUsuario perfil, {
    String motivoRecusa = '',
  }) {
    if (!perfil.permissaoTotal) {
      return Future.error(
        Exception('Somente o administrador pode decidir sobre vales.'),
      );
    }

    return _transicao(id, (tx, ref, v) {
      if (v.status != 'pendente') {
        throw Exception('Este pedido já foi decidido.');
      }

      tx.update(ref, {
        'status': aprovar ? 'aprovado' : 'recusado',
        'decididoPorUid': perfil.uid,
        'decididoPorNome': perfil.nome,
        'decididoEm': FieldValue.serverTimestamp(),
        if (!aprovar) 'motivoRecusa': motivoRecusa,
      });
    });
  }

  /// Registra o pagamento do vale e lança a saída no caixa (despesa).
  Future<void> pagar(String id, PerfilUsuario perfil, String forma) {
    if (!perfil.permissaoTotal) {
      return Future.error(
        Exception('Somente o administrador pode pagar vales.'),
      );
    }
    if (forma != 'dinheiro' && forma != 'pix') {
      return Future.error(Exception('Forma de pagamento inválida.'));
    }

    final despesaRef = _despesas.doc();
    final hoje = diaIso(DateTime.now());

    return _transicao(id, (tx, ref, v) {
      if (v.status != 'aprovado') {
        throw Exception('Só vales aprovados podem ser pagos.');
      }

      tx.update(ref, {
        'status': 'pago',
        'pagoEm': FieldValue.serverTimestamp(),
        'pagoPorUid': perfil.uid,
        'pagoPorNome': perfil.nome,
        'forma': forma,
        'despesaId': despesaRef.id,
      });

      tx.set(despesaRef, {
        'descricao': 'Vale - ${v.barbeiroNome}',
        'categoria': 'Vales',
        'valorCentavos': v.valorCentavos,
        'dia': hoje,
        'forma': forma,
        'observacoes': v.motivo,
        'origem': 'vale',
        'valeId': v.id,
        'cancelada': false,
        'registradoPorUid': perfil.uid,
        'registradoPorNome': perfil.nome,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Só enquanto nada do vale foi descontado de comissão. O vale fica no
  /// histórico como cancelado e a despesa do caixa é cancelada.
  Future<void> estornarPagamento(String id, PerfilUsuario perfil) {
    if (!perfil.permissaoTotal) {
      return Future.error(
        Exception('Somente o administrador pode estornar vales.'),
      );
    }

    return _transicao(id, (tx, ref, v) {
      if (v.status != 'pago') {
        throw Exception('Só vales pagos podem ser estornados.');
      }
      if (v.descontadoCentavos > 0) {
        throw Exception(
          'Já foram descontados ${Dinheiro.formatar(v.descontadoCentavos)} '
          'deste vale em comissões. Estorne antes o pagamento da comissão.',
        );
      }

      tx.update(ref, {
        'status': 'cancelado',
        'canceladoEm': FieldValue.serverTimestamp(),
        'canceladoPorUid': perfil.uid,
        'canceladoPorNome': perfil.nome,
      });

      if (v.despesaId.isNotEmpty) {
        tx.update(_despesas.doc(v.despesaId), {
          'cancelada': true,
          'canceladaPorUid': perfil.uid,
          'canceladaPorNome': perfil.nome,
          'canceladaEm': FieldValue.serverTimestamp(),
          'motivoCancelamento': 'Estorno do pagamento do vale',
        });
      }
    });
  }
}
