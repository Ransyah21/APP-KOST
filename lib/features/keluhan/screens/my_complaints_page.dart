import 'package:flutter/material.dart';

import '../models/complaint.dart';
import '../services/complaint_service.dart';
import '../utils/format.dart';
import '../widgets/complaint_card.dart';
import '../widgets/complaint_detail_sheet.dart';
import '../widgets/state_message.dart';
import 'complaint_form_page.dart';

/// Halaman "Keluhan saya" (penghuni): daftar keluhan + status, tombol kirim baru.
class MyComplaintsPage extends StatefulWidget {
  const MyComplaintsPage({super.key});

  @override
  State<MyComplaintsPage> createState() => _MyComplaintsPageState();
}

class _MyComplaintsPageState extends State<MyComplaintsPage> {
  final _service = ComplaintService();
  late Future<List<Complaint>> _future = _service.keluhanSaya();

  Future<void> _refresh() async {
    final f = _service.keluhanSaya();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  Future<void> _kirimBaru() async {
    final berhasil = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ComplaintFormPage()),
    );
    if (berhasil == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Keluhan Saya')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _kirimBaru,
        icon: const Icon(Icons.add),
        label: const Text('Kirim keluhan'),
      ),
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
          final data = snap.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: data.isEmpty
                ? const StateMessage(
                    icon: Icons.inbox_outlined,
                    text: 'Belum ada keluhan.\nKetuk "Kirim keluhan" untuk membuat.',
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 96),
                    itemCount: data.length,
                    itemBuilder: (_, i) => ComplaintCard(
                      complaint: data[i],
                      onTap: () => showComplaintDetail(context, data[i]),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
