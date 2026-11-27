part of 'comanda_repository.dart';

extension ComandaRepositoryProdutos on ComandaRepository {
  void _validarEstoque(Produto p, int desejada) {
    if (!p.ativo) throw Exception('Este produto está desativado.');
    if (p.estoqueQtd <= 0) throw Exception('Produto sem estoque.');
    if (desejada > p.estoqueQtd) {
      throw Exception(
        'Estoque insuficiente: há apenas ${p.estoqueQtd} '
        'unidade(s) de ${p.nome}.',
      );
    }
  }

  /// O estoque NÃO é alterado aqui: a baixa acontece só no pagamento final.
  Future<void> adicionarProduto(String comandaId, Produto p) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _col.doc(comandaId);
      final produtoRef = _produtos.doc(p.id);

      final comandaSnap = await tx.get(comandaRef);
      final produtoSnap = await tx.get(produtoRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');
      if (!produtoSnap.exists) throw Exception('Produto não encontrado.');

      final c = Comanda.doDocumento(comandaSnap);
      final atual = Produto.doDocumento(produtoSnap);

      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final produtos = [...c.produtos];
      final indice = produtos.indexWhere((x) => x.produtoId == atual.id);
      final quantidadeAtual = indice >= 0 ? produtos[indice].quantidade : 0;

      _validarEstoque(atual, quantidadeAtual + 1);

      if (indice >= 0) {
        produtos[indice] =
            produtos[indice].comQuantidade(quantidadeAtual + 1);
      } else {
        produtos.add(
          ItemProduto(
            id: _col.doc().id,
            produtoId: atual.id,
            nome: atual.nome,
            precoCentavos: atual.precoVendaCentavos,
            quantidade: 1,
          ),
        );
      }

      tx.update(
        comandaRef,
        _camposAtualizados(
          c.servicos,
          produtos,
          c.descontoBp,
          c.pagoCentavos,
        ),
      );
    });
  }

  /// Aumentar a quantidade exige estoque suficiente; diminuir é sempre livre.
  Future<void> alterarQuantidadeProduto(
    String comandaId,
    String itemId,
    int quantidade,
  ) async {
    await _firestore.runTransaction((tx) async {
      final comandaRef = _col.doc(comandaId);
      final comandaSnap = await tx.get(comandaRef);

      if (!comandaSnap.exists) throw Exception('Comanda não encontrada.');

      final c = Comanda.doDocumento(comandaSnap);
      if (!c.aberta) throw Exception('Esta comanda não está mais aberta.');

      final indice = c.produtos.indexWhere((i) => i.id == itemId);
      if (indice < 0) throw Exception('Produto não encontrado na comanda.');

      final item = c.produtos[indice];

      if (quantidade > item.quantidade) {
        final produtoSnap = await tx.get(_produtos.doc(item.produtoId));
        if (!produtoSnap.exists) throw Exception('Produto não encontrado.');
        _validarEstoque(Produto.doDocumento(produtoSnap), quantidade);
      }

      final produtos = <ItemProduto>[];
      for (final i in c.produtos) {
        if (i.id != itemId) {
          produtos.add(i);
        } else if (quantidade >= 1) {
          produtos.add(i.comQuantidade(quantidade));
        }
      }

      tx.update(
        comandaRef,
        _camposAtualizados(
          c.servicos,
          produtos,
          c.descontoBp,
          c.pagoCentavos,
        ),
      );
    });
  }

  Future<void> removerProduto(String comandaId, String itemId) {
    return _alterar(
      comandaId,
      (c) => _camposAtualizados(
        c.servicos,
        c.produtos.where((i) => i.id != itemId).toList(),
        c.descontoBp,
        c.pagoCentavos,
      ),
    );
  }
}
