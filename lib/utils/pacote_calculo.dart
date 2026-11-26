/// Soma [n] meses a uma data, ajustando o dia quando o mês é mais curto
/// (31/01 + 1 mês = 28/02 ou 29/02).
DateTime somarMeses(DateTime d, int n) {
  final total = d.month - 1 + n;
  final ano = d.year + total ~/ 12;
  final mes = total % 12 + 1;
  final ultimoDia = DateTime(ano, mes + 1, 0).day;
  final dia = d.day > ultimoDia ? ultimoDia : d.day;
  return DateTime(ano, mes, dia);
}

/// Número do mês de uso (0 = primeiro) em que [dia] cai, contando a
/// partir da data da compra.
int cicloDe(DateTime inicio, DateTime dia) {
  var k = (dia.year - inicio.year) * 12 + (dia.month - inicio.month);
  if (k < 0) return 0;

  while (k > 0 && somarMeses(inicio, k).isAfter(dia)) {
    k--;
  }
  while (!somarMeses(inicio, k + 1).isAfter(dia)) {
    k++;
  }
  return k;
}

/// "2026-11-25" -> data. Nulo se inválida.
DateTime? parseDiaIso(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return null;

  final a = int.tryParse(p[0]);
  final m = int.tryParse(p[1]);
  final d = int.tryParse(p[2]);
  if (a == null || m == null || d == null) return null;

  return DateTime(a, m, d);
}
