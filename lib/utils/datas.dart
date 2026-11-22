String _dois(int n) => n.toString().padLeft(2, '0');

String formatarDataHora(DateTime? d) {
  if (d == null) return '—';
  return '${_dois(d.day)}/${_dois(d.month)} ${_dois(d.hour)}:${_dois(d.minute)}';
}

/// "2026-11-21"
String diaIso(DateTime d) => '${d.year}-${_dois(d.month)}-${_dois(d.day)}';

/// "21/11/2026"
String formatarDia(DateTime d) => '${_dois(d.day)}/${_dois(d.month)}/${d.year}';

/// "2026-11-21" -> "21/11/2026"
String formatarDiaIso(String iso) {
  final p = iso.split('-');
  if (p.length != 3) return iso;
  return '${p[2]}/${p[1]}/${p[0]}';
}

/// "21/11/2026" -> "2026-11-21". Retorna null se for inválida ou futura.
String? dataParaIso(String texto) {
  final m = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(texto.trim());
  if (m == null) return null;

  final dia = int.parse(m[1]!);
  final mes = int.parse(m[2]!);
  final ano = int.parse(m[3]!);

  final data = DateTime(ano, mes, dia);
  if (data.year != ano || data.month != mes || data.day != dia) return null;
  if (ano < 2000) return null;

  final agora = DateTime.now();
  final hoje = DateTime(agora.year, agora.month, agora.day);
  if (data.isAfter(hoje)) return null;

  return diaIso(data);
}

/// Segunda-feira da semana de [d].
DateTime segundaDaSemana(DateTime d) {
  return DateTime(d.year, d.month, d.day - (d.weekday - 1));
}
