String formatarDataHora(DateTime? d) {
  if (d == null) return '—';
  String dois(int n) => n.toString().padLeft(2, '0');
  return '${dois(d.day)}/${dois(d.month)} ${dois(d.hour)}:${dois(d.minute)}';
}
