import 'package:flutter/material.dart';
import '../data/tagihan_repository.dart';
import '../helpers.dart';
import '../models/models.dart';

/// Owner: buat tagihan bulanan untuk penghuni (F-07).
class BuatTagihanPage extends StatefulWidget {
  const BuatTagihanPage({super.key, required this.repo});
  final TagihanRepository repo;

  @override
  State<BuatTagihanPage> createState() => _BuatTagihanPageState();
}

class _BuatTagihanPageState extends State<BuatTagihanPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahCtrl = TextEditingController();
  late Future<List<BookingOption>> _opsi;

  BookingOption? _booking;
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;
  DateTime _jatuhTempo = DateTime.now().add(const Duration(days: 7));
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _opsi = widget.repo.daftarBookingAktif();
  }

  @override
  void dispose() {
    _jumlahCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _jatuhTempo,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );
    if (d != null) setState(() => _jatuhTempo = d);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await widget.repo.buatTagihan(
        bookingId: _booking!.id,
        bulan: _bulan,
        tahun: _tahun,
        jumlah: double.parse(_jumlahCtrl.text.replaceAll('.', '').trim()),
        jatuhTempo: _jatuhTempo,
      );
      if (!mounted) return;
      snack(context, 'Tagihan berhasil dibuat');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      snack(context, bersihkanError(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buat tagihan')),
      body: FutureBuilder<List<BookingOption>>(
        future: _opsi,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return Center(child: Text(bersihkanError(snap.error!)));
          final opsi = snap.data!;
          if (opsi.isEmpty) {
            return const Center(
                child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Belum ada penghuni aktif (booking yang disetujui).'),
            ));
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<BookingOption>(
                  initialValue: _booking,
                  decoration: const InputDecoration(
                      labelText: 'Penghuni', border: OutlineInputBorder()),
                  items: [
                    for (final o in opsi) DropdownMenuItem(value: o, child: Text(o.label))
                  ],
                  onChanged: (o) => setState(() {
                    _booking = o;
                    if (o != null) _jumlahCtrl.text = o.hargaBulanan.toStringAsFixed(0);
                  }),
                  validator: (v) => v == null ? 'Pilih penghuni' : null,
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: _bulan,
                      decoration: const InputDecoration(
                          labelText: 'Bulan', border: OutlineInputBorder()),
                      items: [
                        for (var i = 1; i <= 12; i++)
                          DropdownMenuItem(value: i, child: Text(namaBulan[i - 1]))
                      ],
                      onChanged: (v) => setState(() => _bulan = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: _tahun,
                      decoration: const InputDecoration(
                          labelText: 'Tahun', border: OutlineInputBorder()),
                      items: [
                        for (var y = DateTime.now().year - 1; y <= DateTime.now().year + 1; y++)
                          DropdownMenuItem(value: y, child: Text('$y'))
                      ],
                      onChanged: (v) => setState(() => _tahun = v!),
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _jumlahCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Jumlah tagihan', prefixText: 'Rp ',
                      border: OutlineInputBorder()),
                  validator: (v) {
                    final n = double.tryParse((v ?? '').replaceAll('.', '').trim());
                    if (n == null || n <= 0) return 'Isi jumlah yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: _pilihTanggal,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                        labelText: 'Jatuh tempo',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_month)),
                    child: Text(tanggal(_jatuhTempo)),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _simpan,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Simpan tagihan'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
