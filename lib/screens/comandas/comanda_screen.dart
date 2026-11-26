import 'package:flutter/material.dart';
import '../../config/parametros.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../models/perfil_usuario.dart';
import '../../models/produto.dart';
import '../../models/servico.dart';
import '../../repositories/comanda_repository.dart';
import '../../utils/datas.dart';
import '../../utils/dinheiro.dart';
import '../../utils/erros.dart';
import '../../utils/percentual.dart';
import 'comanda_dialogos.dart';
import 'dialogo_desconto.dart';
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
                    if (c.servicos.isNotEmpty || c.descontoBp > 0) ...[
                      const SizedBox(height: 24),
                      _titulo('DESCONTO'),
                      const SizedBox(height: 10),
                      _secaoDesconto(context, c),
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

  Widget _botao(
    String texto,
    VoidCallback onPressed, {
    bool destaque = false,
    IconData icone = Icons.add,
  }) {
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
              icon: Icon(icone),
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
              icon: Icon(icone),
              label: Text(
                texto,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _secaoDesconto(BuildContext context, Comanda c) {
    final admin = perfil.permissaoTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cartao,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: bordaCartao),
          ),
          child: c.descontoBp > 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${bpParaTexto(c.descontoBp)} de desconto '
                      '(− ${Dinheiro.formatar(c.descontoCentavos)})',
                      style: const TextStyle(
                        color: dourado,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Sobre os serviços: '
                      '${Dinheiro.formatar(c.subtotalServicosCentavos)}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    if (c.descontoAprovadoBp > limiteDescontoSemAutorizacaoBp &&
                        c.descontoDecididoPorNome.isNotEmpty)
                      Text(
                        'Autorizado por ${c.descontoDecididoPorNome}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                  ],
                )
              : const Text(
                  'Sem desconto.',
                  style: TextStyle(color: Colors.white54),
                ),
        ),
        if (c.descontoPendente) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cartao,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.orangeAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin
                      ? '${c.descontoSolicitadoPorNome} pede '
                          '${bpParaTexto(c.descontoSolicitadoBp)} de desconto.'
                      : 'Aguardando autorização do administrador: '
                          '${bpParaTexto(c.descontoSolicitadoBp)}.',
                  style: const TextStyle(
                    color: Colors.orangeAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (admin)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _executar(
                            context,
                            () => _repo.decidirDesconto(c.id, false, perfil),
                          ),
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
                            context,
                            () => _repo.decidirDesconto(c.id, true, perfil),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: dourado,
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('APROVAR'),
                        ),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: () => _executar(
                      context,
                      () => _repo.cancelarSolicitacao(c.id),
                    ),
                    child: const Text('CANCELAR PEDIDO'),
                  ),
              ],
            ),
          ),
        ],
        if (c.descontoRecusado) ...[
          const SizedBox(height: 10),
          Text(
            'Pedido de ${bpParaTexto(c.descontoSolicitadoBp)} recusado'
            '${c.descontoDecididoPorNome.isEmpty ? '' : ' por ${c.descontoDecididoPorNome}'}.',
            style: const TextStyle(color: Colors.redAccent, fontSize: 13),
          ),
        ],
        if (c.aberta && !c.descontoPendente && c.servicos.isNotEmpty) ...[
          const SizedBox(height: 10),
          _botao(
            c.descontoBp > 0 ? 'ALTERAR DESCONTO' : 'APLICAR DESCONTO',
            () => _desconto(context, c),
            icone: Icons.percent,
          ),
        ],
      ],
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
        subtitle: item.ehPacote
            ? const Text(
                'Pacote • sem comissão na venda',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              )
            : (alterado
                ? Text(
                    'Catálogo: ${Dinheiro.formatar(item.precoCatalogoCentavos)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  )
                : (item.aPartir
                    ? const Text(
                        'A partir de',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      )
                    : null)),
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
                  PopupMenuItem(
                    value: 'remover',
                    child: Text(
                      item.ehPacote ? 'Remover pacote' : 'Remover serviço',
                    ),
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

                  
