import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/formas_pagamento.dart';
import '../models/comanda.dart';
import '../models/pagamento.dart';
import '../models/perfil_usuario.dart';
import '../models/produto.dart';
import '../utils/comissao_calculo.dart';
import '../utils/datas.dart';
import '../utils/dinheiro.dart';
import '../utils/pacote_calculo.dart';
import '../utils/rateio.dart';

class _Movimento {
  final DocumentReference<Map<String, dynamic>> ref;
  final Produto produto;
  final ItemProduto item;

  _Movimento(this.ref, this.produto, this.item);
}

class PagamentoRepository {
  PagamentoRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('pagamentos');
  CollectionReference<Map<String, dynamic>> get _comandas =>
      _firestore.collection('comandas');
  CollectionReference<Map<String, dynamic>> get _produtos =>
      _firestore.collection('produtos');
  CollectionReference<Map<String, dynamic>> get _movimentos =>
      _firestore.collection('movimentosEstoque');
  CollectionReference<Map<String, dynamic>> get _usuarios =>
      _firestore.collection('usuarios');
  CollectionReference<Map<String, dynamic>> get _comissoes =>
      _firestore.collection('comissoes');
  CollectionReference<Map<String, dynamic>> get _clientes =>
      _firestore.collection('clientes');
  CollectionReference<Map<String, dynamic>> get _pacotesClientes =>
      _firestore.collection('pacotesClientes');

  Stream<List<Pagamento>> observarDaComanda(
    String comandaId,
    PerfilUsuario perfil,
  ) {
    Query<Map<String, dynamic>> consulta =
        _col.where('comandaId', isEqualTo: comandaId);

    if (!perfil.permissaoTotal) {
      consulta = consulta.where('barbeiroUid', isEqualTo: perfil.uid);
    }

    return consulta.snapshots().map((snap) {
      final lista = snap.docs.map(Pagamento.doDocumento).toList();
      lista.sort((a, b) {
        final x = a.criadoEm ?? DateTime.now();
        final y = b.criadoEm ?? DateTime.now();
        return x.compareTo(y);
      });
      return lista;
    });
  }

  /// Calcula a comissão com os percentuais do barbeiro neste momento.
  /// O administrador principal não gera comissão (retorna nulo).
  ResultadoComissao? _comissaoDaComanda(
    Comanda c,
    DocumentSnapshot<Map<String, dynamic>> barbeiro,
  ) {
    if (!barbeiro.exists) {
      throw Exception('Cadastro do barbeiro não encontrado.');
    }

    final b = barbeiro.data() ?? <String, dynamic>{};
    if (b['permissaoTotal'] == true) return null;

    final padrao = (b['comissaoBp'] as num?)?.toInt();
    if (padrao == null) {
      throw Exception(
        'Defina a comissão de ${c.barbeiroNome} em Funcionários '
        'antes de receber.',
      );
    }

    final categorias = <String, int>{};
    final brutas = b['comissaoCategoriasBp'];
    if (brutas is Map) {
      brutas.forEach((k, v) {
        if (v is num) categorias[k.toString()] = v.toInt();
      });
    }

    return calcularComissao(
      comanda: c,
      servicoPadraoBp: padrao,
      categoriasBp: categorias,
      produtosBp: (b['comissaoProdutosBp'] as num?)?.toInt(),
    );
  }

  /// Registra o pagamento. Se ele quitar a comanda, finaliza, dá baixa
  /// no estoque, grava a comissão e cria os pacotes vendidos na MESMA
  /// operação (tudo ou nada).
  Future<void> registrar({
    required String comandaId,
    required String forma,
    required int valorCentavos,
    required int recebidoCentavos,
    required PerfilUsuario perfil,
  }) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _comandas.doc(comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);
      final bruto = comandaSnap.data() ?? <String, dynamic>{};
      final finalizacoes = (bruto['finalizacoes'] as num?)?.toInt() ?? 0;

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');
      if (!perfil.permissaoTotal && c.barbeiroUid != perfil.uid) {
        throw Exception(
          'Somente o barbeiro responsável ou o administrador pode receber.',
        );
      }
      if (c.descontoPendente) {
        throw Exception(
          'Há um pedido de desconto aguardando autorização. '
          'Aguarde a decisão do administrador.',
        );
      }
      if (c.totalCentavos <= 0) {
        throw Exception('A comanda não tem valor a receber.');
      }
      if (!formasPagamento.any((f) => f.chave == forma)) {
        throw Exception('Forma de pagamento inválida.');
      }
      if (valorCentavos <= 0) {
        throw Exception('Informe um valor maior que zero.');
      }
      if (valorCentavos > c.saldoCentavos) {
        throw Exception(
          'O valor é maior que o saldo '
          '(${Dinheiro.formatar(c.saldoCentavos)}).',
        );
      }
      if (forma == 'dinheiro' && valorCentavos != c.saldoCentavos) {
        throw Exception(
          'O pagamento em dinheiro deve quitar todo o saldo '
          '(${Dinheiro.formatar(c.saldoCentavos)}). '
          'Para pagar parcialmente, use Pix ou cartão.',
        );
      }

