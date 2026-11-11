import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../utils/format.dart';
import 'status_badge.dart';

/// Menampilkan detail keluhan. Jika [canChangeStatus] true (owner), sheet
/// menampilkan tombol ubah status dan mengembalikan status yang dipilih
/// (null jika sheet ditutup tanpa memilih).
Future<ComplaintStatus?> showComplaintDetail(
  BuildContext context,
  Complaint complaint, {
  bool canChangeStatus = false,
}) {
  return showModalBottomSheet<ComplaintStatus>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _DetailSheet(
      complaint: complaint,
      canChangeStatus: canChangeStatus,
    ),
  );
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.complaint, required this.canChangeStatus});

  final Complaint complaint;
  final bool canChangeStatus;

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final pilihan = [ComplaintStatus.proses, ComplaintStatus.selesai]
        .where((s) => s != c.status)
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.judul,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(c.status),
              ],
            ),
            const SizedBox(height: 12),
            if (canChangeStatus && c.penghuniNama != null)
              _Baris('Pengirim', c.penghuniNama!),
            if (c.nomorKamar != null) _Baris('Kamar', c.nomorKamar!),
            _Baris('Dikirim', formatWaktu(c.createdAt)),
            _Baris('Diperbarui', formatWaktu(c.updatedAt)),
            const Divider(height: 24),
            Text(c.isi),
            if (canChangeStatus && pilihan.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Ubah status',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in pilihan)
                    FilledButton(
                      onPressed: () => Navigator.pop(context, s),
                      child: Text(s.label),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  const _Baris(this.label, this.nilai);

  final String label;
  final String nilai;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(nilai)),
        ],
      ),
    );
  }
}
