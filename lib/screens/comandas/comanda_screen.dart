import 'package:flutter/material.dart';
import '../../config/catalogo_inicial.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/perfil_usuario.dart';
import '../../models/produto.dart';
import '../../models/servico.dart';
import '../../repositories/comanda_repository.dart';
import '../../repositories/produto_repository.dart';
import '../../repositories/servico_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';

class ComandaScreen extends StatelessWidget {
  final String comandaId;
  final PerfilUsuario perfil;
  final ComandaRepository _repo = ComandaRepository();

  ComandaScreen({super.key, required this.comandaId, required this.perfil});

  Future<void> _executar(
    BuildContext context,
    Future<void> Function() acao,
  ) async {
    try {
      await acao();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  Future<void> _adicionarServico(BuildContext context, Comanda c) async {
    final servico = await showModalBottomSheet<Servico>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartao,
      builder: (_) => const _SeletorServico(),
    );

    if (servico == null || !context.mounted) return;
    await _executar(context, () => _repo.adicionarServico(c.id, servico));
  }

  Future<void> _adicionarProduto(BuildContext context, Comanda c) async {
    final produto = await showModalBottomSheet<Produto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartao,
      builder: (_) => const _SeletorProduto(),
    );

    if (produto == null || !context.mounted) return;
    await _executar(context, () => _repo.adicionarProduto(c.id, produto));
  }

  Future<void> _ajustarPreco(
    BuildContext context,
    Comanda c,
    ItemComanda item,
  ) async {
    final novo = await showDialog<int>(
      context: context,
      builder: (_) => _DialogPreco(item: item),
    );

    if (novo == null || !context.mounted) return;
    await _executar(context, () => _repo.ajustarPreco(c.id, item.id, novo));
  }

