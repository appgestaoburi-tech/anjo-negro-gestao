import 'package:cloud_firestore/cloud_firestore.dart';

class Servico {
  final String id;
  final String nome;
  final String categoria;
  final int precoCentavos;
  final bool aPartir;
  final String descricao;
  final bool ativo;
  final int ordem;
  final String imagemUrl;

  const Servico({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.precoCentavos,
    required this.aPartir,
    required this.descricao,
    required this.ativo,
    required this.ordem,
    required this.imagemUrl,
  });

  factory Servico.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Servico(
      id: doc.id,
      nome: (d['nome'] ?? '').toString(),
      categoria: (d['categoria'] ?? '').toString(),
      precoCentavos: (d['precoCentavos'] as num?)?.toInt() ?? 0,
      aPartir: d['tipoPreco'] == 'a_partir',
      descricao: (d['descricao'] ?? '').toString(),
      ativo: d['ativo'] == true,
      ordem: (d['ordem'] as num?)?.toInt() ?? 0,
      imagemUrl: (d['imagemUrl'] ?? '').toString(),
    );
  }
}
