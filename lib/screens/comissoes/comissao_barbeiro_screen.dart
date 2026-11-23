import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/comissao.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/comissao_repository.dart';
import '../../repositories/configuracao_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import '../../utils/percentual.dart';
import '../../utils/periodo_comissao.dart';

class ComissaoBarbeiroScreen extends StatefulWidget {
  final PerfilUsuario perfil;
  final String barbeiroUid;
  final String barbeiroNome;

  const ComissaoBarbeiroScreen({
    super.key,
    required this.perfil,
    required this.barbeiroUid,
    required this.barbeiroNome,
  });

  @override
  State<ComissaoBarbeiroScreen> createState() => _ComissaoBarbeiroScreenState();
}

class _EntradaPagamento {
  final String forma;
  final String observacoes;

  const _EntradaPagamento(this.forma, this.observacoes);
}

class _ComissaoBarbeiroScreenState extends State<ComissaoBarbeiroScreen> {
  final _repo = ComissaoRepository();
  late final Stream<BrutoComissao> _bruto =
      _repo.observarBarbeiro(widget.barbeiroUid);
  late final Stream<ComissaoConfig> _config =
      ConfiguracaoRepository().observarComissoes();

  bool get _admin => widget.perfil.permissaoTotal;

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  String _periodoPagavel(DadosComissaoBarbeiro d, ComissaoConfig cfg) {
    if (!cfg.semanal || d.corte == null) return '';

    final fim = diaDe(d.corte!);

    if (d.de == null) return 'até ${formatarDia(fim)}';

    final anterior = diaDe(d.de!);
    final ini = DateTime(anterior.year, anterior.month, anterior.day + 1);
    return '${formatarDia(ini)} a ${formatarDia(fim)}';
  }

