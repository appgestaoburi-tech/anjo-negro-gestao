import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/pacote_cliente.dart';
import '../models/uso_pacote.dart';

class PacoteClienteRepository {
  PacoteClienteRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pacotesClientes');

  List<PacoteCliente> _ordenar(QuerySnapshot<Map<String, dynamic>> snap) {
    final lista = snap.docs.map(PacoteCliente.doDocumento).toList();
    lista.sort(
      (a, b) =>
          a.clienteNome.toLowerCase().compareTo(b.clienteNome.toLowerCase()),
    );
    return lista;
  }

  Stream<List<PacoteCliente>> observarTodos() =>
      _col.snapshots().map(_ordenar);

  Stream<List<PacoteCliente>> observarDoCliente(String clienteId) {
    return _col
        .where('clienteId', isEqualTo: clienteId)
        .snapshots()
        .map(_ordenar);
  }

  Stream<PacoteCliente?> observarUm(String id) {
    return _col
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? PacoteCliente.doDocumento(d) : null);
  }

  Stream<List<UsoPacote>> observarUsos(String pacoteId) {
    return _firestore
        .collection('usosPacote')
        .where('pacoteClienteId', isEqualTo: pacoteId)
        .snapshots()
        .map((snap) {
      final lista = snap.docs.map(UsoPacote.doDocumento).toList();
      lista.sort((a, b) {
        final x = a.criadoEm ?? Timestamp.now();
        final y = b.criadoEm ?? Timestamp.now();
        return y.compareTo(x);
      });
      return lista;
    });
  }
}
