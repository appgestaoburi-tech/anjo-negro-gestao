import '../models/comanda.dart';
import '../models/comissao.dart';

/// Arredonda para cima a partir de meio centavo.
int _comissao(int baseCentavos, int bp) => (baseCentavos * bp + 5000) ~/ 10000;

class ResultadoComissao {
  final List<LinhaComissao> linhas;
  final int baseServicosCentavos;
  final int baseProdutosCentavos;
  final int totalCentavos;

  const ResultadoComissao({
    required this.linhas,
    required this.baseServicosCentavos,
    required this.baseProdutosCentavos,
    required this.totalCentavos,
  });
}

/// Serviços: base = preço menos a parte do desconto da comanda, dividido
/// proporcionalmente ao preço (o último serviço fica com o resto, para a
/// soma fechar certinho). Produtos: preço de venda x quantidade.
ResultadoComissao calcularComissao({
  required Comanda comanda,
  required int servicoPadraoBp,
  required Map<String, int> categoriasBp,
  required int? produtosBp,
}) {
  final linhas = <LinhaComissao>[];
  var baseServicos = 0;
  var baseProdutos = 0;
  var total = 0;

  final servicos = comanda.servicos;
  final subtotal = servicos.fold<int>(0, (s, i) => s + i.precoCentavos);
  final desconto = comanda.descontoCentavos;
  var restante = desconto;

  for (var i = 0; i < servicos.length; i++) {
    final item = servicos[i];

    var parte = 0;
    if (desconto > 0 && subtotal > 0) {
      parte = i == servicos.length - 1
          ? restante
          : (desconto * item.precoCentavos) ~/ subtotal;
      restante -= parte;
    }

    var base = item.precoCentavos - parte;
    if (base < 0) base = 0;

    final bp = categoriasBp[item.categoria] ?? servicoPadraoBp;
    final valor = _comissao(base, bp);

    linhas.add(
      LinhaComissao(
        tipo: 'servico',
        nome: item.nome,
        categoria: item.categoria,
        baseCentavos: base,
        bp: bp,
        comissaoCentavos: valor,
      ),
    );

    baseServicos += base;
    total += valor;
  }

  if (comanda.produtos.isNotEmpty && produtosBp == null) {
    throw Exception(
      'Defina a comissão de produtos do barbeiro em Funcionários '
      'antes de receber esta comanda.',
    );
  }

  for (final p in comanda.produtos) {
    final base = p.totalCentavos;
    final bp = produtosBp ?? 0;
    final valor = _comissao(base, bp);

    linhas.add(
      LinhaComissao(
        tipo: 'produto',
        nome: '${p.nome} (x${p.quantidade})',
        categoria: 'Produtos',
        baseCentavos: base,
        bp: bp,
        comissaoCentavos: valor,
      ),
    );

    baseProdutos += base;
    total += valor;
  }

  return ResultadoComissao(
    linhas: linhas,
    baseServicosCentavos: baseServicos,
    baseProdutosCentavos: baseProdutos,
    totalCentavos: total,
  );
}
