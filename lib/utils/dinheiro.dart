class Dinheiro {
  /// 4500 -> "R$ 45,00"
  static String formatar(int centavos) {
    final negativo = centavos < 0;
    final valor = centavos.abs();
    final reais = (valor ~/ 100).toString().replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (_) => '.',
        );
    final cents = (valor % 100).toString().padLeft(2, '0');
    return '${negativo ? '-' : ''}R\$ $reais,$cents';
  }

  /// "45", "45,5" ou "45,50" -> 4500, 4550. Retorna null se inválido.
  static int? paraCentavos(String texto) {
    var t = texto.trim().replaceAll('R\$', '').replaceAll(' ', '');
    if (t.isEmpty || t.startsWith('-')) return null;
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    }
    final partes = t.split('.');
    if (partes.length > 2) return null;
    final reais = int.tryParse(partes[0].isEmpty ? '0' : partes[0]);
    if (reais == null) return null;
    var cents = 0;
    if (partes.length == 2) {
      if (partes[1].length > 2) return null;
      final c = int.tryParse(partes[1].padRight(2, '0'));
      if (c == null) return null;
      cents = c;
    }
    return reais * 100 + cents;
  }
}
