import 'package:flutter/material.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/perfil_usuario.dart';
import '../../models/vale.dart';
import '../../repositories/vale_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class ValesScreen extends StatefulWidget {
  final PerfilUsuario perfil;

  const ValesScreen({super.key, required this.perfil});

  @override
  State<ValesScreen> createState() => _ValesScreenState();
}

class _ValesScreenState extends State<ValesScreen> {
  final _repo = ValeRepository();

  late final Stream<List<Vale>> _stream = _admin
      ? _repo.observarTodos()
      : _repo.observarDoBarbeiro(widget.perfil.uid);

  String _filtro = 'pendente'; // só para o administrador

  bool get _admin => widget.perfil.permissaoTotal;

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _executar(Future<void> Function() acao, String sucesso) async {
    try {
      await acao();
      _aviso(sucesso);
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  Future<void> _pedir() async {
    final r = await showDialog<_PedidoVale>(
      context: context,
      builder: (_) => const _DialogPedirVale(),
    );

    if (r == null || !mounted) return;

    await _executar(
      () => _repo.criar(
        perfil: widget.perfil,
        valorCentavos: r.valorCentavos,
        motivo: r.motivo,
      ),
      'Pedido enviado ao administrador.',
    );
  }

  Future<void> _recusar(Vale v) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogRecusarVale(),
    );

    if (motivo == null || !mounted) return;

    await _executar(
      () => _repo.decidir(v.id, false, widget.perfil, motivoRecusa: motivo),
      'Pedido recusado.',
    );
  }

  Future<void> _pagar(Vale v) async {
    final forma = await showDialog<String>(
      context: context,
      builder: (_) => _DialogPagarVale(vale: v),
    );

    if (forma == null || !mounted) return;

    await _executar(
      () => _repo.pagar(v.id, widget.perfil, forma),
      'Vale pago e lançado no caixa.',
    );
  }

