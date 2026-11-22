import 'package:cloud_firestore/cloud_firestore.dart';

class Despesa {
  final String id;
  final String descricao;
  final String categoria;
  final int valorCentavos;
  final String dia; // aaaa-mm-dd
  final String forma;
  final String observacoes;
  final String registradoPorNome;
  final bool cancelada;
  final String canceladaPorNome;
  final String motivoCancelamento;
  final DateTime? criadoEm;

  const Despesa({
    required this.id,
    required this.descricao,
    required this.categoria,
    required this.valorCentavos,
    required this.dia,
    required this.forma,
    required this.observacoes,
    required this.registradoPorNome,
    required this.cancelada,
    required this.canceladaPorNome,
    required this.motivoCancelamento,
    required this.criadoEm,
  });

  factory Despesa.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final criado = d['criadoEm'];

    return Despesa(
      id: doc.id,
      descricao: (d['descricao'] ?? '').toString(),
      categoria: (d['categoria'] ?? '').toString(),
      valorCentavos: (d['valorCentavos'] as num?)?.toInt() ?? 0,
      dia: (d['dia'] ?? '').toString(),
      forma: (d['forma'] ?? '').toString(),
      observacoes: (d['observacoes'] ?? '').toString(),
      registradoPorNome: (d['registradoPorNome'] ?? '').toString(),
      cancelada: d['cancelada'] == true,
      canceladaPorNome: (d['canceladaPorNome'] ?? '').toString(),
      motivoCancelamento: (d['motivoCancelamento'] ?? '').toString(),
      criadoEm: criado is Timestamp ? criado.toDate() : null,
    );
  }
}