      final novoPago = c.pagoCentavos + valorCentavos;
      final quita = novoPago == c.totalCentavos;

      // Todas as leituras antes de qualquer escrita.
      final baixas = <_Movimento>[];
      final indicesPacote = <int>[];
      ResultadoComissao? comissao;
      var telefoneCliente = '';

      if (quita) {
        for (final item in c.produtos) {
          final ref = _produtos.doc(item.produtoId);
          final snap = await tx.get(ref);

          if (!snap.exists) {
            throw Exception(
              'O produto "${item.nome}" não existe mais no cadastro.',
            );
          }

          final p = Produto.doDocumento(snap);
          if (p.estoqueQtd < item.quantidade) {
            throw Exception(
              'Estoque insuficiente de ${item.nome}: há ${p.estoqueQtd} '
              'e a comanda tem ${item.quantidade}.',
            );
          }
          baixas.add(_Movimento(ref, p, item));
        }

        for (var i = 0; i < c.servicos.length; i++) {
          if (c.servicos[i].ehPacote) indicesPacote.add(i);
        }

        if (indicesPacote.isNotEmpty) {
          if (c.clienteId.isEmpty) {
            throw Exception(
              'Para vender pacote, a comanda precisa ter um cliente '
              'cadastrado.',
            );
          }
          final clienteSnap = await tx.get(_clientes.doc(c.clienteId));
          telefoneCliente = (clienteSnap.data()?['telefone'] ?? '').toString();
        }

        final barbeiro = await tx.get(_usuarios.doc(c.barbeiroUid));
        comissao = _comissaoDaComanda(c, barbeiro);
      }

      final agora = DateTime.now();
      final troco = (forma == 'dinheiro' && recebidoCentavos > valorCentavos)
          ? recebidoCentavos - valorCentavos
          : 0;

      tx.set(_col.doc(), {
        'comandaId': c.id,
        'comandaNumero': c.numero,
        'barbeiroUid': c.barbeiroUid,
        'barbeiroNome': c.barbeiroNome,
        'clienteNome': c.clienteNome,
        'forma': forma,
        'valorCentavos': valorCentavos,
        'recebidoCentavos': forma == 'dinheiro' ? recebidoCentavos : 0,
        'trocoCentavos': troco,
        'registradoPorUid': perfil.uid,
        'registradoPorNome': perfil.nome,
        'estornado': false,
        'dia': diaIso(agora),
        'criadoEm': FieldValue.serverTimestamp(),
      });