  Future<void> _confirmar({
    required String titulo,
    required String texto,
    required String botao,
    required Future<void> Function() acao,
    required String sucesso,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cartao,
        title: Text(titulo, style: const TextStyle(color: dourado)),
        content: Text(texto),
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
            child: Text(botao),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;
    await _executar(acao, sucesso);
  }

  Color _corStatus(String status) {
    switch (status) {
      case 'pendente':
        return Colors.orangeAccent;
      case 'aprovado':
        return dourado;
      case 'pago':
        return Colors.greenAccent;
      case 'recusado':
        return Colors.redAccent;
      default:
        return Colors.white38;
    }
  }

  bool _passaFiltro(Vale v) {
    if (!_admin || _filtro == 'todos') return true;
    return v.status == _filtro;
  }

  Widget _resumoBarbeiro(List<Vale> lista) {
    final aDescontar = lista
        .where((v) => v.status == 'pago')
        .fold<int>(0, (s, v) => s + v.saldoCentavos);
    final emAnalise = lista
        .where((v) => v.status == 'pendente' || v.status == 'aprovado')
        .fold<int>(0, (s, v) => s + v.valorCentavos);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: dourado),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A DESCONTAR DAS COMISSÕES',
            style: TextStyle(
              color: dourado,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            Dinheiro.formatar(aDescontar),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          if (emAnalise > 0)
            Text(
              'Em análise ou aguardando pagamento: '
              '${Dinheiro.formatar(emAnalise)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _item(Vale v) {
    final cor = _corStatus(v.status);

    final detalhes = <String>[
      if (_admin) v.barbeiroNome,
      'Pedido em ${formatarDataHora(v.criadoEm?.toDate())}',
    ];

    final acoes = <Widget>[];

    if (_admin) {
      if (v.status == 'pendente') {
        acoes.addAll([
          Expanded(
            child: OutlinedButton(
              onPressed: () => _recusar(v),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text('RECUSAR'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _executar(
                () => _repo.decidir(v.id, true, widget.perfil),
                'Vale aprovado.',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: const Text('APROVAR'),
            ),
          ),
        ]);
      } else if (v.status == 'aprovado') {
        acoes.addAll([
          Expanded(
            child: OutlinedButton(
              onPressed: () => _confirmar(
                titulo: 'Cancelar vale',
                texto: 'Cancelar este vale aprovado? Ele continua no histórico.',
                botao: 'CANCELAR VALE',
                acao: () => _repo.cancelar(v.id, widget.perfil),
                sucesso: 'Vale cancelado.',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.redAccent,
                side: const BorderSide(color: Colors.redAccent),
              ),
              child: const Text('CANCELAR'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _pagar(v),
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
              ),
              child: const Text('PAGAR VALE'),
            ),
          ),
        ]);
      } else if (v.status == 'pago' && v.descontadoCentavos == 0) {
        acoes.add(
          Expanded(
            child: TextButton(
              onPressed: () => _confirmar(
                titulo: 'Estornar vale',
                texto: 'Estornar o pagamento deste vale? Ele fica como '
                    'cancelado no histórico e a despesa do caixa é cancelada.',
                botao: 'ESTORNAR',
                acao: () => _repo.estornarPagamento(v.id, widget.perfil),
                sucesso: 'Vale estornado.',
              ),
              child: const Text('ESTORNAR PAGAMENTO'),
            ),
          ),
        );
      }
    } else if (v.status == 'pendente') {
      acoes.add(
        Expanded(
          child: TextButton(
            onPressed: () => _confirmar(
              titulo: 'Cancelar pedido',
              texto: 'Cancelar este pedido de vale?',
              botao: 'CANCELAR PEDIDO',
              acao: () => _repo.cancelar(v.id, widget.perfil),
              sucesso: 'Pedido cancelado.',
            ),
            child: const Text('CANCELAR PEDIDO'),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  Dinheiro.formatar(v.valorCentavos),
                  style: const TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              Flexible(
                child: Text(
                  v.rotuloStatus,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            detalhes.join(' • '),
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          if (v.motivo.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Motivo: ${v.motivo}', style: const TextStyle(fontSize: 13)),
          ],
          if (v.status == 'recusado' && v.motivoRecusa.isNotEmpty)
            Text(
              'Recusado por ${v.decididoPorNome}: ${v.motivoRecusa}',
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          if (v.status == 'pago') ...[
            const SizedBox(height: 2),
            Text(
              'Pago em ${formatarDataHora(v.pagoEm?.toDate())} '
              '(${rotuloForma(v.forma)}) por ${v.pagoPorNome}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            Text(
              'Descontado: ${Dinheiro.formatar(v.descontadoCentavos)} • '
              'Saldo: ${Dinheiro.formatar(v.saldoCentavos)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
          if (acoes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: acoes),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_admin ? 'VALES' : 'MEUS VALES'),
      ),
      body: StreamBuilder<List<Vale>>(
        stream: _stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: dourado),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Erro ao carregar os vales:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final todos = snapshot.data ?? [];
          final lista = todos.where(_passaFiltro).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            children: [
              if (_admin)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final f in const [
                        ['pendente', 'PENDENTES'],
                        ['aprovado', 'A PAGAR'],
                        ['pago', 'PAGOS'],
                        ['todos', 'TODOS'],
                      ])
                        ChoiceChip(
                          label: Text(f[1]),
                          selected: _filtro == f[0],
                          selectedColor: dourado,
                          labelStyle: TextStyle(
                            color: _filtro == f[0] ? Colors.black : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          onSelected: (_) => setState(() => _filtro = f[0]),
                        ),
                    ],
                  ),
                )
              else
                _resumoBarbeiro(todos),
              if (lista.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 30),
                  child: Center(child: Text('Nenhum vale por aqui.')),
                ),
              for (final v in lista) _item(v),
            ],
          );
        },
      ),
      floatingActionButton: _admin
          ? null
          : FloatingActionButton.extended(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
              onPressed: _pedir,
              icon: const Icon(Icons.add),
              label: const Text('PEDIR VALE'),
            ),
    );
  }
}

class _PedidoVale {
  final int valorCentavos;
  final String motivo;

  const _PedidoVale(this.valorCentavos, this.motivo);
}

class _DialogPedirVale extends StatefulWidget {
  const _DialogPedirVale();

  @override
  State<_DialogPedirVale> createState() => _DialogPedirValeState();
}

class _DialogPedirValeState extends State<_DialogPedirVale> {
  final _valor = TextEditingController();
  final _motivo = TextEditingController();
  String? _erro;

  @override
  void dispose() {
    _valor.dispose();
    _motivo.dispose();
    super.dispose();
  }

  void _confirmar() {
    final centavos = Dinheiro.paraCentavos(_valor.text);

    if (centavos == null || centavos <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    if (_motivo.text.trim().isEmpty) {
      setState(() => _erro = 'Informe o motivo.');
      return;
    }

    Navigator.pop(context, _PedidoVale(centavos, _motivo.text.trim()));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Pedir vale', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _valor,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _motivo,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() => _erro = null),
              decoration: const InputDecoration(
                labelText: 'Motivo',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Depois de aprovado e pago, o valor é descontado das suas '
              'próximas comissões.',
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
          child: const Text('ENVIAR PEDIDO'),
        ),
      ],
    );
  }
}

class _DialogRecusarVale extends StatefulWidget {
  const _DialogRecusarVale();

  @override
  State<_DialogRecusarVale> createState() => _DialogRecusarValeState();
}

class _DialogRecusarValeState extends State<_DialogRecusarVale> {
  final _motivo = TextEditingController();

  @override
  void dispose() {
    _motivo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Recusar pedido', style: TextStyle(color: dourado)),
      content: TextField(
        controller: _motivo,
        maxLines: 2,
        decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('VOLTAR'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _motivo.text.trim()),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
          ),
          child: const Text('RECUSAR'),
        ),
      ],
    );
  }
}

class _DialogPagarVale extends StatefulWidget {
  final Vale vale;

  const _DialogPagarVale({required this.vale});

  @override
  State<_DialogPagarVale> createState() => _DialogPagarValeState();
}

class _DialogPagarValeState extends State<_DialogPagarVale> {
  String _forma = 'dinheiro';
  bool _confirmou = false;
  String? _erro;

  void _confirmar() {
    if (!_confirmou) {
      setState(() => _erro = 'Marque a confirmação do pagamento.');
      return;
    }
    Navigator.pop(context, _forma);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Pagar vale', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.vale.barbeiroNome}: '
              '${Dinheiro.formatar(widget.vale.valorCentavos)}',
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
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
                'Confirmo que o valor foi entregue ao funcionário.',
                style: TextStyle(fontSize: 14),
              ),
            ),
            const Text(
              'O pagamento será lançado no caixa como despesa.',
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
          child: const Text('PAGAR'),
        ),
      ],
    );
  }
}
