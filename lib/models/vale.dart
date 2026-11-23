import 'package:cloud_firestore/cloud_firestore.dart';

class Vale {
  final String id;
  final String barbeiroUid;
  final String barbeiroNome;
  final int valorCentavos;
  final String motivo;
  final String status; // pendente | aprovado | recusado | pago | cancelado
  final Timestamp? criadoEm;
  final String decididoPorNome;
  final String motivoRecusa;
  final Timestamp? pagoEm;
  final String pagoPorNome;
  final String forma;
  final String despesaId;
  final int descontadoCentavos;

  const Vale({
    required this.id,
    required this.barbeiroUid,
    required this.barbeiroNome,
    required this.valorCentavos,
    required this.motivo,
    required this.status,
    required this.criadoEm,
    required this.decididoPorNome,
    required this.motivoRecusa,
    required this.pagoEm,
    required this.pagoPorNome,
    required this.forma,
    required this.despesaId,
    required this.descontadoCentavos,
  });

  factory Vale.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final criado = d['criadoEm'];
    final pago = d['pagoEm'];

    return Vale(
      id: doc.id,
      barbeiroUid: (d['barbeiroUid'] ?? '').toString(),
      barbeiroNome: (d['barbeiroNome'] ?? '').toString(),
      valorCentavos: (d['valorCentavos'] as num?)?.toInt() ?? 0,
      motivo: (d['motivo'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      criadoEm: criado is Timestamp ? criado : null,
      decididoPorNome: (d['decididoPorNome'] ?? '').toString(),
      motivoRecusa: (d['motivoRecusa'] ?? '').toString(),
      pagoEm: pago is Timestamp ? pago : null,
      pagoPorNome: (d['pagoPorNome'] ?? '').toString(),
      forma: (d['forma'] ?? '').toString(),
      despesaId: (d['despesaId'] ?? '').toString(),
      descontadoCentavos: (d['descontadoCentavos'] as num?)?.toInt() ?? 0,
    );
  }

  /// Quanto ainda falta descontar das comissões.
  int get saldoCentavos => valorCentavos - descontadoCentavos;

  String get rotuloStatus {
    switch (status) {
      case 'pendente':
        return 'Aguardando aprovação';
      case 'aprovado':
        return 'Aprovado • aguardando pagamento';
      case 'recusado':
        return 'Recusado';
      case 'pago':
        return 'Pago';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }
}
