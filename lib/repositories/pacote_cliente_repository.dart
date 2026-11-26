import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pacote_cliente.dart';

class PacoteClienteRepository {
  PacoteClienteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pacotesClientes');

  Stream<List<PacoteCliente>> observarTodos() {
    return _col.snapshots().map((snap) {
      final lista = snap.docs.map(PacoteCliente.doDocumento).toList();
      lista.sort(
        (a, b) =>
            a.clienteNome.toLowerCase().compareTo(b.clienteNome.toLowerCase()),
      );
      return lista;
    });
  }

  Stream<PacoteCliente?> observarUm(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? PacoteCliente.doDocumento(d) : null);
  }
}
