import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/formas_pagamento.dart';
import '../models/comanda.dart';
import '../models/despesa.dart';
import '../models/pagamento.dart';
import '../models/perfil_usuario.dart';

class ResumoCaixa {
  final Map<String, int> entradasPorForma;
  final int totalEntradas;
  final int qtdPagamentos;
  final Map<String, int> despesasPorForma;
  final int totalDespesas;
  final int faturamento;
  final int qtdComandasPagas;
  final int aReceber;
  final int qtdAbertas;

  const ResumoCaixa({
    required this.entradasPorForma,
    required this.totalEntradas,
    required this.qtdPagamentos,
    required this.despesasPorForma,
    required this.totalDespesas,
    required this.faturamento,
    required this.qtdComandasPagas,
    required this.aReceber,
    required this.qtdAbertas,
  });

  int get saldo => totalEntradas - totalDespesas;

  /// O que deveria estar na gaveta: dinheiro recebido menos despesas
  /// pagas em dinheiro.
  int get dinheiroEsperado =>
      (entradasPorForma['dinheiro'] ?? 0) -
      (despesasPorForma['dinheiro'] ?? 0);

  static ResumoCaixa calcular({
    required List<Pagamento> pagamentos,
    required List<Despesa> despesas,
    required List<Comanda> finalizadas,
    required List<Comanda> abertas,
  }) {
    final entradas = <String, int>{
      for (final f in formasPagamento) f.chave: 0,
    };
    var totalEntradas = 0;
    var qtd = 0;

    for (final p in pagamentos) {
      if (p.estornado) continue;
      entradas[p.forma] = (entradas[p.forma] ?? 0) + p.valorCentavos;
      totalEntradas += p.valorCentavos;
      qtd++;
    }

    final saidas = <String, int>{
      for (final f in formasPagamento) f.chave: 0,
    };
    var totalDespesas = 0;

    for (final d in despesas) {
      if (d.cancelada) continue;
      saidas[d.forma] = (saidas[d.forma] ?? 0) + d.valorCentavos;
      totalDespesas += d.valorCentavos;
    }

    final pagas = finalizadas.where((c) => c.status == 'paga').toList();
    final faturamento = pagas.fold<int>(0, (s, c) => s + c.totalCentavos);
    final aReceber = abertas.fold<int>(0, (s, c) => s + c.saldoCentavos);

    return ResumoCaixa(
      entradasPorForma: entradas,
      totalEntradas: totalEntradas,
      qtdPagamentos: qtd,
      despesasPorForma: saidas,
      totalDespesas: totalDespesas,
      faturamento: faturamento,
      qtdComandasPagas: pagas.length,
      aReceber: aReceber,
      qtdAbertas: abertas.length,
    );
  }
}

class Fechamento {
  final String id;
  final String dia;
  final int totalEntradas;
  final int totalDespesas;
  final int dinheiroEsperado;
  final int dinheiroContado;
  final int diferenca;
  final String observacoes;
  final String fechadoPorNome;
  final DateTime? criadoEm;

  const Fechamento({
    required this.id,
    required this.dia,
    required this.totalEntradas,
    required this.totalDespesas,
    required this.dinheiroEsperado,
    required this.dinheiroContado,
    required this.diferenca,
    required this.observacoes,
    required this.fechadoPorNome,
    required this.criadoEm,
  });

  factory Fechamento.doDocumento(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final criado = d['criadoEm'];

    return Fechamento(
      id: doc.id,
      dia: (d['dia'] ?? '').toString(),
      totalEntradas: (d['totalEntradasCentavos'] as num?)?.toInt() ?? 0,
      totalDespesas: (d['totalDespesasCentavos'] as num?)?.toInt() ?? 0,
      dinheiroEsperado: (d['dinheiroEsperadoCentavos'] as num?)?.toInt() ?? 0,
      dinheiroContado: (d['dinheiroContadoCentavos'] as num?)?.toInt() ?? 0,
      diferenca: (d['diferencaCentavos'] as num?)?.toInt() ?? 0,
      observacoes: (d['observacoes'] ?? '').toString(),
      fechadoPorNome: (d['fechadoPorNome'] ?? '').toString(),
      criadoEm: criado is Timestamp ? criado.toDate() : null,
    );
  }
}

