import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comissao.dart';
import '../../models/perfil_usuario.dart';
import '../../models/vale.dart';
import '../../repositories/comissao_repository.dart';
import '../../repositories/configuracao_repository.dart';
import '../../repositories/vale_repository.dart';
import '../../utils/datas.dart';
import '../../utils/desconto_vales.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import '../../utils/periodo_comissao.dart';
import 'dialogo_pagar_comissao.dart';
import 'itens_comissao.dart';

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

class _ComissaoBarbeiroScreenState extends State<ComissaoBarbeiroScreen> {
  final _repo = ComissaoRepository();
  late final Stream<BrutoComissao> _bruto =
      _repo.observarBarbeiro(widget.barbeiroUid);
  late final Stream<ComissaoConfig> _config =
      ConfiguracaoRepository().observarComissoes();
  late final Stream<List<Vale>> _vales =
      ValeRepository().observarDoBarbeiro(widget.barbeiroUid);

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
    PlanoVales plano,
  ) async {
    final liquido = dados.totalCentavos - plano.totalCentavos;

    final entrada = await showDialog<EntradaPagamentoComissao>(
      context: context,
      builder: (_) => DialogPagarComissao(
        nome: widget.barbeiroNome,
        comissaoCentavos: dados.totalCentavos,
        valesCentavos: plano.totalCentavos,
        valorCentavos: liquido,
        periodo: _periodoPagavel(dados, cfg),
      ),
    );

    if (entrada == null || !mounted) return;

    try {
      await _repo.pagar(
        perfil: widget.perfil,
        barbeiroUid: widget.barbeiroUid,
        barbeiroNome: widget.barbeiroNome,
        dados: dados,
        valesDescontar: plano.aDescontar,
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
          'O valor volta a ficar a receber, os vales descontados voltam a '
          'ficar a descontar e a despesa no caixa é cancelada.',
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

  Widget _linhaValor(String rotulo, String valor, {Color? cor}) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Text(
            valor,
            style: TextStyle(
              color: cor ?? Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartaoAndamento(
    DadosComissaoBarbeiro d,
    ComissaoConfig cfg,
    DateTime agora,
    PlanoVales plano,
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
          if (plano.aposLimiteCentavos > 0)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Vales pagos nesta semana: '
                '${Dinheiro.formatar(plano.aposLimiteCentavos)} '
                '(serão descontados no próximo pagamento).',
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _conteudo(
    DadosComissaoBarbeiro d,
    ComissaoConfig cfg,
    DateTime agora,
    List<Vale> vales,
  ) {
    final plano = planejarVales(vales, limite: cfg.semanal ? d.corte : null);

    final comissao = d.totalCentavos;
    final liquido = comissao - plano.totalCentavos;
    final valesCobrem = comissao > 0 && plano.totalCentavos >= comissao;
    final cor = liquido < 0 ? Colors.redAccent : dourado;

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
                Dinheiro.formatar(liquido < 0 ? 0 : liquido),
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
              const SizedBox(height: 6),
              _linhaValor('Comissões', Dinheiro.formatar(d.creditosCentavos)),
              if (d.estornosCentavos > 0)
                _linhaValor(
                  'Estornos de comanda',
                  '− ${Dinheiro.formatar(d.estornosCentavos)}',
                  cor: Colors.redAccent,
                ),
              if (plano.totalCentavos > 0 && comissao > 0)
                _linhaValor(
                  'Vales a descontar',
                  '− ${Dinheiro.formatar(plano.totalCentavos)}',
                  cor: Colors.orangeAccent,
                ),
              if (cfg.semanal && nadaFechado)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'Nenhuma semana fechada com comissão a pagar.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
              if (valesCobrem)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Os vales cobrem a comissão deste período. Nada a pagar '
                    'agora: a diferença de '
                    '${Dinheiro.formatar(plano.totalCentavos - comissao)} '
                    'será descontada das próximas comissões.',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 12,
                    ),
                  ),
                ),
              if (comissao < 0)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Saldo negativo: houve estorno de comissão já paga. '
                    'O valor será descontado das próximas comissões.',
                    style: TextStyle(color: Colors.redAccent, fontSize: 12),
                  ),
                ),
              if (_admin && liquido > 0 && d.ate != null) ...[
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
                      onPressed: () => _pagar(d, cfg, plano),
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
        if (cfg.semanal) _cartaoAndamento(d, cfg, agora, plano),
        _titulo(
          cfg.semanal ? 'COMISSÕES DAS SEMANAS FECHADAS' : 'COMISSÕES A RECEBER',
        ),
        if (nadaFechado)
          const Text(
            'Nenhuma comissão pendente.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final c in d.creditos) TileComissao(comissao: c),
        if (d.estornos.isNotEmpty) ...[
          _titulo('ESTORNOS NESTA JANELA'),
          for (final c in d.estornos) TileComissao(comissao: c, estorno: true),
        ],
        _titulo('HISTÓRICO DE PAGAMENTOS'),
        if (d.pagamentos.isEmpty)
          const Text(
            'Nenhum pagamento de comissão registrado.',
            style: TextStyle(color: Colors.white54),
          ),
        for (final p in d.pagamentos)
          ItemPagamentoComissao(
            pagamento: p,
            podeEstornar: _admin && d.ultimoValido?.id == p.id,
            onEstornar: () => _estornar(p),
          ),
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

          return StreamBuilder<List<Vale>>(
            stream: _vales,
            builder: (context, valesSnap) {
              final vales = valesSnap.data ?? const <Vale>[];

              return StreamBuilder<BrutoComissao>(
                stream: _bruto,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: SelectableText(
                          'Erro ao carregar as comissões:\n\n'
                          '${snapshot.error}',
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

                  return _conteudo(dados, cfg, agora, vales);
                },
              );
            },
          );
        },
      ),
    );
  }
}
