/// Divide [desconto] entre os itens, proporcional ao preço de cada um.
/// O último item com preço recebe o resto, para a soma fechar certinho.
List<int> ratearDesconto(List<int> precos, int desconto) {
  final partes = List<int>.filled(precos.length, 0);
  final subtotal = precos.fold<int>(0, (s, p) => s + p);

  if (desconto <= 0 || subtotal <= 0) return partes;

  var ultimo = -1;
  for (var i = 0; i < precos.length; i++) {
    if (precos[i] > 0) ultimo = i;
  }

  var restante = desconto;
  for (var i = 0; i < precos.length; i++) {
    if (precos[i] <= 0) continue;
    final parte = i == ultimo ? restante : (desconto * precos[i]) ~/ subtotal;
    partes[i] = parte;
    restante -= parte;
  }

  return partes;
}