  Future<void> _cancelar(BuildContext context, Comanda c) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const _DialogCancelar(),
    );

    if (motivo == null || !context.mounted) return;

    try {
      await _repo.cancelar(c.id, perfil, motivo: motivo);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensagemDeErro(e))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Comanda?>(
      stream: _repo.observarUma(comandaId),
      builder: (context, snapshot) {
        final c = snapshot.data;

        if (c == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('COMANDA')),
            body: Center(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator(color: dourado)
                  : Text(
                      snapshot.hasError
                          ? 'Não foi possível carregar a comanda.'
                          : 'Comanda não encontrada.',
                    ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('COMANDA #${c.numero}'),
            actions: [
              if (c.aberta)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (_) => _cancelar(context, c),
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: 'cancelar',
                      child: Text('Cancelar comanda'),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _cabecalho(c),
                    const SizedBox(height: 22),
                    _titulo('SERVIÇOS'),
                    const SizedBox(height: 10),
                    if (c.servicos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum serviço adicionado.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    for (final item in c.servicos) _servicoCard(context, c, item),
                    if (c.aberta) ...[
                      const SizedBox(height: 6),
                      _botao(
                        'ADICIONAR SERVIÇO',
                        () => _adicionarServico(context, c),
                        destaque: true,
                      ),
                    ],
                    if (c.produtos.isNotEmpty || c.aberta) ...[
                      const SizedBox(height: 24),
                      _titulo('PRODUTOS'),
                      const SizedBox(height: 10),
                    ],
                    if (c.produtos.isEmpty && c.aberta)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'Opcional: adicione apenas se o cliente '
                          'comprar algum produto.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    for (final item in c.produtos) _produtoCard(context, c, item),
                    if (c.aberta) ...[
                      const SizedBox(height: 6),
                      _botao(
                        'ADICIONAR PRODUTO',
                        () => _adicionarProduto(context, c),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Desconto e pagamento serão ativados '
                        'nas próximas partes desta etapa.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              _barraTotal(c),
            ],
          ),
        );
      },
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto,
      style: const TextStyle(
        color: dourado,
        fontWeight: FontWeight.bold,
        letterSpacing: 2,
      ),
    );
  }

  Widget _botao(String texto, VoidCallback onPressed, {bool destaque = false}) {
    return SizedBox(
      height: 50,
      child: destaque
          ? ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: dourado,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                foregroundColor: dourado,
                side: const BorderSide(color: dourado),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add),
              label: Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _cabecalho(Comanda c) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cartao,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: bordaCartao),
      ),
      child: Column(
        children: [
          _linha(Icons.person_outline, 'Cliente', c.nomeCliente),
          const SizedBox(height: 8),
          _linha(Icons.content_cut, 'Barbeiro', c.barbeiroNome),
          const SizedBox(height: 8),
          _linha(Icons.schedule, 'Aberta em', formatarDataHora(c.criadoEm)),
          if (!c.aberta) ...[
            const SizedBox(height: 8),
            _linha(Icons.info_outline, 'Situação', c.rotuloStatus),
          ],
        ],
      ),
    );
  }

  Widget _linha(IconData icone, String rotulo, String valor) {
    return Row(
      children: [
        Icon(icone, color: dourado, size: 20),
        const SizedBox(width: 10),
        Text('$rotulo: ', style: const TextStyle(color: Colors.white54)),
        Expanded(
          child: Text(
            valor,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _servicoCard(BuildContext context, Comanda c, ItemComanda item) {
    final alterado = item.precoCentavos != item.precoCatalogoCentavos;

    return Card(
      color: cartao,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: bordaCartao),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        title: Text(
          item.nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: alterado
            ? Text(
                'Catálogo: ${Dinheiro.formatar(item.precoCatalogoCentavos)}',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              )
            : (item.aPartir
                ? const Text(
                    'A partir de',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  )
                : null),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              Dinheiro.formatar(item.precoCentavos),
              style: const TextStyle(
                color: dourado,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (c.aberta)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (opcao) {
                  if (opcao == 'preco') {
                    _ajustarPreco(context, c, item);
                  } else {
                    _executar(
                      context,
                      () => _repo.removerServico(c.id, item.id),
                    );
                  }
                },
                itemBuilder: (_) => [
                  if (item.aPartir)
                    const PopupMenuItem(
                      value: 'preco',
                      child: Text('Ajustar preço'),
                    ),
                  const PopupMenuItem(
                    value: 'remover',
                    child: Text('Remover serviço'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _produtoCard(BuildContext context, Comanda c, ItemProduto item) {
    return Card(
      color: cartao,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: const BorderSide(color: bordaCartao),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 12, 8, 6),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nome,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${Dinheiro.formatar(item.precoCentavos)} cada',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: Text(
                    Dinheiro.formatar(item.totalCentavos),
                    style: const TextStyle(
                      color: dourado,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            if (c.aberta)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: dourado,
                    onPressed: () => _executar(
                      context,
                      () => _repo.alterarQuantidadeProduto(
                        c.id,
                        item.id,
                        item.quantidade - 1,
                      ),
                    ),
                  ),
                  Text(
                    '${item.quantidade}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: dourado,
                    onPressed: () => _executar(
                      context,
                      () => _repo.alterarQuantidadeProduto(
                        c.id,
                        item.id,
                        item.quantidade + 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _executar(
                      context,
                      () => _repo.removerProduto(c.id, item.id),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Remover'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                    ),
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Quantidade: ${item.quantidade}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _barraTotal(Comanda c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: cartao,
        border: Border(top: BorderSide(color: bordaCartao)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.subtotalProdutosCentavos > 0) ...[
              _linhaValor('Serviços', c.subtotalServicosCentavos),
              const SizedBox(height: 2),
              _linhaValor('Produtos', c.subtotalProdutosCentavos),
              const SizedBox(height: 8),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  Dinheiro.formatar(c.totalCentavos),
                  style: const TextStyle(
                    color: dourado,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _linhaValor(String rotulo, int centavos) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          rotulo,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
        ),
        Text(
          Dinheiro.formatar(centavos),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}

class _SeletorServico extends StatelessWidget {
  const _SeletorServico();

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
                        trailing
