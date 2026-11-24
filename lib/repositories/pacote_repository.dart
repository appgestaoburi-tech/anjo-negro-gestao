import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/pacotes_iniciais.dart';
import '../models/pacote.dart';

class PacoteRepository {
  PacoteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pacotes');

  Stream<List<Pacote>> observar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(Pacote.doDocumento).toList();
      lista.sort((a, b) => a.ordem.compareTo(b.ordem));
      return lista;
    });
  }

  /// Cria só os pacotes iniciais que ainda não existem (ids fixos).
  /// Nunca sobrescreve um pacote já existente.
  Future<int> garantirIniciais() async {
    final existentes = await _col.get();
    final ids = existentes.docs.map((d) => d.id).toSet();
    final lote = _firestore.batch();
    var novos = 0;

    for (var i = 0; i < pacotesIniciais.length; i++) {
      final p = pacotesIniciais[i];
      if (ids.contains(p.id)) continue;

      lote.set(_col.doc(p.id), {
        'nome': p.nome,
        'meses': p.meses,
        'itens': p.itens.map((x) => x.paraMapa()).toList(),
        'precoCentavos': 0,
        'ativo': false,
        'ordem': i,
        'criadoEm': FieldValue.serverTimestamp(),
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
      novos++;
    }

    if (novos > 0) await lote.commit();
    return novos;
  }

  Future<void> salvar({
    String? id,
    required String nome,
    required int meses,
    required List<ItemPacote> itens,
    required int precoCentavos,
    required bool ativo,
  }) async {
    if (ativo && precoCentavos <= 0) {
      throw Exception('Defina o preço antes de ativar o pacote.');
    }

    final dados = <String, dynamic>{
      'nome': nome,
      'meses': meses,
      'itens': itens.map((i) => i.paraMapa()).toList(),
      'precoCentavos': precoCentavos,
      'ativo': ativo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      await _col.add({
        ...dados,
        'ordem': DateTime.now().millisecondsSinceEpoch,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    } else {
      await _col.doc(id).update(dados);
    }
  }

  Future<void> definirAtivo(String id, bool ativo) async {
    if (ativo) {
      final snap = await _col.doc(id).get();
      final preco = (snap.data()?['precoCentavos'] as num?)?.toInt() ?? 0;
      if (preco <= 0) {
        throw Exception('Defina o preço antes de ativar o pacote.');
      }
    }

    await _col.doc(id).update({
      'ativo': ativo,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
