import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/despesa.dart';
import '../models/perfil_usuario.dart';

class DespesaRepository {
  DespesaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('despesas');

  /// Despesas do período (datas no formato aaaa-mm-dd, inclusive).
  Stream<List<Despesa>> observarPeriodo(String ini, String fim) {
    return _col
        .where('dia', isGreaterThanOrEqualTo: ini)
        .where('dia', isLessThanOrEqualTo: fim)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(Despesa.doDocumento).toList();
      lista.sort((a, b) {
        final porDia = b.dia.compareTo(a.dia);
        if (porDia != 0) return porDia;
        final x = a.criadoEm ?? DateTime.now();
        final y = b.criadoEm ?? DateTime.now();
        return y.compareTo(x);
      });
      return lista;
    });
  }

  Future<void> criar({
    required String descricao,
    required String categoria,
    required int valorCentavos,
    required String dia,
    required String forma,
    required String observacoes,
    required PerfilUsuario perfil,
  }) async {
    await _col.add({
      'descricao': descricao,
      'categoria': categoria,
      'valorCentavos': valorCentavos,
      'dia': dia,
      'forma': forma,
      'observacoes': observacoes,
      'cancelada': false,
      'registradoPorUid': perfil.uid,
      'registradoPorNome': perfil.nome,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Não apaga: marca como cancelada, com quem cancelou e o motivo.
  Future<void> cancelar(
    String id,
    PerfilUsuario perfil, {
    String motivo = '',
  }) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode cancelar despesas.');
    }

    await _col.doc(id).update({
      'cancelada': true,
      'canceladaPorUid': perfil.uid,
      'canceladaPorNome': perfil.nome,
      'canceladaEm': FieldValue.serverTimestamp(),
      'motivoCancelamento': motivo,
    });
  }
}