class CaixaRepository {
  CaixaRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _pagamentos =>
      _firestore.collection('pagamentos');
  CollectionReference<Map<String, dynamic>> get _despesas =>
      _firestore.collection('despesas');
  CollectionReference<Map<String, dynamic>> get _comandas =>
      _firestore.collection('comandas');
  CollectionReference<Map<String, dynamic>> get _fechamentos =>
      _firestore.collection('fechamentosCaixa');

  /// Junta pagamentos, despesas e comandas do período (aaaa-mm-dd,
  /// inclusive) em um resumo que se atualiza em tempo real.
  Stream<ResumoCaixa> observarResumo(String ini, String fim) {
    late final StreamController<ResumoCaixa> controller;
    final inscricoes = <StreamSubscription<dynamic>>[];

    List<Pagamento>? pagamentos;
    List<Despesa>? despesas;
    List<Comanda>? finalizadas;
    List<Comanda>? abertas;

    void emitir() {
      if (pagamentos == null ||
          despesas == null ||
          finalizadas == null ||
          abertas == null) {
        return;
      }
      controller.add(
        ResumoCaixa.calcular(
          pagamentos: pagamentos!,
          despesas: despesas!,
          finalizadas: finalizadas!,
          abertas: abertas!,
        ),
      );
    }

    controller = StreamController<ResumoCaixa>(
      onListen: () {
        inscricoes.add(
          _pagamentos
              .where('dia', isGreaterThanOrEqualTo: ini)
              .where('dia', isLessThanOrEqualTo: fim)
              .snapshots()
              .listen((s) {
            pagamentos = s.docs.map(Pagamento.doDocumento).toList();
            emitir();
          }, onError: controller.addError),
        );

        inscricoes.add(
          _despesas
              .where('dia', isGreaterThanOrEqualTo: ini)
              .where('dia', isLessThanOrEqualTo: fim)
              .snapshots()
              .listen((s) {
            despesas = s.docs.map(Despesa.doDocumento).toList();
            emitir();
          }, onError: controller.addError),
        );

        inscricoes.add(
          _comandas
              .where('finalizadaDia', isGreaterThanOrEqualTo: ini)
              .where('finalizadaDia', isLessThanOrEqualTo: fim)
              .snapshots()
              .listen((s) {
            finalizadas = s.docs.map(Comanda.doDocumento).toList();
            emitir();
          }, onError: controller.addError),
        );

        inscricoes.add(
          _comandas
              .where('status', isEqualTo: 'aberta')
              .snapshots()
              .listen((s) {
            abertas = s.docs.map(Comanda.doDocumento).toList();
            emitir();
          }, onError: controller.addError),
        );
      },
      onCancel: () async {
        for (final i in inscricoes) {
          await i.cancel();
        }
      },
    );

    return controller.stream;
  }

  Stream<List<Fechamento>> observarFechamentos(String dia) {
    return _fechamentos.where('dia', isEqualTo: dia).snapshots().map((snap) {
      final lista = snap.docs.map(Fechamento.doDocumento).toList();
      lista.sort((a, b) {
        final x = a.criadoEm ?? DateTime.now();
        final y = b.criadoEm ?? DateTime.now();
        return x.compareTo(y);
      });
      return lista;
    });
  }

  /// Registra o resumo do dia. Não trava nenhuma operação.
  Future<void> fecharCaixa({
    required String dia,
    required ResumoCaixa resumo,
    required int dinheiroContadoCentavos,
    required String observacoes,
    required PerfilUsuario perfil,
  }) async {
    await _fechamentos.add({
      'dia': dia,
      'totalEntradasCentavos': resumo.totalEntradas,
      'totalDespesasCentavos': resumo.totalDespesas,
      'saldoCentavos': resumo.saldo,
      'entradasPorForma': resumo.entradasPorForma,
      'qtdPagamentos': resumo.qtdPagamentos,
      'dinheiroEsperadoCentavos': resumo.dinheiroEsperado,
      'dinheiroContadoCentavos': dinheiroContadoCentavos,
      'diferencaCentavos': dinheiroContadoCentavos - resumo.dinheiroEsperado,
      'observacoes': observacoes,
      'fechadoPorUid': perfil.uid,
      'fechadoPorNome': perfil.nome,
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }
}
