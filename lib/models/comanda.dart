import 'package:cloud_firestore/cloud_firestore.dart';

class ItemComanda {
  final String id;
  final String servicoId;
  final String nome;
  final String categoria;
  final int precoCatalogoCentavos;
  final int precoCentavos;
  final bool aPartir;

  /// servico | pacote (venda de pacote) | uso (uso de pacote do cliente)
  final String tipo;
  final String pacoteId;
  final Map<String, dynamic>? pacote;
  final int valorUsoCentavos;
  final int ciclo;

  const ItemComanda({
    required this.id,
    required this.servicoId,
    required this.nome,
    required this.categoria,
    required this.precoCatalogoCentavos,
    required this.precoCentavos,
    required this.aPartir,
    this.tipo = 'servico',
    this.pacoteId = '',
    this.pacote,
    this.valorUsoCentavos = 0,
    this.ciclo = 0,
  });

  factory ItemComanda.doMapa(Map<String, dynamic> m) {
    final pacoteBruto = m['pacote'];

    return ItemComanda(
      id: (m['id'] ?? '').toString(),
      servicoId: (m['servicoId'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      categoria: (m['categoria'] ?? '').toString(),
      precoCatalogoCentavos: (m['precoCatalogoCentavos'] as num?)?.toInt() ?? 0,
      precoCentavos: (m['precoCentavos'] as num?)?.toInt() ?? 0,
      aPartir: m['aPartir'] == true,
      tipo: (m['tipo'] ?? 'servico').toString(),
      pacoteId: (m['pacoteId'] ?? '').toString(),
      pacote: pacoteBruto is Map ? Map<String, dynamic>.from(pacoteBruto) : null,
      valorUsoCentavos: (m['valorUsoCentavos'] as num?)?.toInt() ?? 0,
      ciclo: (m['ciclo'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> paraMapa() => {
        'id': id,
        'servicoId': servicoId,
        'nome': nome,
        'categoria': categoria,
        'precoCatalogoCentavos': precoCatalogoCentavos,
        'precoCentavos': precoCentavos,
        'aPartir': aPartir,
        'tipo': tipo,
        'pacoteId': pacoteId,
        if (pacote != null) 'pacote': pacote,
        'valorUsoCentavos': valorUsoCentavos,
        'ciclo': ciclo,
      };

  bool get ehPacote => tipo == 'pacote';
  bool get ehUso => tipo == 'uso';

  ItemComanda comPreco(int novoPreco) => ItemComanda(
        id: id,
        servicoId: servicoId,
        nome: nome,
        categoria: categoria,
        precoCatalogoCentavos: precoCatalogoCentavos,
        precoCentavos: novoPreco,
        aPartir: aPartir,
        tipo: tipo,
        pacoteId: pacoteId,
        pacote: pacote,
        valorUsoCentavos: valorUsoCentavos,
        ciclo: ciclo,
      );
}

class ItemProduto {
  final String id;
  final String produtoId;
  final String nome;
  final int precoCentavos;
  final int quantidade;

  const ItemProduto({
    required this.id,
    required this.produtoId,
    required this.nome,
    required this.precoCentavos,
    required this.quantidade,
  });

  factory ItemProduto.doMapa(Map<String, dynamic> m) {
    return ItemProduto(
      id: (m['id'] ?? '').toString(),
      produtoId: (m['produtoId'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      precoCentavos: (m['precoCentavos'] as num?)?.toInt() ?? 0,
      quantidade: (m['quantidade'] as num?)?.toInt() ?? 1,
    );
  }

  Map<String, dynamic> paraMapa() => {
        'id': id,
        'produtoId': produtoId,
        'nome': nome,
        'precoCentavos': precoCentavos,
        'quantidade': quantidade,
      };

  int get totalCentavos => precoCentavos * quantidade;

  ItemProduto comQuantidade(int nova) => ItemProduto(
        id: id,
        produtoId: produtoId,
        nome: nome,
        precoCentavos: precoCentavos,
        quantidade: nova,
      );
}

class Comanda {
  final String id;
  final int numero;
  final String status; // aberta | paga | cancelada
  final String barbeiroUid;
  final String barbeiroNome;
  final String clienteId;
  final String clienteNome;
  final List<ItemComanda> servicos;
  final List<ItemProduto> produtos;
  final int subtotalServicosCentavos;
  final int subtotalProdutosCentavos;
  final int descontoBp; // desconto aplicado, em pontos-base (1500 = 15%)
  final int descontoCentavos;
  final int descontoAprovadoBp; // maior percentual autorizado pelo admin
  final String descontoStatus; // '' | pendente | aprovado | recusado
  final int descontoSolicitadoBp;
  final String descontoSolicitadoPorNome;
  final String descontoDecididoPorNome;
  final int totalCentavos;
  final int pagoCentavos;
  final int valorUsosCentavos; // soma do valor dos usos de pacote
  final bool coberta; // sem cobrança: só usos de pacote
  final DateTime? criadoEm;

  const Comanda({
    required this.id,
    required this.numero,
    required this.status,
    required this.barbeiroUid,
    required this.barbeiroNome,
    required this.clienteId,
    required this.clienteNome,
    required this.servicos,
    required this.produtos,
    required this.subtotalServicosCentavos,
    required this.subtotalProdutosCentavos,
    required this.descontoBp,
    required this.descontoCentavos,
    required this.descontoAprovadoBp,
    required this.descontoStatus,
    required this.descontoSolicitadoBp,
    required this.descontoSolicitadoPorNome,
    required this.descontoDecididoPorNome,
    required this.totalCentavos,
    required this.pagoCentavos,
    required this.valorUsosCentavos,
    required this.coberta,
    required this.criadoEm,
  });

  factory Comanda.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    final servicos = <ItemComanda>[];
    final brutosServicos = d['servicos'];
    if (brutosServicos is List) {
      for (final m in brutosServicos) {
        if (m is Map) {
          servicos.add(ItemComanda.doMapa(Map<String, dynamic>.from(m)));
        }
      }
    }

    final produtos = <ItemProduto>[];
    final brutosProdutos = d['produtos'];
    if (brutosProdutos is List) {
      for (final m in brutosProdutos) {
        if (m is Map) {
          produtos.add(ItemProduto.doMapa(Map<String, dynamic>.from(m)));
        }
      }
    }

    final criado = d['criadoEm'];

    return Comanda(
      id: doc.id,
      numero: (d['numero'] as num?)?.toInt() ?? 0,
      status: (d['status'] ?? '').toString(),
      barbeiroUid: (d['barbeiroUid'] ?? '').toString(),
      barbeiroNome: (d['barbeiroNome'] ?? '').toString(),
      clienteId: (d['clienteId'] ?? '').toString(),
      clienteNome: (d['clienteNome'] ?? '').toString(),
      servicos: servicos,
      produtos: produtos,
      subtotalServicosCentavos:
          (d['subtotalServicosCentavos'] as num?)?.toInt() ?? 0,
      subtotalProdutosCentavos:
          (d['subtotalProdutosCentavos'] as num?)?.toInt() ?? 0,
      descontoBp: (d['descontoBp'] as num?)?.toInt() ?? 0,
      descontoCentavos: (d['descontoCentavos'] as num?)?.toInt() ?? 0,
      descontoAprovadoBp: (d['descontoAprovadoBp'] as num?)?.toInt() ?? 0,
      descontoStatus: (d['descontoStatus'] ?? '').toString(),
      descontoSolicitadoBp: (d['descontoSolicitadoBp'] as num?)?.toInt() ?? 0,
      descontoSolicitadoPorNome:
          (d['descontoSolicitadoPorNome'] ?? '').toString(),
      descontoDecididoPorNome: (d['descontoDecididoPorNome'] ?? '').toString(),
      totalCentavos: (d['totalCentavos'] as num?)?.toInt() ?? 0,
      pagoCentavos: (d['pagoCentavos'] as num?)?.toInt() ?? 0,
      valorUsosCentavos: (d['valorUsosCentavos'] as num?)?.toInt() ?? 0,
      coberta: d['coberta'] == true,
      criadoEm: criado is Timestamp ? criado.toDate() : null,
    );
  }

  bool get aberta => status == 'aberta';

  bool get descontoPendente => descontoStatus == 'pendente';

  bool get descontoRecusado => descontoStatus == 'recusado';

  int get saldoCentavos => totalCentavos - pagoCentavos;

  String get nomeCliente => clienteNome.isEmpty ? 'Sem cadastro' : clienteNome;

  String get rotuloStatus {
    if (status == 'aberta') return 'Aberta';
    if (status == 'paga') return 'Paga';
    if (status == 'cancelada') return 'Cancelada';
    return status;
  }
}
