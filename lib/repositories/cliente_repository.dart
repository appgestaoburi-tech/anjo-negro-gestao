import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cliente.dart';

class ClienteRepository {
  ClienteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('clientes');

  Stream<List<Cliente>> observar() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(Cliente.doDocumento).toList();
      lista.sort(
        (a, b) => Cliente.normalizar(a.nome).compareTo(
          Cliente.normalizar(b.nome),
        ),
      );
      return lista;
    });
  }

  Stream<Cliente?> observarUm(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? Cliente.doDocumento(d) : null);
  }

  Future<void> criar({
    required String nome,
    required String telefone,
    required String nascimento,
    required String observacoes,
  }) async {
    await _col.add({
      'nome': nome,
      'telefone': telefone,
      'nascimento': nascimento,
      'observacoes': observacoes,
      'criadoPor': FirebaseAuth.instance.currentUser?.uid,
      'criadoEm': FieldValue.serverTimestamp(),
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  Future<void> atualizar(
    String id, {
    required String nome,
    required String telefone,
    required String nascimento,
    required String observacoes,
  }) async {
    await _col.doc(id).update({
      'nome': nome,
      'telefone': telefone,
      'nascimento': nascimento,
      'observacoes': observacoes,
      'atualizadoEm': FieldValue.serverTimestamp(),
    });
  }

  /// Só o administrador consegue (regra do Firestore).
  Future<void> excluir(String id) async {
    await _col.doc(id).delete();
  }
}
