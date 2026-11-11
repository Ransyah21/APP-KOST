import 'package:flutter/material.dart';
import '../data/tagihan_repository.dart';
import '../helpers.dart';
import '../models/models.dart';
import 'buat_tagihan_page.dart';
import 'status_badge.dart';
import 'upload_bukti_page.dart';
import 'verifikasi_page.dart';

/// Halaman utama modul Tagihan (dipakai owner & penghuni).
/// Dari menu utama (modul 1) cukup:
///   Navigator.push(context, MaterialPageRoute(builder: (_) =>
///     TagihanListPage(repo: SupabaseTagihanRepository(Supabase.instance.client),
///                     isOwner: role == 'owner')));
class TagihanListPage extends StatefulWidget {
  const TagihanListPage({super.key, required this.repo, required this.isOwner});
  final TagihanRepository repo;
  final bool isOwner;

  @override
  State<TagihanListPage> createState() => _TagihanListPageState();
}

class _TagihanListPageState extends State<TagihanListPage> {
  late Future<List<Bill>> _future;
  BillStatus? _filter; // null = semua

  @override
  void initState() {
    super.initState();
    _future = widget.repo.daftarTagihan();
  }

  Future<void> _refresh() async {
    final f = widget.repo.daftarTagihan();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {}
  }

  Future<void> _buka(Bill b) async {
    final Widget page = widget.isOwner
        ? VerifikasiPage(repo: widget.repo, bill: b)
        : UploadBuktiPage(repo: widget.repo, bill: b);
    final changed =
        await Navigator.push<bool>(context, MaterialPageRoute(builder: (_) => page));
    if (changed == true) _refresh();
  }

  Future<void> _buat() async {
    final ok = await Navigator.push<bool>(
        context, MaterialPageRoute(builder: (_) => BuatTagihanPage(repo: widget.repo)));
    if (ok == true) _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isOwner ? 'Tagihan' : 'Tagihan saya')),
      floatingActionButton: widget.isOwner
          ? FloatingActionButton.extended(
              onPressed: _buat, icon: const Icon(Icons.add), label: const Text('Buat tagihan'))
          : null,
      body: Column(
        children: [
          _filterBar(),
          Expanded(
            child: FutureBuilder<List<Bill>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Gagal memuat: ${bersihkanError(snap.error!)}'),
                      const SizedBox(height: 8),
                      FilledButton(onPressed: _refresh, child: const Text('Coba lagi')),
                    ]),
                  );
                }
                final data =
                    snap.data!.where((b) => _filter == null || b.status == _filter).toList();
                if (data.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Belum ada tagihan')),
                    ]),
                  );
                }
                return RefreshIndicator(onRefresh: _refresh, child: _list(data));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterBar() {
    final opsi = <(String, BillStatus?)>[
      ('Semua', null),
      ('Belum bayar', BillStatus.belumBayar),
      ('Menunggu', BillStatus.menungguVerifikasi),
      ('Lunas', BillStatus.lunas),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          for (final (label, st) in opsi)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label),
                selected: _filter == st,
                onSelected: (_) => setState(() => _filter = st),
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(List<Bill> data) {
    final items = <Widget>[];
    int? lastKey;
    for (final b in data) {
      final key = b.tahun * 100 + b.bulan;
      if (key != lastKey) {
        items.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text('${namaBulan[b.bulan - 1]} ${b.tahun}',
              style: Theme.of(context).textTheme.titleSmall),
        ));
        lastKey = key;
      }
      items.add(_kartu(b));
    }
    items.add(const SizedBox(height: 90));
    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: items);
  }

  Widget _kartu(Bill b) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: ListTile(
          onTap: () => _buka(b),
          title: Text(widget.isOwner
              ? '${b.namaPenghuni} • Kamar ${b.nomorKamar}'
              : 'Kamar ${b.nomorKamar}'),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${rupiah(b.jumlah)}\nJatuh tempo ${tanggal(b.jatuhTempo)}'),
          ),
          isThreeLine: true,
          trailing: StatusBadge(b.status, terlambat: b.terlambat),
        ),
      );
}
