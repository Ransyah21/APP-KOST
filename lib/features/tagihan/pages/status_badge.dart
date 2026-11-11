import 'package:flutter/material.dart';
import '../models/models.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.terlambat = false});
  final BillStatus status;
  final bool terlambat;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg, String text) = switch (status) {
      BillStatus.lunas => (Colors.green.shade100, Colors.green.shade900, 'Lunas'),
      BillStatus.menungguVerifikasi =>
        (Colors.orange.shade100, Colors.orange.shade900, 'Menunggu verifikasi'),
      BillStatus.belumBayar => terlambat
          ? (Colors.red.shade100, Colors.red.shade900, 'Terlambat')
          : (Colors.blueGrey.shade100, Colors.blueGrey.shade900, 'Belum bayar'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
