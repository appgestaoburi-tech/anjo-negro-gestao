import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comissao.dart';
import '../models/perfil_usuario.dart';
import '../models/vale.dart';
import '../utils/datas.dart';
import '../utils/dinheiro.dart';

Timestamp? _maior(Timestamp? a, Timestamp? b) {
  if (a == null) return b;
  if (b == null) return a;
  return a.compareTo(b) >= 0 ? a : b;
}

bool _mesmoTs(Timestamp? a, Timestamp? b) {
  if (a == null && b == null) return true;
  if (a == null || b == null) return false;
  return a.compareTo(b) == 0;
}

/// Dados lidos do Firestore, antes de aplicar a regra de período.
class BrutoComissao {
  final List<Comissao> comissoes;
  final List<PagamentoComissao> pagamentos;

  const BrutoComissao(this.comissoes, this.pagamentos);
}

/// O que está a receber (desde o último pagamento válido, até o corte).
/// No modo semanal, o que veio depois do corte fica em "andamento".
class DadosComissaoBarbeiro {
  final List<PagamentoComissao> pagamentos; // mais recente primeiro
  final PagamentoComissao? ultimoValido;
  final Timestamp? de;
  final Timestamp? ate;
  final Timestamp? corte;
  final List<Comissao> creditos;
  final List<Comissao> estornos;
  final int creditosCentavos;
  final int estornosCentavos;
  final int andamentoCentavos; // comissões após o corte, líquidas
  final int andamentoQtd;

  const DadosComissaoBarbeiro({
    required this.pagamentos,
    required this.ultimoValido,
    required this.de,
    required this.ate,
    required this.corte,
    required this.creditos,
    required this.estornos,
    required this.creditosCentavos,
    required this.estornosCentavos,
    required this.andamentoCentavos,
    required this.andamentoQtd,
  });

  int get totalCentavos => creditosCentavos - estornosCentavos;

  static DadosComissaoBarbeiro calcular(
    BrutoComissao bruto, {
    Timestamp? corte,
  }) {
    final ordenados = [...bruto.pagamentos];
    ordenados.sort((a, b) {
      final x = a.criadoEm ?? Timestamp.now();
      final y = b.criadoEm ?? Timestamp.now();
      return y.compareTo(x);
    });

    final validos =
        ordenados.where((p) => !p.estornado && p.ate != null).toList();
    validos.sort((a, b) => b.ate!.compareTo(a.ate!));

    final ultimo = validos.isEmpty ? null : validos.first;
    final de = ultimo?.ate;

    bool depois(Timestamp? t) =>
        t != null && (de == null || t.compareTo(de) > 0);
    bool noCorte(Timestamp? t) =>
        corte == null || (t != null && t.compareTo(corte) <= 0);

    final creditos = bruto.comissoes
        .where((c) => depois(c.criadoEm) && noCorte(c.criadoEm))
        .toList();
    final estornos = bruto.comissoes
        .where((c) => c.estornada && depois(c.estornadaEm) && noCorte(c.estornadaEm))
        .toList();

    creditos.sort((a, b) {
      final x = a.criadoEm ?? Timestamp.now();
      final y = b.criadoEm ?? Timestamp.now();
      return y.compareTo(x);
    });

    // O que veio depois do corte (só existe no modo semanal).
    var andamento = 0;
    var andamentoQtd = 0;
    if (corte != null) {
      for (final c in bruto.comissoes) {
        if (depois(c.criadoEm) && !noCorte(c.criadoEm)) {
          andamento += c.totalCentavos;
          andamentoQtd++;
        }
        if (c.estornada && depois(c.estornadaEm) && !noCorte(c.estornadaEm)) {
          andamento -= c.totalCentavos;
        }
      }
    }

    Timestamp? ate;
    if (creditos.isNotEmpty || estornos.isNotEmpty) {
      if (corte != null) {
        ate = corte;
      } else {
        for (final c in creditos) {
          ate = _maior(ate, c.criadoEm);
        }
        for (final c in estornos) {
          ate = _maior(ate, c.estornadaEm);
        }
      }
    }

    return DadosComissaoBarbeiro(
      pagamentos: ordenados,
      ultimoValido: ultimo,
      de: de,
      ate: ate,
      corte: corte,
      creditos: creditos,
      estornos: estornos,
      creditosCentavos: creditos.fold<int>(0, (s, c) => s + c.totalCentavos),
      estornosCentavos: estornos.fold<int>(0, (s, c) => s + c.totalCentavos),
      andamentoCentavos: andamento,
      andamentoQtd: andamentoQtd,
    );
  }
}

