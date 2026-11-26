import 'package:flutter/material.dart';
import '../../config/tema.dart';
import '../../models/comanda.dart';
import '../../utils/dinheiro.dart';

class CartaoServicoComanda extends StatelessWidget {
  final Comanda comanda;
  final ItemComanda item;
  final VoidCallback onAjustarPreco;
  final VoidCallback onRemover;

  const CartaoServicoComanda({
    super.key,
    required this.comanda,
    required this.item,
    required this.onAjustarPreco,
    required this.onRemover,
  });

  Widget? _subtitulo() {
    const estilo = TextStyle(color: Colors.white54, fontSize: 12);

    if (item.ehPacote) {
      return const Text('Pacote • sem comissão na venda', style: estilo);
    }
    if (item.precoCentavos != item.precoCatalogoCentavos) {
      return Text(
        'Catálogo: ${Dinheiro.formatar(item.precoCatalogoCentavos)}',
        style: estilo,
      );
    }
    if (item.aPartir) {
      return const Text('A partir de', style: estilo);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
        subtitle: _subtitulo(),
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
            if (comanda.aberta)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white70),
                onSelected: (opcao) {
                  if (opcao == 'preco') {
                    onAjustarPreco();
                  } else {
                    onRemover();
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
}

class CartaoProdutoComanda extends StatelessWidget {
  final Comanda comanda;
  final ItemProduto item;
  final void Function(int quantidade) onQuantidade;
  final VoidCallback onRemover;

  const CartaoProdutoComanda({
    super.key,
    required this.comanda,
    required this.item,
    required this.onQuantidade,
    required this.onRemover,
  });

  @override
  Widget build(BuildContext context) {
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
            if (comanda.aberta)
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    color: dourado,
                    onPressed: () => onQuantidade(item.quantidade - 1),
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
                    onPressed: () => onQuantidade(item.quantidade + 1),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: onRemover,
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
}
