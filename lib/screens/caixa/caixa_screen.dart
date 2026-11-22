import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/caixa_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import 'despesas_screen.dart';

class CaixaScreen extends StatefulWidget {
  final PerfilUsuario perfil;

  const CaixaScreen({super.key, required this.perfil});

  @override
  State<CaixaScreen> createState() => _CaixaScreenState();
}

class _EntradaFechamento {
  final int contadoCentavos;
  final String observacoes;

  const _EntradaFechamento(this.contadoCentavos, this.observacoes);
}

class _CaixaScreenState extends State<CaixaScreen> {
  final _repo = CaixaRepository();

  String _modo = 'dia'; // dia | semana | mes
  DateTime _ref = DateTime.now();

  late Stream<ResumoCaixa> _resumo;
  late Stream<List<Fechamento>> _fechamentos;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  DateTime get _inicioData {
    if (_modo == 'semana') return segundaDaSemana(_ref);
    if (_modo == 'mes') return DateTime(_ref.year, _ref.month, 1);
    return DateTime(_ref.year, _ref.month, _ref.day);
  }

  DateTime get _fimData {
    final i = _inicioData;
    if (_modo == 'semana') return DateTime(i.year, i.month, i.day + 6);
    if (_modo == 'mes') return DateTime(i.year, i.month + 1, 0);
    return i;
  }

  String get _ini => diaIso(_inicioData);
  String get _fim => diaIso(_fimData);

  void _atualizar() {
    _resumo = _repo.observarResumo(_ini, _fim);
    _fechamentos = _repo.observarFechamentos(_ini);
  }

  void _trocarModo(String modo) {
    setState(() {
      _modo = modo;
      _ref = DateTime.now();
      _atualizar();
    });
  }

  void _mover(int dir) {
    setState(() {
      if (_modo == 'dia') {
        _ref = DateTime(_ref.year, _ref.month, _ref.day + dir);
      } else if (_modo == 'semana') {
        _ref = DateTime(_ref.year, _ref.month, _ref.day + 7 * dir);
      } else {
        _ref = DateTime(_ref.year, _ref.month + dir, 1);
      }
      _atualizar();
    });
  }

  bool get _podeAvancar {
    final hoje = DateTime.now();
    return _fimData.isBefore(DateTime(hoje.year, hoje.month, hoje.day));
  }

