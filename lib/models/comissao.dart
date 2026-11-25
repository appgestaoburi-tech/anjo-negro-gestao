import 'package:cloud_firestore/cloud_firestore.dart';

class LinhaComissao {
  final String tipo; // servico | produto
  final String nome;
  final String categoria;
  final int baseCentavos;
  final int bp;
  final int comissaoCentavos;

  const LinhaComissao({
    required this.tipo,
    required this.nome,
    required this.categoria,
    required this.baseCentavos,
    required this.bp,
    required this.comissaoCentavos,
  });

  factory LinhaComissao.doMapa(Map<String, dynamic> m) {
    return LinhaComissao(
      tipo: (m['tipo'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      categoria: (m['categoria'] ?? '').toString(),
      baseCentavos: (m['baseCentavos'] as num?)?.toInt() ?? 0,
      bp: (m['bp'] as num?)?.toInt() ?? 0,
      comissaoCentavos: (m['comissaoCentavos'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> paraMapa() => {
        'tipo': tipo,
        'nome': nome,
        'categoria': categoria,
        'baseCentavos': baseCentavos,
        'bp': bp,
        'comissaoCentavos': comissaoCentavos,
      };
}

class Comissao {
  final String id;
  final String comandaId;
  final int comandaNumero;
  final String barbeiroUid;
  final String barbeiroNome;
  final String clienteNome;
  final String dia;
  final String status; // ativa | estornada
  final int totalCentavos;
  final int baseServicosCentavos;
  final int baseProdutosCentavos;
  final List<LinhaComissao> linhas;
  final Timestamp? criadoEm;
  final Timestamp? estornadaEm;

  const Comissao({
    required this.id,
    required this.comandaId,
    required this.comandaNumero,
    required this.barbeiroUid,
    required this.barbeiroNome,
    required this.clienteNome,
    required this.dia,
    required this.status,
    required this.totalCentavos,
    required this.baseServicosCentavos,
    required this.baseProdutosCentavos,
    required this.linhas,
    required this.criadoEm,
    required this.estornadaEm,
  });

  factory Comissao.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    final linhas = <LinhaComissao>[];
    final brutas = d['linhas'];
    if (brutas is List) {
      for (final m in brutas) {
        if (m is Map) {
          linhas.add(LinhaComissao.doMapa(Map<String, dynamic>.from(m)));
        }
      }
    }

    final criado = d['criadoEm'];
    final estornada = d['estornadaEm'];

    return Comissao(
      id: doc.id,
      comandaId: (d['comandaId'] ?? '').toString(),
      comandaNumero: (d['comandaNumero'] as num?)?.toInt() ?? 0,
      barbeiroUid: (d['barbeiroUid'] ?? '').toString(),
      barbeiroNome: (d['barbeiroNome'] ?? '').toString(),
      clienteNome: (d['clienteNome'] ?? '').toString(),
      dia: (d['dia'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      totalCentavos: (d['totalComissaoCentavos'] as num?)?.toInt() ?? 0,
      baseServicosCentavos:
          (d['baseServicosCentavos'] as num?)?.toInt() ?? 0,
      baseProdutosCentavos:
          (d['baseProdutosCentavos'] as num?)?.toInt() ?? 0,
      linhas: linhas,
      criadoEm: criado is Timestamp ? criado : null,
      estornadaEm: estornada is Timestamp ? estornada : null,
    );
  }

  bool get estornada => status == 'estornada';
}

class PagamentoComissao {
  final String id;
  final String barbeiroUid;
  final String barbeiroNome;
  final int valorCentavos; // valor efetivamente pago (já sem os vales)
  final int comissaoCentavos; // comissão antes de descontar os vales
  final int valesDescontadosCentavos;
  final int creditosCentavos;
  final int estornosCentavos;
  final String forma;
  final String observacoes;
  final String pagoPorNome;
  final bool estornado;
  final String estornadoPorNome;
  final Timestamp? de;
  final Timestamp? ate;
  final Timestamp? criadoEm;

  const PagamentoComissao({
    required this.id,
    required this.barbeiroUid,
    required this.barbeiroNome,
    required this.valorCentavos,
    required this.comissaoCentavos,
    required this.valesDescontadosCentavos,
    required this.creditosCentavos,
    required this.estornosCentavos,
    required this.forma,
    required this.observacoes,
    required this.pagoPorNome,
    required this.estornado,
    required this.estornadoPorNome,
    required this.de,
    required this.ate,
    required this.criadoEm,
  });

  factory PagamentoComissao.doDocumento(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? <String, dynamic>{};
    final de = d['de'];
    final ate = d['ate'];
    final criado = d['criadoEm'];
    final valor = (d['valorCentavos'] as num?)?.toInt() ?? 0;

    return PagamentoComissao(
      id: doc.id,
      barbeiroUid: (d['barbeiroUid'] ?? '').toString(),
      barbeiroNome: (d['barbeiroNome'] ?? '').toString(),
      valorCentavos: valor,
      comissaoCentavos: (d['comissaoCentavos'] as num?)?.toInt() ?? valor,
      valesDescontadosCentavos:
          (d['valesDescontadosCentavos'] as num?)?.toInt() ?? 0,
      creditosCentavos: (d['creditosCentavos'] as num?)?.toInt() ?? 0,
      estornosCentavos: (d['estornosCentavos'] as num?)?.toInt() ?? 0,
      forma: (d['forma'] ?? '').toString(),
      observacoes: (d['observacoes'] ?? '').toString(),
      pagoPorNome: (d['pagoPorNome'] ?? '').toString(),
      estornado: d['estornado'] == true,
      estornadoPorNome: (d['estornadoPorNome'] ?? '').toString(),
      de: de is Timestamp ? de : null,
      ate: ate is Timestamp ? ate : null,
      criadoEm: criado is Timestamp ? criado : null,
    );
  }
}
