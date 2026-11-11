import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../kamar/kamar_feature.dart' show DaftarKamarScreen, bukaWhatsApp;
import '../keluhan/keluhan.dart' show KeluhanEntryPage;
import '../login/models/user_profile.dart';
import '../tagihan/data/supabase_tagihan_repository.dart';
import '../tagihan/helpers.dart';
import '../tagihan/pages/tagihan_list_page.dart';
import 'dashboard_service.dart';
import 'dashboard_widgets.dart';

/// Dashboard untuk akun role `penghuni`: hanya data milik dia sendiri
/// (kamar, tagihan, keluhan) + info rekening dan kontak owner.
class PenghuniDashboard extends StatelessWidget {
  const PenghuniDashboard({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return DashboardFrame<PenghuniDashboardData>(
      profile: profile,
      judul: 'Dashboard Penghuni',
      load: DashboardService().penghuni,
      builder: (context, d, buka) {
        final tema = Theme.of(context);

        // Modul tagihan memfilter berdasarkan booking.nama, jadi pakai nama
        // yang tersimpan di booking (bisa beda dengan nama profil).
        final namaBooking = d.kamarAktif?.namaBooking ?? '';
        final repo = SupabaseTagihanRepository(
          Supabase.instance.client,
          sebagaiPenghuni: namaBooking.isNotEmpty ? namaBooking : profile.nama,
        );

        final adaKontak = (d.noWa ?? '').isNotEmpty;
        final adaRekening = (d.noRekening ?? '').isNotEmpty;

        return [
          // ---------------- KAMAR SAYA ----------------
          _kartuKamar(context, d, buka, adaKontak),

          // ---------------- TAGIHAN ----------------
          if (d.kamarAktif != null || d.adaTagihan) ...[
            const JudulBagian('Tagihan'),
            if (d.terlambat > 0)
              Card.filled(
                color: tema.colorScheme.errorContainer,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber_rounded),
                  title: Text('${d.terlambat} tagihan terlambat'),
                  subtitle: const Text('Segera lunasi supaya tidak menumpuk.'),
                ),
              ),
            BarisDua(
              StatTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Harus dibayar',
                value: rupiah(d.totalBelumBayar),
                catatan: '${d.belumBayar} tagihan belum bayar',
              ),
              StatTile(
                icon: Icons.event_outlined,
                label: 'Tagihan terdekat',
                value: d.terdekat == null ? '-' : rupiah(d.terdekat!.jumlah),
                catatan: d.terdekat?.jatuhTempo == null
                    ? 'Tidak ada tagihan'
                    : 'Jatuh tempo ${tanggal(d.terdekat!.jatuhTempo!)}',
              ),
            ),
            if (d.menunggu > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${d.menunggu} pembayaran sedang diverifikasi owner.',
                  style: tema.textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () =>
                  buka(TagihanListPage(repo: repo, isOwner: false)),
              icon: const Icon(Icons.receipt_long_outlined),
              label: const Text('Lihat & bayar tagihan'),
            ),
          ],

          // ---------------- KELUHAN ----------------
          const JudulBagian('Keluhan saya'),
          Card.outlined(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _Angka('${d.keluhanPending}', 'Pending'),
                      _Angka('${d.keluhanProses}', 'Diproses'),
                      _Angka('${d.keluhanSelesai}', 'Selesai'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => buka(
                        const KeluhanEntryPage(role: UserProfile.rolePenghuni),
                      ),
                      icon: const Icon(Icons.report_problem_outlined),
                      label: const Text('Kirim / lihat keluhan'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------- INFO PEMBAYARAN & KONTAK ----------------
          if (adaRekening || adaKontak) ...[
            JudulBagian(
              (d.namaKos ?? '').isNotEmpty ? d.namaKos! : 'Info pembayaran',
            ),
            Card.outlined(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  if (adaRekening)
                    ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(d.noRekening!),
                      subtitle: Text(
                        [
                          if ((d.bank ?? '').isNotEmpty) d.bank!,
                          if ((d.atasNama ?? '').isNotEmpty)
                            'a.n. ${d.atasNama}',
                        ].join(' • '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Salin nomor rekening',
                        icon: const Icon(Icons.copy),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: d.noRekening!),
                          );
                          if (context.mounted) {
                            snack(context, 'Nomor rekening disalin');
                          }
                        },
                      ),
                    ),
                  if (adaKontak)
                    ListTile(
                      leading: const Icon(Icons.chat_outlined),
                      title: const Text('Hubungi owner via WhatsApp'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => bukaWhatsApp(
                        context,
                        nomor: d.noWa!,
                        pesan: 'Halo, saya ${profile.nama}, penghuni kos.',
                      ),
                    ),
                ],
              ),
            ),
          ],
        ];
      },
    );
  }

  Widget _kartuKamar(
    BuildContext context,
    PenghuniDashboardData d,
    Future<void> Function(Widget page) buka,
    bool adaKontak,
  ) {
    final tema = Theme.of(context);

    // 1) Sudah punya kamar
    final aktif = d.kamarAktif;
    if (aktif != null) {
      return Card.filled(
        color: tema.colorScheme.primaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.meeting_room_outlined, size: 18),
                  const SizedBox(width: 6),
                  Text('Kamar saya', style: tema.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Kamar ${aktif.nomor}',
                style: tema.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text('${rupiah(aktif.harga)} / bulan'),
              if (aktif.tanggalMasuk != null)
                Text('Masuk sejak ${tanggal(aktif.tanggalMasuk!)}'),
            ],
          ),
        ),
      );
    }

    // 2) Pengajuan masih menunggu owner
    if (d.pendingNomor != null) {
      return Card.filled(
        color: tema.colorScheme.secondaryContainer,
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.hourglass_top_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('Menunggu persetujuan', style: tema.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pengajuan sewa Kamar ${d.pendingNomor}',
                style: tema.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              const Text('Owner akan memproses pengajuanmu.'),
              if (adaKontak)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: OutlinedButton.icon(
                    onPressed: () => bukaWhatsApp(
                      context,
                      nomor: d.noWa!,
                      pesan:
                          'Halo, saya ${profile.nama}. Saya sudah mengajukan sewa Kamar ${d.pendingNomor}.',
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Hubungi owner'),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 3) Belum punya kamar sama sekali
    return Card.outlined(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kamu belum punya kamar',
              style: tema.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text('Lihat kamar yang tersedia lalu ajukan sewa.'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => buka(const DaftarKamarScreen()),
              icon: const Icon(Icons.search),
              label: const Text('Lihat kamar tersedia'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Angka extends StatelessWidget {
  const _Angka(this.angka, this.label);

  final String angka;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            angka,
            style: tema.textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(label, style: tema.textTheme.bodySmall),
        ],
      ),
    );
  }
}