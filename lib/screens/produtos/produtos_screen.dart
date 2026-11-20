import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/produto.dart';
import '../../repositories/produto_repository.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key});

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  final _repo = ProdutoRepository();
  late final Stream<List<Produto>> _stream = _repo.observar();

  Future<void> _abrirFormulario({Produto? produto}) async {
    final salvou = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FormularioProduto(repo: _repo, produto: produto),
    );

    if (salvou == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produto salvo com sucesso!')),
      );
    }
  }

  Future<void> _alterarAtivo(Produto p) async {
    try {
      await _repo.definirAtivo(p.id, !p.ativo);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PRODUTOS E ESTOQUE')),
      body: StreamBuilder<List<Produto>>(
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
                  'Erro ao carregar os produtos:\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            );
          }

          final lista = snapshot.data ?? [];

          if (lista.isEmpty) {
            return const Center(child: Text('Nenhum produto cadastrado.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: lista.length,
            itemBuilder: (context, i) {
              final p = lista[i];

              return Opacity(
                opacity: p.ativo ? 1 : 0.5,
                child: Card(
                  color: cartao,
                  margin: const EdgeInsets.only(bottom: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                    side: const BorderSide(color: bordaCartao),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 6,
                    ),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF302719),
                      child: Icon(Icons.inventory_2_outlined, color: dourado),
                    ),
                    title: Text(
                      p.nome,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Estoque: ${p.estoqueQtd}'
                      '${p.categoria.isEmpty ? '' : ' • ${p.categoria}'}'
                      '${p.ativo ? '' : ' • desativado'}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Dinheiro.formatar(p.precoVendaCentavos),
                          style: const TextStyle(
                            color: dourado,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white70,
                          ),
                          onSelected: (opcao) {
                            if (opcao == 'editar') {
                              _abrirFormulario(produto: p);
                            } else {
                              _alterarAtivo(p);
                            }
                          },
                          itemBuilder: (_) => [
                            const PopupMenuItem(
                              value: 'editar',
                              child: Text('Editar produto'),
                            ),
                            PopupMenuItem(
                              value: 'ativo',
                              child: Text(
                                p.ativo ? 'Desativar produto' : 'Reativar produto',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: dourado,
        foregroundColor: Colors.black,
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('NOVO PRODUTO'),
      ),
    );
  }
}

class _FormularioProduto extends StatefulWidget {
  final ProdutoRepository repo;
  final Produto? produto;

  const _FormularioProduto({required this.repo, this.produto});

  @override
  State<_FormularioProduto> createState() => _FormularioProdutoState();
}

class _FormularioProdutoState extends State<_FormularioProduto> {
  final _nome = TextEditingController();
  final _categoria = TextEditingController();
  final _preco = TextEditingController();
  final _estoque = TextEditingController();

  bool _salvando = false;
  String? _erro;

  bool get _novo => widget.produto == null;

  @override
  void initState() {
    super.initState();
    final p = widget.produto;
    if (p != null) {
      _nome.text = p.nome;
      _categoria.text = p.categoria;
      final c = p.precoVendaCentavos;
      _preco.text = '${c ~/ 100},${(c % 100).toString().padLeft(2, '0')}';
    }
  }

  @override
  void dispose() {
    _nome.dispose();
    _categoria.dispose();
    _preco.dispose();
    _estoque.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final nome = _nome.text.trim();
    final centavos = Dinheiro.paraCentavos(_preco.text);

    if (nome.isEmpty) {
      setState(() => _erro = 'Informe o nome do produto.');
      return;
    }
    if (centavos == null || centavos <= 0) {
      setState(() => _erro = 'Informe um preço de venda válido.');
      return;
    }

    var estoqueInicial = 0;
    if (_novo && _estoque.text.trim().isNotEmpty) {
      final n = int.tryParse(_estoque.text.trim());
      if (n == null || n < 0) {
        setState(() => _erro = 'Estoque inicial inválido.');
        return;
      }
      estoqueInicial = n;
    }

    setState(() {
      _salvando = true;
      _erro = null;
    });

    try {
      if (_novo) {
        await widget.repo.criar(
          nome: nome,
          categoria: _categoria.text.trim(),
          precoVendaCentavos: centavos,
          estoqueInicial: estoqueInicial,
        );
      } else {
        await widget.repo.atualizar(
          widget.produto!.id,
          nome: nome,
          categoria: _categoria.text.trim(),
          precoVendaCentavos: centavos,
        );
      }
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
      title: Text(
        _novo ? 'Novo produto' : 'Editar produto',
        style: const TextStyle(color: dourado),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nome,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Nome do produto',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _categoria,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Categoria (opcional)',
                prefixIcon: Icon(Icons.category_outlined),
              ),
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _preco,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Preço de venda (R\$)',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            if (_novo) ...[
              const SizedBox(height: 13),
              TextField(
                controller: _estoque,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Estoque inicial (opcional)',
                  helperText: 'Quantidade que você já tem hoje',
                  prefixIcon: Icon(Icons.numbers),
                ),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Text(
                'A quantidade em estoque muda por entradas e saídas '
                'registradas (disponível na Etapa 5).',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
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
