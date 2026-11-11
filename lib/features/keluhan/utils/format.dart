String formatWaktu(DateTime d) {
  String dua(int n) => n.toString().padLeft(2, '0');
  return '${dua(d.day)}/${dua(d.month)}/${d.year} ${dua(d.hour)}:${dua(d.minute)}';
}

String pesanError(Object e) {
  final teks = e.toString();
  return teks.startsWith('Exception: ') ? teks.substring(11) : teks;
}