  String get _rotuloPeriodo {
    if (_modo == 'mes') {
      final d = _inicioData;
      return '${d.month.toString().padLeft(2, '0')}/${d.year}';
    }
    if (_modo == 'semana') {
      final i = _inicioData;
      final f = _fimData;
      return '${i.day.toString().padLeft(2, '0')}/${i.month.toString().padLeft(2, '0')}'
          ' a ${formatarDia(f)}';
    }
    final hoje = DateTime.now();
    final ehHoje = _ref.year == hoje.year &&
        _ref.month == hoje.month &&
        _ref.day == hoje.day;
    return ehHoje ? 'Hoje, ${formatarDia(_ref)}' : formatarDia(_ref);
  }

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _fechar(ResumoCaixa r) async {
    final entrada = await showDialog<_EntradaFechamento>(
      context: context,
      builder: (_) => _DialogFechamento(esperadoCentavos: r.dinheiroEsperado),
    );

    if (entrada == null || !mounted) return;

    try {
      await _repo.fecharCaixa(
        dia: _ini,
        resumo: r,
        dinheiroContadoCentavos: entrada.contadoCentavos,
        observacoes: entrada.observacoes,
        perfil: widget.perfil,
      );
      _aviso('Caixa fechado.');
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  Widget _cartao(Widget filho, {Color borda = bordaCartao}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: borda),
      ),
      child: filho,
    );
  }

  Widget _titulo(String texto) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
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

  Widget _linha(String rotulo, int centavos, {IconData? icone, Color? cor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          if (icone != null) ...[
            Icon(icone, size: 18, color: Colors.white54),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              rotulo,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          Text(
            Dinheiro.formatar(centavos),
            style: TextStyle(
              color: cor ?? Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _conteudo(ResumoCaixa r) {
    final saldoCor = r.saldo >= 0 ? dourado : Colors.redAccent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _cartao(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo('RECEBIDO'),
              Text(
                Dinheiro.formatar(r.totalEntradas),
                style: const TextStyle(
                  color: dourado,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              Text(
                '${r.qtdPagamentos} pagamento(s)',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 8),
              for (final f in formasPagamento)
                _linha(
                  f.rotulo,
                  r.entradasPorForma[f.chave] ?? 0,
                  icone: f.icone,
                ),
            ],
          ),
        ),
        _cartao(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo('DESPESAS'),
              Text(
                Dinheiro.formatar(r.totalDespesas),
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DespesasScreen(
                        perfil: widget.perfil,
                        ini: _ini,
                        fim: _fim,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dourado,
                    side: const BorderSide(color: dourado),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('VER / LANÇAR DESPESAS'),
                ),
              ),
            ],
          ),
        ),
        _cartao(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo('SALDO DO PERÍODO'),
              Text(
                Dinheiro.formatar(r.saldo),
                style: TextStyle(
                  color: saldoCor,
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              const Text(
                'Recebido menos despesas.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          borda: saldoCor,
        ),
        _cartao(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _titulo('FATURAMENTO x A RECEBER'),
              _linha(
                'Faturamento (${r.qtdComandasPagas} comanda(s) finalizada(s))',
                r.faturamento,
              ),
              _linha(
                'A receber agora (${r.qtdAbertas} comanda(s) aberta(s))',
                r.aReceber,
                cor: Colors.orangeAccent,
              ),
              const SizedBox(height: 4),
              const Text(
                'O "a receber" mostra o saldo das comandas abertas neste '
                'momento, independentemente do período escolhido.',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
        if (_modo == 'dia') _secaoFechamento(r),
      ],
    );
  }

  Widget _secaoFechamento(ResumoCaixa r) {
    return StreamBuilder<List<Fechamento>>(
      stream: _fechamentos,
      builder: (context, snapshot) {
        final lista = snapshot.data ?? [];
        final ultimo = lista.isEmpty ? null : lista.last;

        final alterado = ultimo != null &&
            (ultimo.totalEntradas != r.totalEntradas ||
                ultimo.totalDespesas != r.totalDespesas);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _cartao(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titulo('FECHAMENTO DO DIA'),
                  _linha(
                    'Dinheiro esperado na gaveta',
                    r.dinheiroEsperado,
                    icone: Icons.payments_outlined,
                  ),
                  if (ultimo == null)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Este dia ainda não foi fechado.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    )
                  else ...[
                    const Divider(color: bordaCartao),
                    Text(
                      'Fechado por ${ultimo.fechadoPorNome} em '
                      '${formatarDataHora(ultimo.criadoEm)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    _linha('Dinheiro contado', ultimo.dinheiroContado),
                    _linha(
                      ultimo.diferenca == 0
                          ? 'Diferença'
                          : (ultimo.diferenca > 0
                              ? 'Diferença (sobra)'
                              : 'Diferença (falta)'),
                      ultimo.diferenca,
                      cor: ultimo.diferenca == 0
                          ? dourado
                          : Colors.orangeAccent,
                    ),
                    if (ultimo.observacoes.isNotEmpty)
                      Text(
                        ultimo.observacoes,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    if (lista.length > 1)
                      Text(
                        '${lista.length} fechamentos registrados neste dia.',
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _fechar(r),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dourado,
                        foregroundColor: Colors.black,
                      ),
                      icon: const Icon(Icons.lock_clock),
                      label: Text(
                        ultimo == null ? 'FECHAR CAIXA' : 'FECHAR DE NOVO',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (alterado)
              _cartao(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ALTERADO APÓS O FECHAMENTO',
                      style: TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Recebido: ${Dinheiro.formatar(ultimo.totalEntradas)} '
                      'no fechamento, ${Dinheiro.formatar(r.totalEntradas)} agora.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Despesas: ${Dinheiro.formatar(ultimo.totalDespesas)} '
                      'no fechamento, ${Dinheiro.formatar(r.totalDespesas)} agora.',
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Houve pagamento, estorno ou despesa depois de fechar. '
                      'Se precisar, feche o dia de novo.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                borda: Colors.orangeAccent,
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CAIXA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              for (final m in const [
                ['dia', 'DIA'],
                ['semana', 'SEMANA'],
                ['mes', 'MÊS'],
              ]) ...[
                ChoiceChip(
                  label: Text(m[1]),
                  selected: _modo == m[0],
                  selectedColor: dourado,
                  labelStyle: TextStyle(
                    color: _modo == m[0] ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onSelected: (_) => _trocarModo(m[0]),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                color: dourado,
                onPressed: () => _mover(-1),
              ),
              Expanded(
                child: Text(
                  _rotuloPeriodo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                color: dourado,
                onPressed: _podeAvancar ? () => _mover(1) : null,
              ),
            ],
          ),
          const SizedBox(height: 8),
          StreamBuilder<ResumoCaixa>(
            stream: _resumo,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    'Erro ao carregar o caixa:\n\n${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: dourado),
                  ),
                );
              }

              return _conteudo(snapshot.data!);
            },
          ),
        ],
      ),
    );
  }
}

class _DialogFechamento extends StatefulWidget {
  final int esperadoCentavos;

  const _DialogFechamento({required this.esperadoCentavos});

  @override
  State<_DialogFechamento> createState() => _DialogFechamentoState();
}

class _DialogFechamentoState extends State<_DialogFechamento> {
  final _contado = TextEditingController();
  final _observacoes = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _contado.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  void _confirmar() {
    final centavos = Dinheiro.paraCentavos(_contado.text);

    if (centavos == null) {
      setState(() => _erro = 'Informe o dinheiro contado (use 0 se não houver).');
      return;
    }

    Navigator.pop(
      context,
      _EntradaFechamento(centavos, _observacoes.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contado = Dinheiro.paraCentavos(_contado.text);
    final diferenca =
        contado == null ? null : contado - widget.esperadoCentavos;

    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Fechar caixa', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dinheiro esperado: '
              '${Dinheiro.formatar(widget.esperadoCentavos)}',
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contado,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                labelText: 'Dinheiro contado na gaveta (R\$)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            if (diferenca != null) ...[
              const SizedBox(height: 8),
              Text(
                diferenca == 0
                    ? 'Sem diferença.'
                    : (diferenca > 0
                        ? 'Sobra de ${Dinheiro.formatar(diferenca)}'
                        : 'Falta de ${Dinheiro.formatar(-diferenca)}'),
                style: TextStyle(
                  color: diferenca == 0 ? dourado : Colors.orangeAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _observacoes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fechar registra o resumo do dia. Não bloqueia pagamentos.',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 8),
              Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _confirmar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: const Text('FECHAR CAIXA'),
        ),
      ],
    );
  }
}