      final campos = <String, dynamic>{
        'pagoCentavos': novoPago,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      String? comissaoId;
      final idsPacotes = <String>[
        for (final i in indicesPacote) '${c.id}_${finalizacoes + 1}_$i',
      ];

      if (quita) {
        campos['status'] = 'paga';
        campos['finalizadaEm'] = FieldValue.serverTimestamp();
        campos['finalizadaPorUid'] = perfil.uid;
        campos['finalizadaDia'] = diaIso(agora);
        campos['finalizacoes'] = finalizacoes + 1;

        if (comissao != null && comissao.linhas.isNotEmpty) {
          comissaoId = '${c.id}_${finalizacoes + 1}';
          campos['comissaoAtualId'] = comissaoId;
        }

        if (idsPacotes.isNotEmpty) {
          campos['pacotesClientesIds'] = idsPacotes;
        }
      }

      tx.update(comandaRef, campos);

      if (comissao != null && comissaoId != null) {
        tx.set(_comissoes.doc(comissaoId), {
          'comandaId': c.id,
          'comandaNumero': c.numero,
          'barbeiroUid': c.barbeiroUid,
          'barbeiroNome': c.barbeiroNome,
          'clienteNome': c.clienteNome,
          'dia': diaIso(agora),
          'status': 'ativa',
          'totalComissaoCentavos': comissao.totalCentavos,
          'baseServicosCentavos': comissao.baseServicosCentavos,
          'baseProdutosCentavos': comissao.baseProdutosCentavos,
          'descontoCentavos': c.descontoCentavos,
          'linhas': comissao.linhas.map((l) => l.paraMapa()).toList(),
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }

      // Pacotes vendidos: o valor pago já considera a parte do desconto.
      if (indicesPacote.isNotEmpty) {
        final partes = ratearDesconto(
          c.servicos.map((s) => s.precoCentavos).toList(),
          c.descontoCentavos,
        );
        final hoje = DateTime(agora.year, agora.month, agora.day);

        for (var n = 0; n < indicesPacote.length; n++) {
          final i = indicesPacote[n];
          final linha = c.servicos[i];
          final copia = linha.pacote ?? const <String, dynamic>{};

          final meses = (copia['meses'] as num?)?.toInt() ?? 1;
          final itens = <Map<String, dynamic>>[];
          final brutos = copia['itens'];
          if (brutos is List) {
            for (final m in brutos) {
              if (m is Map) itens.add(Map<String, dynamic>.from(m));
            }
          }

          final totalUsos = itens.fold<int>(
            0,
            (s, m) => s + ((m['qtdTotal'] as num?)?.toInt() ?? 0),
          );

          var precoPago = linha.precoCentavos - partes[i];
          if (precoPago < 0) precoPago = 0;

          final valorUso = totalUsos > 0 ? precoPago ~/ totalUsos : 0;
          final fim = somarMeses(hoje, meses);

          tx.set(_pacotesClientes.doc(idsPacotes[n]), {
            'clienteId': c.clienteId,
            'clienteNome': c.clienteNome,
            'clienteTelefone': telefoneCliente,
            'pacoteCatalogoId': linha.pacoteId,
            'nome': (copia['nome'] ?? linha.nome).toString(),
            'meses': meses,
            'itens': itens,
            'precoPagoCentavos': precoPago,
            'precoTabelaCentavos': linha.precoCentavos,
            'totalUsos': totalUsos,
            'valorUsoCentavos': valorUso,
            'inicio': diaIso(hoje),
            'fim': diaIso(fim),
            'validoAte': Timestamp.fromDate(fim),
            'status': 'ativo',
            'comandaVendaId': c.id,
            'comandaVendaNumero': c.numero,
            'vendidoPorUid': perfil.uid,
            'vendidoPorNome': perfil.nome,
            'barbeiroVendaNome': c.barbeiroNome,
            'contadores': <String, dynamic>{},
            'contadoresMes': <String, dynamic>{},
            'usosTotal': 0,
            'criadoEm': FieldValue.serverTimestamp(),
          });
        }
      }

      for (final b in baixas) {
        tx.update(b.ref, {
          'estoqueQtd': b.produto.estoqueQtd - b.item.quantidade,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
        tx.set(_movimentos.doc(), {
          'produtoId': b.produto.id,
          'produtoNome': b.produto.nome,
          'tipo': 'saida',
          'quantidade': b.item.quantidade,
          'motivo': 'Venda - comanda #${c.numero}',
          'comandaId': c.id,
          'usuarioUid': perfil.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Só o administrador. O pagamento continua no histórico, marcado como
  /// estornado. Se a comanda estava paga, ela reabre, o estoque volta, a
  /// comissão é estornada e os pacotes vendidos nela são cancelados (se
  /// algum já tiver usos, o estorno é bloqueado).
  Future<void> estornar(
    String pagamentoId,
    PerfilUsuario perfil, {
    String motivo = '',
  }) async {
    if (!perfil.permissaoTotal) {
      throw Exception('Somente o administrador pode estornar pagamentos.');
    }

    await _firestore.runTransaction((tx) async {
      final pagRef = _col.doc(pagamentoId);
      final pagSnap = await tx.get(pagRef);

      if (!pagSnap.exists) throw Exception('Pagamento não encontrado.');

      final pag = Pagamento.doDocumento(pagSnap);
      if (pag.estornado) throw Exception('Este pagamento já foi estornado.');

      final comandaRef = _comandas.doc(pag.comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);
      final bruto = comandaSnap.data() ?? <String, dynamic>{};

      if (c.status == 'cancelada') {
        throw Exception('A comanda está cancelada.');
      }

      final reabre = c.status == 'paga';

      final devolucoes = <_Movimento>[];
      final pacotesCancelar =
          <DocumentReference<Map<String, dynamic>>>[];
      DocumentReference<Map<String, dynamic>>? comissaoRef;
      DocumentSnapshot<Map<String, dynamic>>? comissaoSnap;

      if (reabre) {
        for (final item in c.produtos) {
          final ref = _produtos.doc(item.produtoId);
          final snap = await tx.get(ref);
          if (snap.exists) {
            devolucoes.add(_Movimento(ref, Produto.doDocumento(snap), item));
          }
        }

        final comissaoId = (bruto['comissaoAtualId'] ?? '').toString();
        if (comissaoId.isNotEmpty) {
          comissaoRef = _comissoes.doc(comissaoId);
          comissaoSnap = await tx.get(comissaoRef);
        }

        final ids = bruto['pacotesClientesIds'];
        if (ids is List) {
          for (final id in ids) {
            final ref = _pacotesClientes.doc(id.toString());
            final snap = await tx.get(ref);
            if (!snap.exists) continue;

            final d = snap.data() ?? <String, dynamic>{};
            if (d['status'] == 'cancelado') continue;

            final usos = (d['usosTotal'] as num?)?.toInt() ?? 0;
            if (usos > 0) {
              throw Exception(
                'Este estorno cancelaria o pacote de '
                '${(d['clienteNome'] ?? '').toString()}, que já tem '
                '$usos uso(s) lançado(s). Não é possível estornar.',
              );
            }
            pacotesCancelar.add(ref);
          }
        }
      }

      tx.update(pagRef, {
        'estornado': true,
        'estornadoPorUid': perfil.uid,
        'estornadoPorNome': perfil.nome,
        'estornadoEm': FieldValue.serverTimestamp(),
        'motivoEstorno': motivo,
      });

      final novoPago = c.pagoCentavos - pag.valorCentavos;

      final campos = <String, dynamic>{
        'pagoCentavos': novoPago < 0 ? 0 : novoPago,
        'atualizadoEm': FieldValue.serverTimestamp(),
      };

      if (reabre) {
        campos['status'] = 'aberta';
        campos['reabertaEm'] = FieldValue.serverTimestamp();
        campos['reabertaPorUid'] = perfil.uid;
        campos['finalizadaEm'] = FieldValue.delete();
        campos['finalizadaDia'] = FieldValue.delete();
        campos['comissaoAtualId'] = FieldValue.delete();
        campos['pacotesClientesIds'] = FieldValue.delete();
      }

      tx.update(comandaRef, campos);

      if (comissaoRef != null &&
          comissaoSnap != null &&
          comissaoSnap.exists &&
          comissaoSnap.data()?['status'] == 'ativa') {
        tx.update(comissaoRef, {
          'status': 'estornada',
          'estornadaEm': FieldValue.serverTimestamp(),
          'estornadaPorUid': perfil.uid,
        });
      }

      for (final ref in pacotesCancelar) {
        tx.update(ref, {
          'status': 'cancelado',
          'canceladoPorUid': perfil.uid,
          'canceladoPorNome': perfil.nome,
          'canceladoEm': FieldValue.serverTimestamp(),
          'motivoCancelamento': 'Estorno do pagamento da venda',
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
      }

      for (final d in devolucoes) {
        tx.update(d.ref, {
          'estoqueQtd': d.produto.estoqueQtd + d.item.quantidade,
          'atualizadoEm': FieldValue.serverTimestamp(),
        });
        tx.set(_movimentos.doc(), {
          'produtoId': d.produto.id,
          'produtoNome': d.produto.nome,
          'tipo': 'entrada',
          'quantidade': d.item.quantidade,
          'motivo': 'Estorno - comanda #${c.numero}',
          'comandaId': c.id,
          'usuarioUid': perfil.uid,
          'criadoEm': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}
