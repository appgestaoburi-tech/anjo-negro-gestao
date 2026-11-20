import 'package:cloud_firestore/cloud_firestore.dart';

class ItemComanda {
  final String id;
  final String servicoId;
  final String nome;
  final String categoria;
  final int precoCatalogoCentavos;
  final int precoCentavos;
  final bool aPartir;

  const ItemComanda({
    required this.id,
    required this.servicoId,
    required this.nome,
    required this.categoria,
    required this.precoCatalogoCentavos,
    required this.precoCentavos,
    required this.aPartir,
  });

  factory ItemComanda.doMapa(Map<String, dynamic> m) {
    return ItemComanda(
      id: (m['id'] ?? '').toString(),
      servicoId: (m['servicoId'] ?? '').toString(),
      nome: (m['nome'] ?? '').toString(),
      categoria: (m['categoria'] ?? '').toString(),
      precoCatalogoCentavos: (m['precoCatalogoCentavos'] as num?)?.toInt() ?? 0,
      precoCentavos: (m['precoCentavos'] as num?)?.toInt() ?? 0,
      aPartir: m['aPartir'] == true,
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
      };

  ItemComanda comPreco(int novoPreco) => ItemComanda(
        id: id,
        servicoId: servicoId,
        nome: nome,
        categoria: categoria,
        precoCatalogoCentavos: precoCatalogoCentavos,
        precoCentavos: novoPreco,
        aPartir: aPartir,
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
  final int subtotalServicosCentavos;
  final int subtotalProdutosCentavos;
  final int descontoCentavos;
  final int totalCentavos;
  final int pagoCentavos;
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
    required this.subtotalServicosCentavos,
    required this.subtotalProdutosCentavos,
    required this.descontoCentavos,
    required this.totalCentavos,
    required this.pagoCentavos,
    required this.criadoEm,
  });

  factory Comanda.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    final servicos = <ItemComanda>[];
    final brutos = d['servicos'];
    if (brutos is List) {
      for (final m in brutos) {
        if (m is Map) {
          servicos.add(ItemComanda.doMapa(Map<String, dynamic>.from(m)));
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
      subtotalServicosCentavos:
          (d['subtotalServicosCentavos'] as num?)?.toInt() ?? 0,
      subtotalProdutosCentavos:
          (d['subtotalProdutosCentavos'] as num?)?.toInt() ?? 0,
      descontoCentavos: (d['descontoCentavos'] as num?)?.toInt() ?? 0,
      totalCentavos: (d['totalCentavos'] as num?)?.toInt() ?? 0,
      pagoCentavos: (d['pagoCentavos'] as num?)?.toInt() ?? 0,
      criadoEm: criado is Timestamp ? criado.toDate() : null,
    );
  }

  bool get aberta => status == 'aberta';

  int get saldoCentavos => totalCentavos - pagoCentavos;

  String get nomeCliente => clienteNome.isEmpty ? 'Sem cadastro' : clienteNome;

  String get rotuloStatus {
    if (status == 'aberta') return 'Aberta';
    if (status == 'paga') return 'Paga';
    if (status == 'cancelada') return 'Cancelada';
    return status;
  }
}
