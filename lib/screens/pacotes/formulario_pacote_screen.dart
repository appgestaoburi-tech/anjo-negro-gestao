import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/pacote.dart';
import '../../repositories/pacote_repository.dart';
import '../../repositories/servico_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class _ItemEditavel {
  String? servicoId;
  final TextEditingController qtd;
  final TextEditingController max;

  _ItemEditavel({this.servicoId, String qtdTexto = '', String maxTexto = ''})
      : qtd = TextEditingController(text: qtdTexto),
        max = TextEditingController(text: maxTexto);

  void dispose() {
    qtd.dispose();
    max.dispose();
  }
}

class FormularioPacoteScreen extends StatefulWidget {
  final PacoteRepository repo;
  final Pacote? pacote;

  const FormularioPacoteScreen({super.key, required this.repo, this.pacote});

  @override
  State<FormularioPacoteScreen> createState() =>
      _FormularioPacoteScreenState();
}

class _FormularioPacoteScreenState extends State<FormularioPacoteScreen> {
  final _nome = TextEditingController();
  final _preco = TextEditingController();
  final List<_ItemEditavel> _itens = [];
  final Map<String, String> _nomes = {};

  int _meses = 1;
  bool _ativo = false;
  bool _carregando = true;
  bool _salvando = false;
  String? _erro;

  bool get _novo => widget.pacote == null;

  @override
  void initState() {
    super.initState();

    final p = widget.pacote;
    if (p != null) {
      _nome.text = p.nome;
      _meses = const [1, 3, 6, 12].contains(p.meses) ? p.meses : 1;
      _ativo = p.ativo;
      if (p.precoCentavos > 0) {
        _preco.text =
            '${p.precoCentavos ~/ 100},${(p.precoCentavos % 100).toString().padLeft(2, '0')}';
      }
      for (final i in p.itens) {
        _itens.add(
          _ItemEditavel(
            servicoId: i.servicoId,
            qtdTexto: '${i.qtdTotal}',
            maxTexto: '${i.maxPorMes}',
          ),
        );
      }
    }

    _carregarServicos();
  }

  @override
  void dispose() {
    _nome.dispose();
    _preco.dispose();
    for (final i in _itens) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _carregarServicos() async {
    try {
      final lista = await ServicoRepository().observar().first;
      for (final s in lista.where((s) => s.ativo)) {
        _nomes[s.id] = s.nome;
      }
    } catch (_) {
      // Segue só com os serviços que já estavam no pacote.
    }

    for (final i in widget.pacote?.itens ?? <ItemPacote>[]) {
      _nomes.putIfAbsent(i.servicoId, () => i.servicoNome);
    }

    if (!mounted) return;
    setState(() => _carregando = false);
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final precoTexto = _preco.text.trim();
    final preco = precoTexto.isEmpty ? 0 : Dinheiro.paraCentavos(precoTexto);

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do pacote.');
      return;
    }
    if (preco == null) {
      setState(() => _erro = 'Preço inválido.');
      return;
    }
    if (_ativo && preco <= 0) {
      setState(() => _erro = 'Defina o preço antes de ativar o pacote.');
      return;
    }
    if (_itens.isEmpty) {
      setState(() => _erro = 'Adicione pelo menos um serviço ao pacote.');
      return;
    }

    final itens = <ItemPacote>[];
    final usados = <String>{};

    for (final it in _itens) {
      final id = it.servicoId;

      if (id == null) {
        setState(() => _erro = 'Escolha o serviço de cada item.');
        return;
      }
      if (!usados.add(id)) {
        setState(() => _erro = 'O mesmo serviço aparece mais de uma vez.');
        return;
      }

      final q = int.tryParse(it.qtd.text.trim());
      final m = int.tryParse(it.max.text.trim());

      if (q == null || q < 1) {
        setState(() => _erro = 'A quantidade total precisa ser 1 ou mais.');
        return;
      }
      if (m == null || m < 1 || m > q) {
        setState(() {
          _erro = 'O máximo por mês precisa estar entre 1 e a quantidade total.';
        });
        return;
      }
      if (m * _meses < q) {
        setState(() {
          _erro = 'Com $m por mês em $_meses mês(es) só dá para usar '
              '${m * _meses} de $q. Aumente o máximo por mês.';
        });
        return;
      }

      itens.add(
        ItemPacote(
          servicoId: id,
          servicoNome: _nomes[id] ?? '',
          qtdTotal: q,
          maxPorMes: m,
        ),
      );
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      await widget.repo.salvar(
        id: widget.pacote?.id,
        nome: nome,
        meses: _meses,
        itens: itens,
        precoCentavos: preco,
        ativo: _ativo,
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

  Widget _secao(String texto) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        texto,
        style: const TextStyle(
          color: dourado,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _cartaoItem(int indice) {
    final it = _itens[indice];

    final opcoes = _nomes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: it.servicoId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Serviço'),
            items: [
              for (final e in opcoes)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() {
              it.servicoId = v;
              _erro = null;
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: it.qtd,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: const InputDecoration(
                    labelText: 'Total de usos',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: it.max,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: const InputDecoration(
                    labelText: 'Máximo por mês',
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _itens.removeAt(indice).dispose();
              }),
              icon: const Icon(Icons.delete_outline, size: 18),
              label: const Text('Remover item'),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_novo ? 'NOVO PACOTE' : 'EDITAR PACOTE'),
      ),
      body: _carregando
          ? const Center(child: CircularProgressIndicator(color: dourado))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nome,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: const InputDecoration(
                    labelText: 'Nome do pacote',
                    prefixIcon: Icon(Icons.card_membership),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _meses,
                  decoration: const InputDecoration(
                    labelText: 'Duração',
                    prefixIcon: Icon(Icons.event_repeat),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('Mensal (1 mês)')),
                    DropdownMenuItem(
                      value: 3,
                      child: Text('Trimestral (3 meses)'),
                    ),
                    DropdownMenuItem(
                      value: 6,
                      child: Text('Semestral (6 meses)'),
                    ),
                    DropdownMenuItem(value: 12, child: Text('Anual (12 meses)')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _meses = v;
                        _erro = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _preco,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) => setState(() => _erro = null),
                  decoration: const InputDecoration(
                    labelText: 'Preço do pacote (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                ),
                _secao('SERVIÇOS INCLUÍDOS'),
                const Text(
                  'Cada serviço tem o seu próprio contador de usos.',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 12),
                for (var i = 0; i < _itens.length; i++) _cartaoItem(i),
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _itens.add(_ItemEditavel());
                    _erro = null;
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: dourado,
                    side: const BorderSide(color: dourado),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('ADICIONAR SERVIÇO'),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: dourado,
                  title: const Text('Pacote ativo para venda'),
                  subtitle: const Text(
                    'Só pode ser ativado com o preço definido.',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _ativo,
                  onChanged: (v) => setState(() {
                    _ativo = v;
                    _erro = null;
                  }),
                ),
                if (_erro != null) ...[
                  const SizedBox(height: 8),
                  Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
                ],
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _salvando ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dourado,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _salvando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Text(
                            'SALVAR',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
    );
  }
}
