import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/produto.dart';

class ProdutoRepository {
  ProdutoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('produtos');

  Stream<List<Produto>> observar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(Produto.doDocumento).toList();
      lista.sort(
        (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
      );
      return lista;
    });
  }

  /// Cria o produto e, se houver estoque inicial, registra a movimentação
  /// de entrada no mesmo lote (tudo ou nada).
  Future<void> criar({
    required String nome,
    required String categoria,
    required int precoVendaCentavos,
    required int estoqueInicial,
  }) async {
    final ref = _col.doc();
    final lote = _firestore.batch();

    lote.set(ref, {
      'nome': nome,
      'categoria': categoria,
      'precoVendaCentavos': precoVendaCentavos,
      'estoqueQtd': estoqueInicial,
      'ativo': true,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });

    if (estoqueInicial > 0) {
      lote.set(_firestore.collection('movimentosEstoque').doc(), {
        'produtoId': ref.id,
        'produtoNome': nome,
        'tipo': 'entrada',
        'quantidade': estoqueInicial,
        'motivo': 'Estoque inicial',
        'usuarioUid': FirebaseAuth.instance.currentUser?.uid,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    }

    await lote.commit();
  }

  /// Não altera o estoque: ele só muda por movimentações registradas.
  Future<void> atualizar(
    String id, {
    required String nome,
    required String categoria,
    required int precoVendaCentavos,
  }) async {
    await _col.doc(id).update({
      'nome': nome,
      'categoria': categoria,
      'precoVendaCentavos': precoVendaCentavos,
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
