import 'package:cloud_firestore/cloud_firestore.dart';

class UsoPacote {
  final String id;
  final String pacoteClienteId;
  final String comandaId;
  final int comandaNumero;
  final String barbeiroNome;
  final String servicoNome;
  final int valorUsoCentavos;
  final String dia;
  final String status; // ativo | cancelado
  final Timestamp? criadoEm;

  const UsoPacote({
    required this.id,
    required this.pacoteClienteId,
    required this.comandaId,
    required this.comandaNumero,
    required this.barbeiroNome,
    required this.servicoNome,
    required this.valorUsoCentavos,
    required this.dia,
    required this.status,
    required this.criadoEm,
  });

  factory UsoPacote.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final criado = d['criadoEm'];

    return UsoPacote(
      id: doc.id,
      pacoteClienteId: (d['pacoteClienteId'] ?? '').toString(),
      comandaId: (d['comandaId'] ?? '').toString(),
      comandaNumero: (d['comandaNumero'] as num?)?.toInt() ?? 0,
      barbeiroNome: (d['barbeiroNome'] ?? '').toString(),
      servicoNome: (d['servicoNome'] ?? '').toString(),
      valorUsoCentavos: (d['valorUsoCentavos'] as num?)?.toInt() ?? 0,
      dia: (d['dia'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      criadoEm: criado is Timestamp ? criado : null,
    );
  }

  bool get cancelado => status == 'cancelado';
}
