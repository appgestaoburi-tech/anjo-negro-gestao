import 'package:cloud_firestore/cloud_firestore.dart';

class Pagamento {
  final String id;
  final String comandaId;
  final int comandaNumero;
  final String forma;
  final int valorCentavos;
  final int recebidoCentavos;
  final int trocoCentavos;
  final String registradoPorNome;
  final String barbeiroUid;
  final DateTime? criadoEm;
  final bool estornado;
  final String estornadoPorNome;
  final String motivoEstorno;

  const Pagamento({
    required this.id,
    required this.comandaId,
    required this.comandaNumero,
    required this.forma,
    required this.valorCentavos,
    required this.recebidoCentavos,
    required this.trocoCentavos,
    required this.registradoPorNome,
    required this.barbeiroUid,
    required this.criadoEm,
    required this.estornado,
    required this.estornadoPorNome,
    required this.motivoEstorno,
  });

  factory Pagamento.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final criado = d['criadoEm'];

    return Pagamento(
      id: doc.id,
      comandaId: (d['comandaId'] ?? '').toString(),
      comandaNumero: (d['comandaNumero'] as num?)?.toInt() ?? 0,
      forma: (d['forma'] ?? '').toString(),
      valorCentavos: (d['valorCentavos'] as num?)?.toInt() ?? 0,
      recebidoCentavos: (d['recebidoCentavos'] as num?)?.toInt() ?? 0,
      trocoCentavos: (d['trocoCentavos'] as num?)?.toInt() ?? 0,
      registradoPorNome: (d['registradoPorNome'] ?? '').toString(),
      barbeiroUid: (d['barbeiroUid'] ?? '').toString(),
      criadoEm: criado is Timestamp ? criado.toDate() : null,
      estornado: d['estornado'] == true,
      estornadoPorNome: (d['estornadoPorNome'] ?? '').toString(),
      motivoEstorno: (d['motivoEstorno'] ?? '').toString(),
    );
  }
}
