import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../utils/format.dart';
import 'status_badge.dart';

class ComplaintCard extends StatelessWidget {
  const ComplaintCard({
    super.key,
    required this.complaint,
    required this.onTap,
    this.showPenghuni = false,
  });

  final Complaint complaint;
  final VoidCallback onTap;

  /// true di sisi owner: tampilkan nama penghuni dan nomor kamar.
  final bool showPenghuni;

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final meta = [
      if (showPenghuni) c.penghuniNama ?? 'Penghuni',
      if (showPenghuni && c.nomorKamar != null) 'Kamar ${c.nomorKamar}',
      formatWaktu(c.createdAt),
    ].join(' • ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(c.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(c.isi, maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(
                meta,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
