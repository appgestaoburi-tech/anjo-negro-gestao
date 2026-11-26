import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/pacote_calculo.dart';
import 'pacote.dart';

class PacoteCliente {
  final String id;
  final String clienteId;
  final String clienteNome;
  final String clienteTelefone;
  final String pacoteCatalogoId;
  final String nome;
  final int meses;
  final List<ItemPacote> itens;
  final int precoPagoCentavos;
  final int precoTabelaCentavos;
  final int totalUsos;
  final int valorUsoCentavos;
  final String inicio; // aaaa-mm-dd
  final String fim; // aaaa-mm-dd, primeiro dia depois da validade
  final String status; // ativo | cancelado
  final int comandaVendaNumero;
  final String vendidoPorNome;
  final Map<String, int> contadores;
  final Map<String, int> contadoresMes;
  final int usosTotal;
  final Timestamp? criadoEm;

  const PacoteCliente({
    required this.id,
    required this.clienteId,
    required this.clienteNome,
    required this.clienteTelefone,
    required this.pacoteCatalogoId,
    required this.nome,
    required this.meses,
    required this.itens,
    required this.precoPagoCentavos,
    required this.precoTabelaCentavos,
    required this.totalUsos,
    required this.valorUsoCentavos,
    required this.inicio,
    required this.fim,
    required this.status,
    required this.comandaVendaNumero,
    required this.vendidoPorNome,
    required this.contadores,
    required this.contadoresMes,
    required this.usosTotal,
    required this.criadoEm,
  });

  static Map<String, int> _mapaInt(dynamic bruto) {
    final r = <String, int>{};
    if (bruto is Map) {
      bruto.forEach((k, v) {
        if (v is num) r[k.toString()] = v.toInt();
      });
    }
    return r;
  }

  factory PacoteCliente.doDocumento(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
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

    final criado = d['criadoEm'];

    return PacoteCliente(
      id: doc.id,
      clienteId: (d['clienteId'] ?? '').toString(),
      clienteNome: (d['clienteNome'] ?? '').toString(),
      clienteTelefone: (d['clienteTelefone'] ?? '').toString(),
      pacoteCatalogoId: (d['pacoteCatalogoId'] ?? '').toString(),
      nome: (d['nome'] ?? '').toString(),
      meses: (d['meses'] as num?)?.toInt() ?? 1,
      itens: itens,
      precoPagoCentavos: (d['precoPagoCentavos'] as num?)?.toInt() ?? 0,
      precoTabelaCentavos: (d['precoTabelaCentavos'] as num?)?.toInt() ?? 0,
      totalUsos: (d['totalUsos'] as num?)?.toInt() ?? 0,
      valorUsoCentavos: (d['valorUsoCentavos'] as num?)?.toInt() ?? 0,
      inicio: (d['inicio'] ?? '').toString(),
      fim: (d['fim'] ?? '').toString(),
      status: (d['status'] ?? '').toString(),
      comandaVendaNumero: (d['comandaVendaNumero'] as num?)?.toInt() ?? 0,
      vendidoPorNome: (d['vendidoPorNome'] ?? '').toString(),
      contadores: _mapaInt(d['contadores']),
      contadoresMes: _mapaInt(d['contadoresMes']),
      usosTotal: (d['usosTotal'] as num?)?.toInt() ?? 0,
      criadoEm: criado is Timestamp ? criado : null,
    );
  }

  DateTime get inicioData => parseDiaIso(inicio) ?? DateTime.now();
  DateTime get fimData => parseDiaIso(fim) ?? DateTime.now();

  int usado(String servicoId) => contadores[servicoId] ?? 0;

  int usadoNoCiclo(String servicoId, int ciclo) =>
      contadoresMes['${servicoId}_$ciclo'] ?? 0;

  int get restantes => totalUsos - usosTotal;

  /// Valor dos usos já feitos (o último uso absorve os centavos de resto).
  int get consumidoCentavos {
    if (totalUsos <= 0) return 0;
    if (usosTotal >= totalUsos) return precoPagoCentavos;
    return usosTotal * valorUsoCentavos;
  }

  /// Dinheiro recebido que ainda corresponde a serviços a prestar.
  int get aPrestarCentavos => precoPagoCentavos - consumidoCentavos;

  /// ativo | concluido | vencido | cancelado
  String situacao(DateTime agora) {
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (status == 'cancelado') return 'cancelado';
    if (totalUsos > 0 && usosTotal >= totalUsos) return 'concluido';
    if (!hoje.isBefore(fimData)) return 'vencido';
    return 'ativo';
  }

  static String rotuloSituacao(String s) {
    switch (s) {
      case 'ativo':
        return 'ATIVO';
      case 'concluido':
        return 'CONCLUÍDO';
      case 'vencido':
        return 'VENCIDO';
      default:
        return 'CANCELADO';
    }
  }

  String get resumo =>
      itens.map((i) => '${i.qtdTotal}x ${i.servicoNome}').join(' + ');

  String get telefoneFormatado {
    final t = clienteTelefone;
    if (t.length == 11) {
      return '(${t.substring(0, 2)}) ${t.substring(2, 7)}-${t.substring(7)}';
    }
    if (t.length == 10) {
      return '(${t.substring(0, 2)}) ${t.substring(2, 6)}-${t.substring(6)}';
    }
    return t;
  }
}
