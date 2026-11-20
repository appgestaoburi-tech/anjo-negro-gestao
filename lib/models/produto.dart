import 'package:cloud_firestore/cloud_firestore.dart';

class Produto {
  final String id;
  final String nome;
  final String categoria;
  final int precoVendaCentavos;
  final int estoqueQtd;
  final bool ativo;

  const Produto({
    required this.id,
    required this.nome,
    required this.categoria,
    required this.precoVendaCentavos,
    required this.estoqueQtd,
    required this.ativo,
  });

  factory Produto.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    return Produto(
      id: doc.id,
      nome: (d['nome'] ?? '').toString(),
      categoria: (d['categoria'] ?? '').toString(),
      precoVendaCentavos: (d['precoVendaCentavos'] as num?)?.toInt() ?? 0,
      estoqueQtd: (d['estoqueQtd'] as num?)?.toInt() ?? 0,
      ativo: d['ativo'] == true,
    );
  }
}
