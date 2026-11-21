import 'package:flutter/material.dart';
import '../../config/catalogo_inicial.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/produto.dart';
import '../../models/servico.dart';
import '../../repositories/produto_repository.dart';
import '../../repositories/servico_repository.dart';
import '../../utils/dinheiro.dart';

class SeletorServico extends StatelessWidget {
  const SeletorServico({super.key});

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: altura,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ESCOLHA O SERVIÇO',
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Servico>>(
              stream: ServicoRepository().observar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar o catálogo.'),
                  );
                }

                final lista =
                    (snapshot.data ?? []).where((s) => s.ativo).toList();

                if (lista.isEmpty) {
                  return const Center(
                    child: Text('Nenhum serviço ativo no catálogo.'),
                  );
                }

                final categorias = <String>[
                  ...categoriasServicos,
                  ...lista
                      .map((s) => s.categoria)
                      .where((cat) => !categoriasServicos.contains(cat))
                      .toSet(),
                ];

                final widgets = <Widget>[];

                for (final cat in categorias) {
                  final itens = lista.where((s) => s.categoria == cat).toList();
                  if (itens.isEmpty) continue;

                  widgets.add(
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                      child: Text(
                        cat.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  );

                  for (final s in itens) {
                    widgets.add(
                      ListTile(
                        title: Text(s.nome),
                        subtitle: s.aPartir ? const Text('A partir de') : null,
                        trailing: Text(
                          Dinheiro.formatar(s.precoCentavos),
                          style: const TextStyle(
                            color: dourado,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () => Navigator.pop(context, s),
                      ),
                    );
                  }
                }

                return ListView(children: widgets);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SeletorProduto extends StatelessWidget {
  const SeletorProduto({super.key});

  @override
  Widget build(BuildContext context) {
    final altura = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: altura,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ESCOLHA O PRODUTO',
              style: TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Produto>>(
              stream: ProdutoRepository().observar(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: dourado),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Erro ao carregar os produtos.'),
                  );
                }

                final lista =
                    (snapshot.data ?? []).where((p) => p.ativo).toList();

                if (lista.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Nenhum produto ativo. O administrador pode '
                        'cadastrar em Estoque.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: lista.length,
                  itemBuilder: (context, i) {
                    final p = lista[i];
                    final semEstoque = p.estoqueQtd <= 0;

                    return ListTile(
                      enabled: !semEstoque,
                      title: Text(p.nome),
                      subtitle: Text(
                        semEstoque
                            ? 'Sem estoque'
                            : 'Estoque: ${p.estoqueQtd}',
                        style: TextStyle(
                          color: semEstoque ? Colors.redAccent : Colors.white54,
                        ),
                      ),
                      trailing: Text(
                        Dinheiro.formatar(p.precoVendaCentavos),
                        style: const TextStyle(
                          color: dourado,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: semEstoque ? null : () => Navigator.pop(context, p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class DialogPreco extends StatefulWidget {
  final ItemComanda item;

  const DialogPreco({super.key, required this.item});

  @override
  State<DialogPreco> createState() => _DialogPrecoState();
}

class _DialogPrecoState extends State<DialogPreco> {
  late final TextEditingController _valor;
  String? _erro;

  @override
  void initState() {
    super.initState();
    final c = widget.item.precoCentavos;
    _valor = TextEditingController(
      text: '${c ~/ 100},${(c % 100).toString().padLeft(2, '0')}',
    );
  }

  @override
  void dispose() {
    _valor.dispose();
    super.dispose();
  }

  void _confirmar() {
    final centavos = Dinheiro.paraCentavos(_valor.text);
    final minimo = widget.item.precoCatalogoCentavos;

    if (centavos == null || centavos <= 0) {
      setState(() => _erro = 'Informe um valor válido.');
      return;
    }
    if (centavos < minimo) {
      setState(() {
        _erro = 'O valor mínimo é ${Dinheiro.formatar(minimo)}. '
            'Reduções serão feitas pelo desconto da comanda.';
      });
      return;
    }

    Navigator.pop(context, centavos);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: cartao,
      title: Text(
        widget.item.nome,
        style: const TextStyle(color: dourado),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor cobrado (R\$)',
              prefixIcon: Icon(Icons.attach_money),
            ),
          ),
          if (_erro != null) ...[
            const SizedBox(height: 10),
            Text(_erro!, style: const TextStyle(color: Colors.redAccent)),
          ],
        ],
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
          child: const Text('SALVAR'),
        ),
      ],
    );
  }
}

class DialogCancelar extends StatefulWidget {
  const DialogCancelar({super.key});

  @override
  State<DialogCancelar> createState() => _DialogCancelarState();
}

class _DialogCancelarState extends State<DialogCancelar> {
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
      title: const Text('Cancelar comanda', style: TextStyle(color: dourado)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A comanda será cancelada e continuará registrada no histórico.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _motivo,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo (opcional)',
            ),
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
          child: const Text('CANCELAR COMANDA'),
        ),
      ],
    );
  }
}
