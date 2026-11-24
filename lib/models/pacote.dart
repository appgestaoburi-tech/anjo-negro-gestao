import 'package:cloud_firestore/cloud_firestore.dart';

class ItemPacote {
  final String servicoId;
  final String servicoNome;
  final int qtdTotal;
  final int maxPorMes;

  const ItemPacote({
    required this.servicoId,
    required this.servicoNome,
    required this.qtdTotal,
    required this.maxPorMes,
  });

  factory ItemPacote.doMapa(Map<String, dynamic> m) {
    return ItemPacote(
      servicoId: (m['servicoId'] ?? '').toString(),
      servicoNome: (m['servicoNome'] ?? '').toString(),
      qtdTotal: (m['qtdTotal'] as num?)?.toInt() ?? 0,
      maxPorMes: (m['maxPorMes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> paraMapa() => {
        'servicoId': servicoId,
        'servicoNome': servicoNome,
        'qtdTotal': qtdTotal,
        'maxPorMes': maxPorMes,
      };
}

class Pacote {
  final String id;
  final String nome;
  final int meses;
  final List<ItemPacote> itens;
  final int precoCentavos;
  final bool ativo;
  final int ordem;

  const Pacote({
    required this.id,
    required this.nome,
    required this.meses,
    required this.itens,
    required this.precoCentavos,
    required this.ativo,
    required this.ordem,
  });

  factory Pacote.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    final itens = <ItemPacote>[];
    final brutos = d['itens'];
    if (brutos is List) {
      for (final m in brutos) {
        if (m is Map) {
          itens.add(ItemPacote.doMapa(Map<String, dynamic>.from(m)));
        }
      }
    }

    return Pacote(
      id: doc.id,
      nome: (d['nome'] ?? '').toString(),
      meses: (d['meses'] as num?)?.toInt() ?? 1,
      itens: itens,
      precoCentavos: (d['precoCentavos'] as num?)?.toInt() ?? 0,
      ativo: d['ativo'] == true,
      ordem: (d['ordem'] as num?)?.toInt() ?? 0,
    );
  }

  int get totalUsos => itens.fold<int>(0, (s, i) => s + i.qtdTotal);

  String get duracaoTexto {
    if (meses == 12) return '1 ano';
    if (meses == 1) return '1 mês';
    return '$meses meses';
  }

  String get resumo =>
      itens.map((i) => '${i.qtdTotal}x ${i.servicoNome}').join(' + ');
}
