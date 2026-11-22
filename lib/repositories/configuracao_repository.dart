import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PixConfig {
  final String chave;
  final String nome;
  final String cidade;

  const PixConfig({
    required this.chave,
    required this.nome,
    required this.cidade,
  });

  factory PixConfig.doMapa(Map<String, dynamic> d) {
    return PixConfig(
      chave: (d['chave'] ?? '').toString(),
      nome: (d['nome'] ?? '').toString(),
      cidade: (d['cidade'] ?? '').toString(),
    );
  }

  bool get completo =>
      chave.trim().isNotEmpty &&
      nome.trim().isNotEmpty &&
      cidade.trim().isNotEmpty;
}

class ConfiguracaoRepository {
  ConfiguracaoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _pix =>
      _firestore.collection('configuracoes').doc('pix');

  Stream<PixConfig?> observarPix() {
    return _pix.snapshots().map(
          (d) => d.exists ? PixConfig.doMapa(d.data() ?? {}) : null,
        );
  }

  Future<PixConfig?> lerPix() async {
    final d = await _pix.get();
    return d.exists ? PixConfig.doMapa(d.data() ?? {}) : null;
  }

  Future<void> salvarPix({
    required String chave,
    required String nome,
    required String cidade,
  }) async {
    await _pix.set({
      'chave': chave.trim(),
      'nome': nome.trim(),
      'cidade': cidade.trim(),
      'atualizadoPorUid': FirebaseAuth.instance.currentUser?.uid,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }
}
