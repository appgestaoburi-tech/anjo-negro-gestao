import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/comanda.dart';
import 'dinheiro.dart';

/// Recalcula subtotais, desconto (só sobre serviços), total e os campos de
/// uso de pacote. O total nunca pode ficar abaixo do que já foi pago.
Map<String, dynamic> camposTotais(
  List<ItemComanda> servicos,
  List<ItemProduto> produtos,
  int descontoBp,
  int pagoCentavos,
) {
  final subServicos = servicos.fold<int>(0, (s, i) => s + i.precoCentavos);
  final subProdutos = produtos.fold<int>(0, (s, i) => s + i.totalCentavos);
  final desconto = (subServicos * descontoBp + 5000) ~/ 10000;
  final total = subServicos + subProdutos - desconto;

  if (total < pagoCentavos) {
    throw Exception(
      'O total da comanda não pode ficar menor que o valor já pago '
      '(${Dinheiro.formatar(pagoCentavos)}). Peça ao administrador para '
      'estornar o pagamento.',
    );
  }

  final usos = servicos.where((i) => i.ehUso).toList();
  final valorUsos = usos.fold<int>(0, (s, i) => s + i.valorUsoCentavos);

  return {
    'servicos': servicos.map((i) => i.paraMapa()).toList(),
    'produtos': produtos.map((i) => i.paraMapa()).toList(),
    'subtotalServicosCentavos': subServicos,
    'subtotalProdutosCentavos': subProdutos,
    'descontoBp': descontoBp,
    'descontoCentavos': desconto,
    'totalCentavos': total,
    'valorUsosCentavos': valorUsos,
    'coberta': total == 0 && usos.isNotEmpty,
    'atualizadoEm': FieldValue.serverTimestamp(),
  };
}
