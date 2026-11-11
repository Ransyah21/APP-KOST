import 'package:flutter/material.dart';

import '../login/models/user_profile.dart';
import '../login/services/auth_service.dart';
import 'dashboard_service.dart';

/// "1,5 jt", "850 rb", dst. Untuk angka yang sempit (grafik, kartu kecil).
String ringkasRupiah(num v) {
  String f(double x) =>
      x.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ',');
  if (v >= 1000000000) return '${f(v / 1e9)} M';
  if (v >= 1000000) return '${f(v / 1e6)} jt';
  if (v >= 1000) return '${f(v / 1e3)} rb';
  return v.toStringAsFixed(0);
}

/// Kerangka dashboard: AppBar + logout, sapaan, tarik-untuk-refresh,
/// loading, dan layar error. Isinya diisi lewat [builder].
/// `buka(page)` = pindah ke halaman fitur, lalu dashboard otomatis refresh
/// saat user kembali (jadi angka selalu terbaru).
class DashboardFrame<T> extends StatefulWidget {
  const DashboardFrame({
    super.key,
    required this.profile,
    required this.judul,
    required this.load,
    required this.builder,
  });

  final UserProfile profile;
  final String judul;
  final Future<T> Function() load;
  final List<Widget> Function(
    BuildContext context,
    T data,
    Future<void> Function(Widget page) buka,
  ) builder;

  @override
  State<DashboardFrame<T>> createState() => _DashboardFrameState<T>();
}

class _DashboardFrameState<T> extends State<DashboardFrame<T>> {
  late Future<T> _future = widget.load();

  Future<void> _refresh() async {
    final f = widget.load();
    setState(() => _future = f);
    try {
      await f;
    } catch (_) {
      // error ditampilkan oleh FutureBuilder
    }
  }

  Future<void> _buka(Widget page) async {
    await Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => page));
    if (mounted) _refresh();
  }

  Future<void> _keluar() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu masuk lagi untuk membuka aplikasi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (yakin == true) await AuthService.instance.logout();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final owner = widget.profile.isOwner;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.judul),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: _keluar,
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<T>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return _Galat(
                pesan: DashboardService.pesanError(snap.error!),
                onCobaLagi: _refresh,
                onKeluar: _keluar,
              );
            }
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Halo, ${widget.profile.nama}',
                          style: tema.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Chip(
                        avatar: Icon(
                          owner
                              ? Icons.admin_panel_settings_outlined
                              : Icons.person_outline,
                          size: 18,
                        ),
                        label: Text(widget.profile.labelRole),
                        backgroundColor: owner
                            ? tema.colorScheme.primaryContainer
                            : tema.colorScheme.secondaryContainer,
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...widget.builder(context, snap.data as T, _buka),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Galat extends StatelessWidget {
  const _Galat({
    required this.pesan,
    required this.onCobaLagi,
    required this.onKeluar,
  });

  final String pesan;
  final VoidCallback onCobaLagi;
  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(pesan, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onCobaLagi, child: const Text('Coba lagi')),
            TextButton(onPressed: onKeluar, child: const Text('Keluar')),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Komponen kecil
// ---------------------------------------------------------------------

class JudulBagian extends StatelessWidget {
  const JudulBagian(this.teks, {super.key});
  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        teks,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Dua kartu sejajar dengan tinggi sama.
class BarisDua extends StatelessWidget {
  const BarisDua(this.kiri, this.kanan, {super.key});
  final Widget kiri;
  final Widget kanan;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: kiri),
          const SizedBox(width: 12),
          Expanded(child: kanan),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.catatan,
    this.warna,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? catatan;
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card.filled(
      color: warna,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: tema.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: tema.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (catatan != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  catatan!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: tema.textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Baris "perlu tindakan" dengan badge jumlah.
class BarisTindakan extends StatelessWidget {
  const BarisTindakan({
    super.key,
    required this.icon,
    required this.judul,
    required this.jumlah,
    required this.onTap,
    this.merah = false,
  });

  final IconData icon;
  final String judul;
  final int jumlah;
  final VoidCallback onTap;
  final bool merah;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: tema.colorScheme.primaryContainer,
        foregroundColor: tema.colorScheme.onPrimaryContainer,
        child: Icon(icon),
      ),
      title: Text(judul),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Badge(
            label: Text('$jumlah'),
            backgroundColor: merah ? tema.colorScheme.error : null,
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Tombol menu cepat (grid 2 kolom).
class AksiTile extends StatelessWidget {
  const AksiTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card.outlined(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                foregroundColor: tema.colorScheme.onPrimaryContainer,
                child: Icon(icon),
              ),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: tema.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GridAksi extends StatelessWidget {
  const GridAksi({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}