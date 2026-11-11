import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../data/tagihan_repository.dart';
import '../helpers.dart';
import '../models/models.dart';
import 'status_badge.dart';

/// Owner: periksa bukti bayar lalu Terima / Tolak (F-10).
class VerifikasiPage extends StatefulWidget {
  const VerifikasiPage({super.key, required this.repo, required this.bill});
  final TagihanRepository repo;
  final Bill bill;

  @override
  State<VerifikasiPage> createState() => _VerifikasiPageState();
}

class _VerifikasiPageState extends State<VerifikasiPage> {
  Payment? _payment;
  Uint8List? _bukti;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    try {
      final p = await widget.repo.pembayaranTerakhir(widget.bill.id);
      Uint8List? img;
      if (p?.buktiPath != null) img = await widget.repo.unduhBukti(p!.buktiPath!);
      if (!mounted) return;
      setState(() {
        _payment = p;
        _bukti = img;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = bersihkanError(e);
        _loading = false;
      });
    }
  }

  Future<void> _proses(bool terima) async {
    setState(() => _busy = true);
    try {
      await widget.repo.verifikasi(paymentId: _payment!.id, terima: terima);
      if (!mounted) return;
      snack(context, terima ? 'Pembayaran diterima, tagihan lunas' : 'Pembayaran ditolak');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      snack(context, bersihkanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bill;
    final menunggu = _payment?.status == 'menunggu';

    return Scaffold(
      appBar: AppBar(title: const Text('Verifikasi pembayaran')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Expanded(
                          child: Text('${b.namaPenghuni} • Kamar ${b.nomorKamar}',
                              style: Theme.of(context).textTheme.titleMedium),
                        ),
                        StatusBadge(b.status, terlambat: b.terlambat),
                      ]),
                      const SizedBox(height: 8),
                      Text('${namaBulan[b.bulan - 1]} ${b.tahun}'),
                      const SizedBox(height: 4),
                      Text(rupiah(b.jumlah), style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text('Jatuh tempo ${tanggal(b.jatuhTempo)}'),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                if (_error != null) Text('Gagal memuat bukti: $_error'),
                if (_payment == null && _error == null)
                  const Text('Penghuni belum mengunggah bukti bayar.'),
                if (_payment != null) ...[
                  Text('Bukti bayar • ${tanggal(_payment!.tanggalBayar)}',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  if (_bukti != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(_bukti!, fit: BoxFit.contain),
                    )
                  else
                    const Text('(Gambar bukti tidak tersedia)'),
                  const SizedBox(height: 8),
                  Text('Status pembayaran: ${_payment!.status}'),
                ],
                if (menunggu) ...[
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _proses(false),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red.shade700),
                        child: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : () => _proses(true),
                        child: const Text('Terima'),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
    );
  }
}
