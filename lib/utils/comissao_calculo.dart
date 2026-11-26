import '../models/comanda.dart';
import '../models/comissao.dart';
import 'rateio.dart';

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
/// proporcionalmente ao preço (o último com preço fica com o resto).
/// Venda de pacote não gera comissão. Uso de pacote: base = valor do uso.
/// Produtos: preço de venda x quantidade.
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
  final partes = ratearDesconto(
    servicos.map((s) => s.precoCentavos).toList(),
    comanda.descontoCentavos,
  );

  for (var i = 0; i < servicos.length; i++) {
    final item = servicos[i];

    if (item.ehPacote) continue;

    int base;
    String nome;

    if (item.ehUso) {
      base = item.valorUsoCentavos;
      nome = 'Pacote: ${item.nome}';
    } else {
      base = item.precoCentavos - partes[i];
      if (base < 0) base = 0;
      nome = item.nome;
    }

    final bp = categoriasBp[item.categoria] ?? servicoPadraoBp;
    final valor = _comissao(base, bp);

    linhas.add(
      LinhaComissao(
        tipo: 'servico',
        nome: nome,
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
