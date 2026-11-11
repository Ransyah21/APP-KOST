import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data/tagihan_repository.dart';
import '../helpers.dart';
import '../models/models.dart';
import 'status_badge.dart';

/// Penghuni: lihat detail tagihan + upload bukti bayar (F-08, F-09).
class UploadBuktiPage extends StatefulWidget {
  const UploadBuktiPage({super.key, required this.repo, required this.bill});
  final TagihanRepository repo;
  final Bill bill;

  @override
  State<UploadBuktiPage> createState() => _UploadBuktiPageState();
}

class _UploadBuktiPageState extends State<UploadBuktiPage> {
  Uint8List? _bytes;
  String _namaFile = 'bukti.jpg';
  Payment? _last;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _muatTerakhir();
  }

  Future<void> _muatTerakhir() async {
    try {
      final p = await widget.repo.pembayaranTerakhir(widget.bill.id);
      if (mounted) setState(() => _last = p);
    } catch (_) {}
  }

  Future<void> _pilih() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
    if (x == null) return;
    final b = await x.readAsBytes();
    if (b.lengthInBytes > 5 * 1024 * 1024) {
      if (mounted) snack(context, 'Ukuran foto maksimal 5 MB', error: true);
      return;
    }
    setState(() {
      _bytes = b;
      _namaFile = x.name;
    });
  }

  Future<void> _kirim() async {
    if (_bytes == null) return;
    setState(() => _sending = true);
    try {
      await widget.repo.uploadBukti(
          billId: widget.bill.id, bytes: _bytes!, fileName: _namaFile);
      if (!mounted) return;
      snack(context, 'Bukti terkirim, menunggu verifikasi owner');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      snack(context, 'Gagal mengirim: ${bersihkanError(e)}', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.bill;
    final bisaUpload = b.status == BillStatus.belumBayar;
    final ditolak = bisaUpload && _last?.status == 'ditolak';

    return Scaffold(
      appBar: AppBar(title: Text('Tagihan ${namaBulan[b.bulan - 1]} ${b.tahun}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Kamar ${b.nomorKamar}', style: Theme.of(context).textTheme.titleMedium),
                  StatusBadge(b.status, terlambat: b.terlambat),
                ]),
                const SizedBox(height: 12),
                Text(rupiah(b.jumlah), style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text('Jatuh tempo ${tanggal(b.jatuhTempo)}'),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          if (ditolak)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
              child: const Text('Bukti bayar sebelumnya ditolak owner. Silakan unggah ulang.'),
            ),
          if (bisaUpload) ...[
            Text('Bukti transfer', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            if (_bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(_bytes!, height: 320, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _sending ? null : _pilih,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_bytes == null ? 'Pilih foto' : 'Ganti foto'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: (_bytes == null || _sending) ? null : _kirim,
              child: _sending
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Kirim bukti bayar'),
            ),
          ] else
            Text(
              b.status == BillStatus.lunas
                  ? 'Tagihan ini sudah lunas. Terima kasih!'
                  : 'Bukti bayar sudah dikirim dan sedang diperiksa owner.',
            ),
        ],
      ),
    );
  }
}
