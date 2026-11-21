/// "15", "12,5" ou "10%" -> pontos-base (1500, 1250, 1000). Inválido: null.
int? percentualParaBp(String texto) {
  final t = texto.trim().replaceAll('%', '').replaceAll(',', '.');
  final v = double.tryParse(t);
  if (v == null || v < 0 || v > 100) return null;
  return (v * 100).round();
}

/// 1500 -> "15%", 1250 -> "12,50%"
String bpParaTexto(int bp) {
  if (bp % 100 == 0) return '${bp ~/ 100}%';
  return '${(bp / 100).toStringAsFixed(2).replaceAll('.', ',')}%';
}
