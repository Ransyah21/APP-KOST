import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../kamar/kamar_feature.dart'
    show DaftarKamarScreen, KelolaBookingScreen, PengaturanKosScreen;
import '../keluhan/keluhan.dart' show KeluhanEntryPage;
import '../login/models/user_profile.dart';
import '../tagihan/data/supabase_tagihan_repository.dart';
import '../tagihan/helpers.dart';
import '../tagihan/pages/tagihan_list_page.dart';
import 'dashboard_service.dart';
import 'dashboard_widgets.dart';

/// Dashboard untuk akun role `owner`:
/// ringkasan kos, daftar hal yang perlu ditindak, dan akses cepat ke semua fitur.
class OwnerDashboard extends StatelessWidget {
  const OwnerDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DashboardFrame<OwnerDashboardData>(
      profile: profile,
      judul: 'Dashboard Owner',
      load: DashboardService().owner,
      builder: (context, d, buka) {
        final tema = Theme.of(context);
        final repo = SupabaseTagihanRepository(Supabase.instance.client);
        void keTagihan() => buka(TagihanListPage(repo: repo, isOwner: true));
        void keBooking() => buka(const KelolaBookingScreen());
        void keKeluhan() =>
            buka(const KeluhanEntryPage(role: UserProfile.roleOwner));

        final tindakan = <Widget>[
          if (d.bookingPending > 0)
            BarisTindakan(
              icon: Icons.assignment_ind_outlined,
              judul: 'Pengajuan sewa menunggu persetujuan',
              jumlah: d.bookingPending,
              onTap: keBooking,
            ),
          if (d.tagihanMenunggu > 0)
            BarisTindakan(
              icon: Icons.fact_check_outlined,
              judul: 'Bukti bayar perlu diverifikasi',
              jumlah: d.tagihanMenunggu,
              onTap: keTagihan,
            ),
          if (d.tagihanTerlambat > 0)
            BarisTindakan(
              icon: Icons.warning_amber_rounded,
              judul: 'Tagihan terlambat',
              jumlah: d.tagihanTerlambat,
              merah: true,
              onTap: keTagihan,
            ),
          if (d.keluhanPending > 0)
            BarisTindakan(
              icon: Icons.report_problem_outlined,
              judul: 'Keluhan baru dari penghuni',
              jumlah: d.keluhanPending,
              onTap: keKeluhan,
            ),
        ];

        return [
          const JudulBagian('Perlu tindakan'),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: tindakan.isEmpty
                ? const ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Semua beres, tidak ada yang perlu ditindak.'),
                  )
                : Column(children: tindakan),
          ),
          const JudulBagian('Ringkasan kos'),
          BarisDua(
            StatTile(
              icon: Icons.meeting_room_outlined,
              label: 'Okupansi',
              value: '${(d.okupansi * 100).round()}%',
              catatan: '${d.kamarTerisi} dari ${d.kamarTotal} kamar terisi',
            ),
            StatTile(
              icon: Icons.door_front_door_outlined,
              label: 'Kamar kosong',
              value: '${d.kamarKosong}',
              catatan: d.kamarKosong == 0 ? 'Semua terisi' : 'Siap disewakan',
            ),
          ),
          const SizedBox(height: 12),
          BarisDua(
            StatTile(
              icon: Icons.payments_outlined,
              label: 'Pemasukan bulan ini',
              value: rupiah(d.pemasukanBulanIni),
              catatan: 'dari ${rupiah(d.tagihanBulanIni)} tagihan',
            ),
            StatTile(
              icon: Icons.money_off_csred_outlined,
              label: 'Tunggakan',
              value: rupiah(d.totalTunggakan),
              catatan: '${d.tagihanTerlambat} tagihan terlambat',
              warna: d.tagihanTerlambat > 0
                  ? tema.colorScheme.errorContainer
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          _GrafikPemasukan(data: d.grafik),
          const JudulBagian('Menu cepat'),
          GridAksi(
            children: [
              AksiTile(
                icon: Icons.meeting_room_outlined,
                label: 'Kelola Kamar',
                onTap: () => buka(const DaftarKamarScreen(initialIsOwner: true)),
              ),
              AksiTile(
                icon: Icons.assignment_ind_outlined,
                label: 'Booking',
                onTap: keBooking,
              ),
              AksiTile(
                icon: Icons.receipt_long_outlined,
                label: 'Tagihan',
                onTap: keTagihan,
              ),
              AksiTile(
                icon: Icons.report_problem_outlined,
                label: 'Keluhan',
                onTap: keKeluhan,
              ),
              AksiTile(
                icon: Icons.settings_outlined,
                label: 'Pengaturan Kos',
                onTap: () => buka(const PengaturanKosScreen()),
              ),
            ],
          ),
        ];
      },
    );
  }
}

/// Grafik batang sederhana (tanpa package tambahan).
class _GrafikPemasukan extends StatelessWidget {
  const _GrafikPemasukan({required this.data});

  final List<PemasukanBulanan> data;

  static const _tinggiBatang = 100.0;
  static const _bln = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final maks = data.fold<double>(0, (a, g) => g.total > a ? g.total : a);

    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pemasukan 6 bulan terakhir',
              style: tema.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text('Dari tagihan yang sudah lunas', style: tema.textTheme.bodySmall),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: Row(
                children: [
                  for (var i = 0; i < data.length; i++)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              data[i].total > 0 ? ringkasRupiah(data[i].total) : '',
                              style: tema.textTheme.labelSmall,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: maks == 0
                                ? 2.0
                                : (data[i].total / maks * _tinggiBatang)
                                    .clamp(2.0, _tinggiBatang)
                                    .toDouble(),
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              // bulan ini = warna utama, bulan lalu = lebih pudar
                              color: i == data.length - 1
                                  ? tema.colorScheme.primary
                                  : tema.colorScheme.primaryContainer,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _bln[(data[i].bulan - 1).clamp(0, 11).toInt()],
                            style: tema.textTheme.labelSmall,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}