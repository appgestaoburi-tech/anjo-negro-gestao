import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/catalogo_inicial.dart';
import '../models/servico.dart';

class ServicoRepository {
  ServicoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('servicos');

  Stream<List<Servico>> observar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(Servico.doDocumento).toList();
      lista.sort((a, b) => a.ordem.compareTo(b.ordem));
      return lista;
    });
  }

  /// Cria só os serviços que ainda não existem, usando IDs fixos.
  /// Nunca sobrescreve um serviço já existente (preço editado é mantido).
  Future<int> garantirCatalogoInicial() async {
    final existentes = await _col.get();
    final ids = existentes.docs.map((d) => d.id).toSet();
    final lote = _firestore.batch();
    var novos = 0;

    for (var i = 0; i < servicosIniciais.length; i++) {
      final s = servicosIniciais[i];
      if (ids.contains(s.id)) continue;

      lote.set(_col.doc(s.id), {
        'nome': s.nome,
        'categoria': s.categoria,
        'precoCentavos': s.precoCentavos,
        'tipoPreco': s.aPartir ? 'a_partir' : 'fixo',
        'descricao': '',
        'ativo': true,
        'imagemUrl': '',
        'ordem': i,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      novos++;
    }

    if (novos > 0) await lote.commit();
    return novos;
  }

  Future<void> criar({
    required String nome,
    required String categoria,
    required int precoCentavos,
    required bool aPartir,
    required String descricao,
  }) async {
    await _col.add({
      'nome': nome,
      'categoria': categoria,
      'precoCentavos': precoCentavos,
      'tipoPreco': aPartir ? 'a_partir' : 'fixo',
      'descricao': descricao,
      'ativo': true,
      'imagemUrl': '',
      'ordem': DateTime.now().millisecondsSinceEpoch,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizar(
    String id, {
    required String nome,
    required String categoria,
    required int precoCentavos,
    required bool aPartir,
    required String descricao,
  }) async {
    await _col.doc(id).update({
      'nome': nome,
      'categoria': categoria,
      'precoCentavos': precoCentavos,
      'tipoPreco': aPartir ? 'a_partir' : 'fixo',
      'descricao': descricao,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> definirAtivo(String id, bool ativo) async {
    await _col.doc(id).update({
      'ativo': ativo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