  Future<void> _pagar(
    DadosComissaoBarbeiro dados,
    ComissaoConfig cfg,
  ) async {
    final periodo = _periodoPagavel(dados, cfg);

    final entrada = await showDialog<_EntradaPagamento>(
      context: context,
      builder: (_) => _DialogPagarComissao(
        nome: widget.barbeiroNome,
        valorCentavos: dados.totalCentavos,
        periodo: periodo,
      ),
    );

    if (entrada == null || !mounted) return;

    try {
      await _repo.pagar(
        perfil: widget.perfil,
        barbeiroUid: widget.barbeiroUid,
        barbeiroNome: widget.barbeiroNome,
        dados: dados,
        modo: cfg.modo,
        forma: entrada.forma,
        observacoes: entrada.observacoes,
      );
      _aviso('Comissão paga e lançada no caixa.');
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  Future<void> _estornar(PagamentoComissao p) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartao,
        title: const Text(
          'Estornar pagamento',
          style: TextStyle(color: dourado),
        ),
        content: Text(
          'Estornar o pagamento de ${Dinheiro.formatar(p.valorCentavos)}? '
          'O valor volta a ficar a receber e a despesa no caixa é cancelada.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('VOLTAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('ESTORNAR'),
          ),
        ],
      ),
    );

    if (confirmou != true || !mounted) return;

    try {
      await _repo.estornarPagamento(p.id, widget.perfil);
      _aviso('Pagamento estornado.');
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Text(
        texto,
        style: const TextStyle(
          color: dourado,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _tileComissao(Comissao c, {bool estorno = false}) {
    final cor = estorno ? Colors.redAccent : dourado;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: ExpansionTile(
        shape: const Border(),
        collapsedShape: const Border(),
        iconColor: dourado,
        collapsedIconColor: Colors.white54,
        title: Text(
          '#${c.comandaNumero} • '
          '${c.clienteNome.isEmpty ? 'Sem cadastro' : c.clienteNome}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          '${formatarDiaIso(c.dia)}${estorno ? ' • comanda estornada' : ''}',
          style: TextStyle(
            color: estorno ? Colors.redAccent : Colors.white54,
            fontSize: 12,
          ),
        ),
        trailing: Text(
          '${estorno ? '− ' : ''}${Dinheiro.formatar(c.totalCentavos)}',
          style: TextStyle(color: cor, fontWeight: FontWeight.bold),
        ),
        children: [
          for (final l in c.linhas)
            ListTile(
              dense: true,
              title: Text(l.nome, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                'base ${Dinheiro.formatar(l.baseCentavos)} x '
                '${bpParaTexto(l.bp)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Text(
                Dinheiro.formatar(l.comissaoCentavos),
                style: const TextStyle(fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _itemPagamento(PagamentoComissao p, bool ultimo) {
    final detalhes = <String>[
      formatarDataHora(p.criadoEm?.toDate()),
      rotuloForma(p.forma),
      'por ${p.pagoPorNome}',
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Row(
        children: [
          Icon(
            Icons.payments_outlined,
            color: p.estornado ? Colors.white38 : dourado,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  Dinheiro.formatar(p.valorCentavos),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: p.estornado ? Colors.white38 : Colors.white,
                    decoration:
                        p.estornado ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhes.join(' • '),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (p.estornado)
                  Text(
                    'ESTORNADO por ${p.estornadoPorNome}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (_admin && ultimo && !p.estornado)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (_) => _estornar(p),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'estornar', child: Text('Estornar')),
              ],
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _cartaoAndamento(
    DadosComissaoBarbeiro d,
    ComissaoConfig cfg,
    DateTime agora,
  ) {
    final inicio = inicioSemanaAtual(agora, cfg.diaInicio);
    final fimSemana = DateTime(inicio.year, inicio.month, inicio.day + 6);
    final proximo = DateTime(inicio.year, inicio.month, inicio.day + 7);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SEMANA EM ANDAMENTO',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            Dinheiro.formatar(d.andamentoCentavos),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${formatarDia(inicio)} a ${formatarDia(fimSemana)} • '
            '${d.andamentoQtd} comissão(ões). Será paga a partir de '
            '${nomesDiasSemana[proximo.weekday].toLowerCase()}, '
            '${formatarDia(proximo)}.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(
    DadosComissaoBarbeiro d,
    ComissaoConfig cfg,
    DateTime agora,
  ) {
    final total = d.totalCentavos;
    final cor = total < 0 ? Colors.redAccent : dourado;

    // No modo semanal, o pagamento só é liberado 10 minutos depois da
    // virada da semana (a regra do Firebase também confere isso).
    final liberado = !cfg.semanal ||
        agora.isAfter(
          inicioSemanaAtual(agora, cfg.diaInicio)
              .add(const Duration(minutes: 10)),
        );

    final periodo = _periodoPagavel(d, cfg);
    final nadaFechado = d.creditos.isEmpty && d.estornos.isEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cartao,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: cor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cfg.semanal ? 'A RECEBER (SEMANAS FECHADAS)' : 'A RECEBER',
                style: const TextStyle(
                  color: dourado,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Dinheiro.formatar(total),
                style: TextStyle(
                  color: cor,
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              if (periodo.isNotEmpty && !nadaFechado)
                Text(
                  'Período: $periodo',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              const SizedBox(height: 4),
              Text(
                'Comissões: ${Dinheiro.formatar(d.creditosCentavos)}'
                '${d.estornosCentavos > 0 ? ' • Estornos: − ${Dinheiro.formatar(d.estornosCentavos)}' : ''}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              if (cfg.semanal && nadaFechado)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Nenhuma semana fechada com comissão a pagar.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              if (total < 0)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Saldo negativo: houve estorno de comissão já paga. '
                    'O valor será descontado das próximas comissões.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              if (_admin && total > 0 && d.ate != null) ...[
                const SizedBox(height: 12),
                if (!liberado)
                  const Text(
                    'O pagamento é liberado 10 minutos depois da virada da '
                    'semana.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 12),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _pagar(d, cfg),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dourado,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text(
                        'PAGAR COMISSÃO',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        if (cfg.semanal) _cartaoAndamento(d, cfg, agora),
        _titulo(cfg.semanal ? 'COMISSÕES DAS SEMANAS FECHADAS' : 'COMISSÕES A RECEBER'),
        if (nadaFechado)
          const Text(
            'Nenhuma comissão pendente.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final c in d.creditos) _tileComissao(c),
        if (d.estornos.isNotEmpty) ...[
          _titulo('ESTORNOS NESTA JANELA'),
          for (final c in d.estornos) _tileComissao(c, estorno: true),
        ],
        _titulo('HISTÓRICO DE PAGAMENTOS'),
        if (d.pagamentos.isEmpty)
          const Text(
            'Nenhum pagamento de comissão registrado.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final p in d.pagamentos)
          _itemPagamento(p, d.ultimoValido?.id == p.id),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _admin
              ? 'COMISSÃO • ${widget.barbeiroNome.toUpperCase()}'
              : 'MINHAS COMISSÕES',
        ),
      ),
      body: StreamBuilder<ComissaoConfig>(
        stream: _config,
        builder: (context, cfgSnap) {
          final cfg = cfgSnap.data ?? const ComissaoConfig();

          return StreamBuilder<BrutoComissao>(
            stream: _bruto,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: SelectableText(
                      'Erro ao carregar as comissões:\n\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: dourado),
                );
              }

              final agora = DateTime.now();
              final corte =
                  cfg.semanal ? corteSemanal(agora, cfg.diaInicio) : null;
              final dados = DadosComissaoBarbeiro.calcular(
                snapshot.data!,
                corte: corte,
              );

              return _conteudo(dados, cfg, agora);
            },
          );
        },
      ),
    );
  }
}

class _DialogPagarComissao extends StatefulWidget {
  final String nome;
  final int valorCentavos;
  final String periodo;

  const _DialogPagarComissao({
    required this.nome,
    required this.valorCentavos,
    required this.periodo,
  });

  @override
  State<_DialogPagarComissao> createState() => _DialogPagarComissaoState();
}

class _DialogPagarComissaoState extends State<_DialogPagarComissao> {
  final _observacoes = TextEditingController();
  String _forma = 'dinheiro';
  bool _confirmou = false;
  String? _erro;

  @override
  void dispose() {
    _observacoes.dispose();
    super.dispose();
  }

  void _confirmar() {
    if (!_confirmou) {
      setState(() => _erro = 'Marque a confirmação do pagamento.');
      return;
    }
    Navigator.pop(context, _EntradaPagamento(_forma, _observacoes.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Pagar comissão', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.nome}: ${Dinheiro.formatar(widget.valorCentavos)}',
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (widget.periodo.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Período: ${widget.periodo}',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
            const SizedBox(height: 14),
            const Text('Forma de pagamento:'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in formasPagamento.where(
                  (f) => f.chave == 'dinheiro' || f.chave == 'pix',
                ))
                  ChoiceChip(
                    label: Text(f.rotulo),
                    selected: _forma == f.chave,
                    selectedColor: dourado,
                    labelStyle: TextStyle(
                      color: _forma == f.chave ? Colors.black : Colors.white,
                    ),
                    onSelected: (_) => setState(() => _forma = f.chave),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _observacoes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            const SizedBox(height: 6),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: dourado,
              checkColor: Colors.black,
              value: _confirmou,
              onChanged: (v) => setState(() {
                _confirmou = v == true;
                _erro = null;
              }),
              title: const Text(
                'Confirmo que o valor foi pago ao funcionário.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const Text(
              'O pagamento será lançado no caixa como despesa.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (_erro != null) ...[
       
