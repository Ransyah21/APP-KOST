import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/user_profile.dart';
import '../navigation/app_menu.dart';
import '../services/auth_service.dart';

/// Menu utama: sapaan, kartu ringkasan, lalu tombol ke fitur.
/// Daftar tombol diatur di lib/navigation/app_menu.dart.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  Future<void> _keluar(BuildContext context) async {
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

  void _bukaMenu(BuildContext context, MenuItemData item) {
    final builder = item.builder;
    if (builder == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fitur ${item.label} belum tersedia.')),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final menu = appMenu.where((m) => m.roles.contains(profile.role)).toList();
    final ringkasan = ringkasanUntuk(profile.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppInfo.name),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () => _keluar(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Halo, ${profile.nama}',
              style: tema.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Masuk sebagai ${profile.labelRole}',
              style: tema.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            Card.filled(
              color: tema.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      for (var i = 0; i < ringkasan.length; i++) ...[
                        if (i > 0) const VerticalDivider(width: 1),
                        Expanded(child: _KolomRingkasan(data: ringkasan[i])),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.25,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final item in menu)
                  _TombolMenu(
                    item: item,
                    onTap: () => _bukaMenu(context, item),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KolomRingkasan extends StatelessWidget {
  const _KolomRingkasan({required this.data});

  final SummaryItemData data;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.value,
            style: tema.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            data.label,
            textAlign: TextAlign.center,
            style: tema.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TombolMenu extends StatelessWidget {
  const _TombolMenu({required this.item, required this.onTap});

  final MenuItemData item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card.outlined(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                backgroundColor: tema.colorScheme.primaryContainer,
                foregroundColor: tema.colorScheme.onPrimaryContainer,
                child: Icon(item.icon),
              ),
              Text(
                item.label,
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
