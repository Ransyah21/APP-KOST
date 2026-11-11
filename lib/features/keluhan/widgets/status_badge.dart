import 'package:flutter/material.dart';

import '../models/complaint.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final ComplaintStatus status;

  Color get _warna => switch (status) {
        ComplaintStatus.pending => Colors.orange,
        ComplaintStatus.proses => Colors.blue,
        ComplaintStatus.selesai => Colors.green,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _warna.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _warna,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
