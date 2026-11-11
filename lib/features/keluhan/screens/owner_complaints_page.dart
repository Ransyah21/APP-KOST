import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../utils/format.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaint_detail_sheet.dart';
import '../widgets/state_message.dart';

/// Daftar semua keluhan (owner) + filter status + ubah status.
class OwnerComplaintsPage extends StatefulWidget {
  const OwnerComplaintsPage({super.key});

  @override
  State<OwnerComplaintsPage> createState() => _OwnerComplaintsPageState();
}

class _OwnerComplaintsPageState extends State<OwnerComplaintsPage> {
  final _service = ComplaintService();
  late Future<List<Complaint>> _future = _service.semuaKeluhan();
  ComplaintStatus? _filter; // null = semua

  Future<void> _refresh() async {
    final f = _service.semuaKeluhan();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  Future<void> _buka(Complaint c) async {
    final baru = await showComplaintDetail(context, c, canChangeStatus: true);
    if (baru == null || !mounted) return;
    try {
      await _service.ubahStatus(c.id, baru);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status diubah ke "${baru.label}"')),
      );
      await _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengubah status: ${pesanError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keluhan Penghuni')),
      body: FutureBuilder<List<Complaint>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return StateMessage(
              icon: Icons.error_outline,
              text: 'Gagal memuat keluhan.\n${pesanError(snap.error!)}',
              onRetry: _refresh,
            );
          }

          final semua = snap.data!;
          int hitung(ComplaintStatus s) =>
              semua.where((c) => c.status == s).length;
          final tampil = _filter == null
              ? semua
              : semua.where((c) => c.status == _filter).toList();

          return Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _chip('Semua (${semua.length})', null),
                    for (final s in ComplaintStatus.values)
                      _chip('${s.label} (${hitung(s)})', s),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: tampil.isEmpty
                      ? const StateMessage(
                          icon: Icons.inbox_outlined,
                          text: 'Tidak ada keluhan pada filter ini.',
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: tampil.length,
                          itemBuilder: (_, i) => ComplaintCard(
                            complaint: tampil[i],
                            showPenghuni: true,
                            onTap: () => _buka(tampil[i]),
                          ),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, ComplaintStatus? status) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _filter == status,
        onSelected: (_) => setState(() => _filter = status),
      ),
    );
  }
}
