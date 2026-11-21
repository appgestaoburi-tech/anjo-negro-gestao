String _dois(int n) => n.toString().padLeft(2, '0');

String formatarDataHora(DateTime? d) {
  if (d == null) return '—';
  return '${_dois(d.day)}/${_dois(d.month)} ${_dois(d.hour)}:${_dois(d.minute)}';
}

/// "2026-11-21"
String diaIso(DateTime d) => '${d.year}-${_dois(d.month)}-${_dois(d.day)}';
