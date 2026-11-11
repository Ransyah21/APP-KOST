import 'package:flutter/material.dart';

import '../models/user_profile.dart';

/// Satu tombol di menu utama.
class MenuItemData {
  const MenuItemData({
    required this.label,
    required this.icon,
    required this.roles,
    this.builder,
  });

  final String label;
  final IconData icon;

  /// Role yang boleh melihat tombol ini.
  final Set<String> roles;

  /// Layar tujuan. Biarkan null sampai fiturnya jadi.
  final WidgetBuilder? builder;
}

const Set<String> _semuaRole = {
  UserProfile.roleOwner,
  UserProfile.rolePenghuni,
};

/// ============================================================
/// DAFTAR MENU UTAMA
/// - Menambah tombol baru: tambah satu MenuItemData di bawah.
/// - Menyambungkan fitur: isi `builder`, contoh:
///     builder: (_) => const DaftarKamarScreen(),
/// ============================================================
final List<MenuItemData> appMenu = [
  MenuItemData(
    label: 'Kamar & Booking',
    icon: Icons.meeting_room_outlined,
    roles: _semuaRole,
    // builder: (_) => const ...Screen(),   // anggota 2
  ),
  MenuItemData(
    label: 'Tagihan',
    icon: Icons.receipt_long_outlined,
    roles: _semuaRole,
    // builder: (_) => const ...Screen(),   // anggota 3
  ),
  MenuItemData(
    label: 'Keluhan',
    icon: Icons.report_problem_outlined,
    roles: _semuaRole,
    // builder: (_) => const ...Screen(),   // anggota 4
  ),
  MenuItemData(
    label: 'Dashboard & Laporan',
    icon: Icons.bar_chart_outlined,
    roles: _semuaRole,
    // builder: (_) => const ...Screen(),   // anggota 5
  ),
];

/// Satu kolom di kartu ringkasan menu utama.
class SummaryItemData {
  const SummaryItemData(this.label, [this.value = '-']);
  final String label;
  final String value;
}

/// Placeholder. Setelah fitur lain jadi, ganti `value` dengan data asli
/// (misalnya hasil query tagihan atau keluhan).
List<SummaryItemData> ringkasanUntuk(String role) {
  if (role == UserProfile.roleOwner) {
    return const [
      SummaryItemData('Kamar terisi'),
      SummaryItemData('Tagihan belum lunas'),
      SummaryItemData('Keluhan baru'),
    ];
  }
  return const [
    SummaryItemData('Kamar saya'),
    SummaryItemData('Tagihan bulan ini'),
    SummaryItemData('Keluhan saya'),
  ];
}
