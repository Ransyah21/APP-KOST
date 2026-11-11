import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const namaBulan = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
];

String rupiah(num v) =>
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(v);

String tanggal(DateTime d) => '${d.day} ${namaBulan[d.month - 1]} ${d.year}';

void snack(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : null,
    ));
}

String bersihkanError(Object e) =>
    e.toString().replaceAll('Exception: ', '').replaceAll('PostgrestException', '');
