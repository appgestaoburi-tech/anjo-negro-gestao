import 'package:flutter/material.dart';
import '../../config/parametros.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/perfil_usuario.dart';
import '../../models/produto.dart';
import '../../models/servico.dart';
import '../../repositories/comanda_repository.dart';
import '../../utils/erros.dart';
import 'comanda_dialogos.dart';
import 'comanda_itens.dart';
import 'comanda_widgets.dart';
import 'dialogo_desconto.dart';
import 'secao_desconto_comanda.dart';
import 'secao_pacotes_comanda.dart';
import 'secao_pagamento.dart';

class ComandaScreen extends StatelessWidget {
  final String comandaId;
  final PerfilUsuario perfil;
  final ComandaRepository _repo = ComandaRepository();

  ComandaScreen({super.key, required this.comandaId, required this.perfil});

  void _aviso(BuildContext context, String texto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto)),
    );
  }

  Future<void> _executar(
    BuildContext context,
    Future<void> Function() acao,
  ) async {
    try {
      await acao();
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
    }
  }

  Future<void> _adicionarServico(BuildContext context, Comanda c) async {
    final servico = await showModalBottomSheet<Servico>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartao,
      builder: (_) => const SeletorServico(),
    );

    if (servico == null || !context.mounted) return;
    await _executar(context, () => _repo.adicionarServico(c.id, servico));
  }

  Future<void> _adicionarProduto(BuildContext context, Comanda c) async {
    final produto = await showModalBottomSheet<Produto>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cartao,
      builder: (_) => const SeletorProduto(),
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
      builder: (_) => DialogPreco(item: item),
    );

    if (novo == null || !context.mounted) return;
    await _executar(context, () => _repo.ajustarPreco(c.id, item.id, novo));
  }

  Future<void> _desconto(BuildContext context, Comanda c) async {
    final livre = perfil.permissaoTotal
        ? 10000
        : (c.descontoAprovadoBp > limiteDescontoSemAutorizacaoBp
            ? c.descontoAprovadoBp
            : limiteDescontoSemAutorizacaoBp);

    final bp = await showDialog<int>(
      context: context,
      builder: (_) => DialogDesconto(
        atualBp: c.descontoBp,
        subtotalServicosCentavos: c.subtotalServicosCentavos,
        limiteLivreBp: livre,
      ),
    );

    if (bp == null || !context.mounted) return;

    if (bp <= livre) {
      await _executar(context, () => _repo.aplicarDesconto(c.id, bp, perfil));
      return;
    }

    try {
      await _repo.solicitarDesconto(c.id, bp, perfil);
      if (!context.mounted) return;
      _aviso(context, 'Pedido enviado ao administrador.');
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
    }
  }

  Future<void> _cancelar(BuildContext context, Comanda c) async {
    final motivo = await showDialog<String>(
      context: context,
      builder: (_) => const DialogCancelar(),
    );

    if (motivo == null || !context.mounted) return;

    try {
      await _repo.cancelar(c.id, perfil, motivo: motivo);
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      _aviso(context, mensagemDeErro(e));
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
                    CabecalhoComanda(comanda: c),
                    const SizedBox(height: 22),
                    const TituloSecao('SERVIÇOS'),
                    const SizedBox(height: 10),
                    if (c.servicos.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Nenhum serviço adicionado.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    for (final item in c.servicos)
                      CartaoServicoComanda(
                        comanda: c,
                        item: item,
                        onAjustarPreco: () => _ajustarPreco(context, c, item),
                        onRemover: () => _executar(
                          context,
                          () => _repo.removerServico(c.id, item.id),
                        ),
                      ),
                    if (c.aberta) ...[
                      const SizedBox(height: 6),
                      BotaoComanda(
                        texto: 'ADICIONAR SERVIÇO',
                        onPressed: () => _adicionarServico(context, c),
                        destaque: true,
                      ),
                    ],
                    if (c.servicos.isNotEmpty || c.descontoBp > 0) ...[
                      const SizedBox(height: 24),
                      const TituloSecao('DESCONTO'),
                      const SizedBox(height: 10),
                      SecaoDescontoComanda(
                        comanda: c,
                        admin: perfil.permissaoTotal,
                        onAlterar: () => _desconto(context, c),
                        onDecidir: (aprovar) => _executar(
                          context,
                          () => _repo.decidirDesconto(c.id, aprovar, perfil),
                        ),
                        onCancelarPedido: () => _executar(
                          context,
                          () => _repo.cancelarSolicitacao(c.id),
                        ),
                      ),
                    ],
                    if (c.produtos.isNotEmpty || c.aberta) ...[
                      const SizedBox(height: 24),
                      const TituloSecao('PRODUTOS'),
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
                    for (final item in c.produtos)
                      CartaoProdutoComanda(
                        comanda: c,
                        item: item,
                        onQuantidade: (q) => _executar(
                          context,
                          () => _repo.alterarQuantidadeProduto(
                            c.id,
                            item.id,
                            q,
                          ),
                        ),
                        onRemover: () => _executar(
                          context,
                          () => _repo.removerProduto(c.id, item.id),
                        ),
                      ),
                    if (c.aberta) ...[
                      const SizedBox(height: 6),
                      BotaoComanda(
                        texto: 'ADICIONAR PRODUTO',
                        onPressed: () => _adicionarProduto(context, c),
                      ),
                    ],
                    SecaoPacotesComanda(comanda: c, perfil: perfil),
                    SecaoPagamento(
                      key: ValueKey('pag-${c.id}'),
                      comanda: c,
                      perfil: perfil,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              BarraTotalComanda(comanda: c),
            ],
          ),
        );
      },
    );
  }
}