class ComissaoRepository {
  ComissaoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _comissoes =>
      _firestore.collection('comissoes');
  CollectionReference<Map<String, dynamic>> get _pagamentos =>
      _firestore.collection('pagamentosComissao');
  CollectionReference<Map<String, dynamic>> get _controles =>
      _firestore.collection('controlesComissao');
  CollectionReference<Map<String, dynamic>> get _despesas =>
      _firestore.collection('despesas');
  CollectionReference<Map<String, dynamic>> get _vales =>
      _firestore.collection('vales');

  Stream<BrutoComissao> observarBarbeiro(String barbeiroUid) {
    late final StreamController<BrutoComissao> controller;
    final inscricoes = <StreamSubscription<dynamic>>[];

    List<Comissao>? comissoes;
    List<PagamentoComissao>? pagamentos;

    void emitir() {
      if (comissoes == null || pagamentos == null) return;
      controller.add(BrutoComissao(comissoes!, pagamentos!));
    }

    controller = StreamController<BrutoComissao>(
      onListen: () {
        inscricoes.add(
          _comissoes
              .where('barbeiroUid', isEqualTo: barbeiroUid)
              .snapshots()
              .listen((s) {
            comissoes = s.docs.map(Comissao.doDocumento).toList();
            emitir();
          }, onError: controller.addError),
        );

        inscricoes.add(
          _pagamentos
              .where('barbeiroUid', isEqualTo: barbeiroUid)
              .snapshots()
              .listen((s) {
            pagamentos = s.docs.map(PagamentoComissao.doDocumento).toList();
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

  /// Paga a comissão até o corte, já descontando os vales [valesDescontar]
  /// (pagos até o corte). O valor pago entra no caixa como despesa. O
  /// documento de controle garante que duas pessoas não paguem a mesma
  /// janela duas vezes.
  Future<void> pagar({
    required PerfilUsuario perfil,
    required String barbeiroUid,
    required String barbeiroNome,
    required DadosComissaoBarbeiro dados,
    required List<Vale> valesDescontar,
    required String modo,
    required String forma,
    required String observacoes,
  }) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode pagar comissões.');
    }

    final totalVales =
        valesDescontar.fold<int>(0, (s, v) => s + v.saldoCentavos);
    final liquido = dados.totalCentavos - totalVales;

    if (liquido <= 0 || dados.ate == null) {
      throw Exception(
        'Não há comissão a pagar (os vales cobrem o valor da semana).',
      );
    }

    final controleRef = _controles.doc(barbeiroUid);
    final pagamentoRef = _pagamentos.doc();
    final despesaRef = _despesas.doc();
    final hoje = diaIso(DateTime.now());

    final notaVales = totalVales > 0
        ? 'Comissão ${Dinheiro.formatar(dados.totalCentavos)} − '
            'vales ${Dinheiro.formatar(totalVales)}'
        : '';
    final observacoesDespesa = [
      if (observacoes.isNotEmpty) observacoes,
      if (notaVales.isNotEmpty) notaVales,
    ].join(' • ');

    await _firestore.runTransaction((tx) async {
      // Leituras primeiro.
      final controle = await tx.get(controleRef);
      final atual = controle.data()?['ate'];
      final atualTs = atual is Timestamp ? atual : null;

      if (!_mesmoTs(atualTs, dados.de)) {
        throw Exception(
          'Os valores mudaram. Volte e abra a tela de novo antes de pagar.',
        );
      }

      for (final v in valesDescontar) {
        final snap = await tx.get(_vales.doc(v.id));
        final d = snap.data();

        final valor = (d?['valorCentavos'] as num?)?.toInt() ?? 0;
        final descontado = (d?['descontadoCentavos'] as num?)?.toInt() ?? 0;

        if (!snap.exists ||
            d?['status'] != 'pago' ||
            valor - descontado != v.saldoCentavos) {
          throw Exception(
            'Os vales mudaram. Volte e abra a tela de novo antes de pagar.',
          );
        }
      }

      // Escritas.
      tx.set(controleRef, {
        'ate': dados.ate,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      tx.set(pagamentoRef, {
        'barbeiroUid': barbeiroUid,
        'barbeiroNome': barbeiroNome,
        'valorCentavos': liquido,
        'comissaoCentavos': dados.totalCentavos,
        'valesDescontadosCentavos': totalVales,
        'descontosVales': [
          for (final v in valesDescontar)
            {'valeId': v.id, 'valorCentavos': v.saldoCentavos},
        ],
        'creditosCentavos': dados.creditosCentavos,
        'estornosCentavos': dados.estornosCentavos,
        'qtdCreditos': dados.creditos.length,
        'qtdEstornos': dados.estornos.length,
        'modo': modo,
        'de': dados.de,
        'ate': dados.ate,
        'forma': forma,
        'observacoes': observacoes,
        'despesaId': despesaRef.id,
        'dia': hoje,
        'estornado': false,
        'pagoPorUid': perfil.uid,
        'pagoPorNome': perfil.nome,
        'criadoEm': FieldValue.serverTimestamp(),
      });

      for (final v in valesDescontar) {
        tx.update(_vales.doc(v.id), {
          'descontadoCentavos': v.valorCentavos,
        });
      }

      tx.set(despesaRef, {
        'descricao': 'Comissão - $barbeiroNome',
        'categoria': 'Comissões',
        'valorCentavos': liquido,
        'dia': hoje,
        'forma': forma,
        'observacoes': observacoesDespesa,
        'origem': 'comissao',
        'pagamentoComissaoId': pagamentoRef.id,
        'cancelada': false,
        'registradoPorUid': perfil.uid,
        'registradoPorNome': perfil.nome,
        'criadoEm': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Só o último pagamento válido de cada barbeiro pode ser estornado.
  /// O valor volta a ficar a receber, os vales descontados voltam a ficar
  /// a descontar e a despesa do caixa é cancelada.
  Future<void> estornarPagamento(
    String pagamentoId,
    PerfilUsuario perfil,
  ) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode estornar pagamentos.');
    }

    await _firestore.runTransaction((tx) async {
      final pagamentoRef = _pagamentos.doc(pagamentoId);
      final snap = await tx.get(pagamentoRef);

      if (!snap.exists) throw Exception('Pagamento não encontrado.');

      final d = snap.data() ?? <String, dynamic>{};
      if (d['estornado'] == true) {
        throw Exception('Este pagamento já foi estornado.');
      }

      final barbeiroUid = (d['barbeiroUid'] ?? '').toString();
      final controleRef = _controles.doc(barbeiroUid);
      final controle = await tx.get(controleRef);

      final atual = controle.data()?['ate'];
      final atualTs = atual is Timestamp ? atual : null;
      final ate = d['ate'] is Timestamp ? d['ate'] as Timestamp : null;
      final de = d['de'] is Timestamp ? d['de'] as Timestamp : null;

      if (!_mesmoTs(atualTs, ate)) {
        throw Exception(
          'Só o último pagamento de comissão pode ser estornado.',
        );
      }

      // Vales descontados neste pagamento (leitura antes das escritas).
      final devolucoes = <MapEntry<DocumentReference<Map<String, dynamic>>, int>>[];
      final descontos = d['descontosVales'];

      if (descontos is List) {
        for (final m in descontos) {
          if (m is! Map) continue;

          final valeId = (m['valeId'] ?? '').toString();
          final valor = (m['valorCentavos'] as num?)?.toInt() ?? 0;
          if (valeId.isEmpty || valor <= 0) continue;

          final ref = _vales.doc(valeId);
          final valeSnap = await tx.get(ref);
          if (!valeSnap.exists) continue;

          final atualDescontado =
              (valeSnap.data()?['descontadoCentavos'] as num?)?.toInt() ?? 0;
          final novo = atualDescontado - valor;

          devolucoes.add(MapEntry(ref, novo < 0 ? 0 : novo));
        }
      }

      tx.update(pagamentoRef, {
        'estornado': true,
        'estornadoPorUid': perfil.uid,
        'estornadoPorNome': perfil.nome,
        'estornadoEm': FieldValue.serverTimestamp(),
      });

      tx.set(controleRef, {
        'ate': de,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });

      for (final dev in devolucoes) {
        tx.update(dev.key, {'descontadoCentavos': dev.value});
      }

      final despesaId = (d['despesaId'] ?? '').toString();
      if (despesaId.isNotEmpty) {
        tx.update(_despesas.doc(despesaId), {
          'cancelada': true,
          'canceladaPorUid': perfil.uid,
          'canceladaPorNome': perfil.nome,
          'canceladaEm': FieldValue.serverTimestamp(),
          'motivoCancelamento': 'Estorno do pagamento de comissão',
        });
      }
    });
  }
}
