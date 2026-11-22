import 'package:flutter/material.dart';
import '../../config/categorias_despesa.dart';
import '../../config/formas_pagamento.dart';
import '../../config/tema.dart';
import '../../models/despesa.dart';
import '../../models/perfil_usuario.dart';
import '../../repositories/despesa_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class DespesasScreen extends StatefulWidget {
  final PerfilUsuario perfil;
  final String ini;
  final String fim;

  const DespesasScreen({
    super.key,
    required this.perfil,
    required this.ini,
    required this.fim,
  });

  @override
  State<DespesasScreen> createState() => _DespesasScreenState();
}

class _DespesasScreenState extends State<DespesasScreen> {
  final _repo = DespesaRepository();
  late final Stream<List<Despesa>> _stream =
      _repo.observarPeriodo(widget.ini, widget.fim);

  void _aviso(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _nova() async {
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioDespesa(repo: _repo, perfil: widget.perfil),
    );

    if (salvou == true) _aviso('Despesa registrada.');
  }

  Future<void> _cancelar(Despesa d) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogCancelarDespesa(),
    );

    if (motivo == null || !mounted) return;

    try {
      await _repo.cancelar(d.id, widget.perfil, motivo: motivo);
      _aviso('Despesa cancelada.');
    } catch (e) {
      _aviso(mensagemDeErro(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodo = widget.ini == widget.fim
        ? formatarDiaIso(widget.ini)
        : '${formatarDiaIso(widget.ini)} a ${formatarDiaIso(widget.fim)}';

    return Scaffold(
      appBar: AppBar(title: const Text('DESPESAS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Período: $periodo',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Despesa>>(
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
                        'Erro ao carregar as despesas:\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final lista = snapshot.data ?? [];

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhuma despesa no período.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                  itemCount: lista.length,
                  itemBuilder: (context, i) => _item(lista[i]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.perfil.pode('lancar_despesas')
          ? FloatingActionButton.extended(
              backgroundColor: dourado,
              foregroundColor: Colors.black,
              onPressed: _nova,
              icon: const Icon(Icons.add),
              label: const Text('NOVA DESPESA'),
            )
          : null,
    );
  }

  Widget _item(Despesa d) {
    final detalhes = <String>[
      formatarDiaIso(d.dia),
      d.categoria,
      rotuloForma(d.forma),
      'por ${d.registradoPorNome}',
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
            Icons.south_west,
            color: d.cancelada ? Colors.white38 : Colors.orangeAccent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.descricao,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: d.cancelada ? Colors.white38 : Colors.white,
                    decoration:
                        d.cancelada ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detalhes.join(' • '),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                if (d.observacoes.isNotEmpty)
                  Text(
                    d.observacoes,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                if (d.cancelada)
                  Text(
                    'CANCELADA por ${d.canceladaPorNome}'
                    '${d.motivoCancelamento.isEmpty ? '' : ' (${d.motivoCancelamento})'}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            Dinheiro.formatar(d.valorCentavos),
            style: TextStyle(
              color: d.cancelada ? Colors.white38 : Colors.orangeAccent,
              fontWeight: FontWeight.bold,
              decoration: d.cancelada ? TextDecoration.lineThrough : null,
            ),
          ),
          if (widget.perfil.permissaoTotal && !d.cancelada)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white70),
              onSelected: (_) => _cancelar(d),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'cancelar', child: Text('Cancelar despesa')),
              ],
            )
          else
            const SizedBox(width: 10),
        ],
      ),
    );
  }
}

class _DialogCancelarDespesa extends StatefulWidget {
  const _DialogCancelarDespesa();

  @override
  State<_DialogCancelarDespesa> createState() => _DialogCancelarDespesaState();
}

class _DialogCancelarDespesaState extends State<_DialogCancelarDespesa> {
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
      title: const Text('Cancelar despesa', style: TextStyle(color: dourado)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A despesa continua no histórico, marcada como cancelada, e '
            'deixa de entrar nos totais do caixa.',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
          ),
        ],
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
          child: const Text('CANCELAR DESPESA'),
        ),
      ],
    );
  }
}

class _FormularioDespesa extends StatefulWidget {
  final DespesaRepository repo;
  final PerfilUsuario perfil;

  const _FormularioDespesa({required this.repo, required this.perfil});

  @override
  State<_FormularioDespesa> createState() => _FormularioDespesaState();
}

class _FormularioDespesaState extends State<_FormularioDespesa> {
  final _descricao = TextEditingController();
  final _valor = TextEditingController();
  final _data = TextEditingController();
  final _observacoes = TextEditingController();

  String _categoria = categoriasDespesa.first;
  String _forma = 'dinheiro';
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _data.text = formatarDia(DateTime.now());
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _data.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final descricao = _descricao.text.trim();
    final centavos = Dinheiro.paraCentavos(_valor.text);
    final dia = dataParaIso(_data.text);

    if (descricao.isEmpty) {
      setState(() => _erro = 'Informe a descrição.');
      return;
    }
    if (centavos == null || centavos <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    if (dia == null) {
      setState(() {
        _erro = 'Data inválida. Use dd/mm/aaaa (não pode ser futura).';
      });
      return;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await widget.repo.criar(
        descricao: descricao,
        categoria: _categoria,
        valorCentavos: centavos,
        dia: dia,
        forma: _forma,
        observacoes: _observacoes.text.trim(),
        perfil: widget.perfil,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _salvando = false;
        _erro = mensagemDeErro(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: const Text('Nova despesa', style: TextStyle(color: dourado)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _descricao,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Descrição',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: _categoria,
              decoration: const InputDecoration(labelText: 'Categoria'),
              items: [
                for (final c in categoriasDespesa)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _categoria = v);
              },
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _valor,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Valor (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _data,
              keyboardType: TextInputType.datetime,
              decoration: const InputDecoration(
                labelText: 'Data',
                helperText: 'dd/mm/aaaa',
                prefixIcon: Icon(Icons.event_outlined),
              ),
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              value: _forma,
              decoration: const InputDecoration(
                labelText: 'Forma de pagamento',
              ),
              items: [
                for (final f in formasPagamento)
                  DropdownMenuItem(value: f.chave, child: Text(f.rotulo)),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _forma = v);
              },
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _observacoes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observações (opcional)',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            if (_erro != null) ...[
              const SizedBox(height: 10),
              Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _salvando ? null : () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        ElevatedButton(
          onPressed: _salvando ? null : _salvar,
          style: ElevatedButton.styleFrom(
            backgroundColor: dourado,
            foregroundColor: Colors.black,
          ),
          child: _salvando
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.black,
                  ),
                )
              : const Text('SALVAR'),
        ),
      ],
    );
  }
}
