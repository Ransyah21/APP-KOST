// lib/features/kamar/screens/kelola_booking_screen.dart

import 'package:flutter/material.dart';
import '../models/booking_model.dart';
import '../services/kamar_service.dart';
import '../utils/wa_helper.dart';

class KelolaBookingScreen extends StatefulWidget {
  const KelolaBookingScreen({super.key});

  @override
  State<KelolaBookingScreen> createState() => _KelolaBookingScreenState();
}

class _KelolaBookingScreenState extends State<KelolaBookingScreen> {
  final KamarService _kamarService = KamarService();

  // Filter aktif: 'Semua', 'Pending', 'Disetujui', 'Ditolak'
  String _selectedFilter = 'Semua';

  // Future daftar booking
  late Future<List<BookingModel>> _futureBooking;

  // Status proses aksi (agar mencegah double click)
  String? _processingBookingId;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _futureBooking = _kamarService.getDaftarBooking(
        statusFilter: _selectedFilter == 'Semua' ? null : _selectedFilter,
      );
    });
  }

  // Dialog konfirmasi untuk menyetujui booking
  Future<void> _konfirmasiSetujui(BookingModel booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Setujui Permohonan Sewa?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menyetujui sewa Kamar ${booking.nomorKamar ?? ''} oleh ${booking.nama}?\n\nStatus kamar akan otomatis berubah menjadi "Terisi".',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Ya, Setujui'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _processingBookingId = booking.id);
      try {
        await _kamarService.setujuiBooking(
          bookingId: booking.id,
          kamarId: booking.kamarId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sewa Kamar ${booking.nomorKamar ?? ''} berhasil disetujui! Kamar kini berstatus "Terisi".',
              ),
              backgroundColor: Colors.green.shade700,
            ),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyetujui booking: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingBookingId = null);
        }
      }
    }
  }

  // Dialog konfirmasi untuk menolak booking
  Future<void> _konfirmasiTolak(BookingModel booking) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Text(
            'Tolak Permohonan Sewa?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Tolak permohonan sewa Kamar ${booking.nomorKamar ?? ''} oleh ${booking.nama}?',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Tolak Sewa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      setState(() => _processingBookingId = booking.id);
      try {
        await _kamarService.tolakBooking(bookingId: booking.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permohonan sewa dari ${booking.nama} telah ditolak.'),
              backgroundColor: Colors.grey.shade800,
            ),
          );
          _refreshData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menolak booking: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _processingBookingId = null);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Kelola Booking Sewa',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Filter Status Bar
          _buildFilterBar(),

          // List Permohonan Booking
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshData();
                await _futureBooking;
              },
              child: FutureBuilder<List<BookingModel>>(
                future: _futureBooking,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal mengambil data booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final listBooking = snapshot.data ?? [];

                  if (listBooking.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada permohonan booking',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFilter == 'Semua'
                                    ? 'Belum ada calon penghuni yang mengajukan sewa.'
                                    : 'Tidak ada booking dengan status "$_selectedFilter".',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: listBooking.length,
                    itemBuilder: (context, index) {
                      final booking = listBooking[index];
                      return _buildBookingCard(booking);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filter Chip Bar
  Widget _buildFilterBar() {
    final filters = ['Semua', 'Pending', 'Disetujui', 'Ditolak'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                selectedColor: Colors.blue.shade100,
                checkmarkColor: Colors.blue.shade800,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedFilter = filter);
                    _refreshData();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Card Tampilan Setiap Permohonan Booking
  Widget _buildBookingCard(BookingModel booking) {
    final bool isPending = booking.isPending;
    final bool isDisetujui = booking.isDisetujui;
    final bool isDitolak = booking.isDitolak;
    final bool isBusy = _processingBookingId == booking.id;

    // Warna status badge
    Color badgeBg;
    Color badgeText;
    IconData badgeIcon;

    if (isDisetujui) {
      badgeBg = Colors.green.shade50;
      badgeText = Colors.green.shade700;
      badgeIcon = Icons.check_circle_outline;
    } else if (isDitolak) {
      badgeBg = Colors.red.shade50;
      badgeText = Colors.red.shade700;
      badgeIcon = Icons.cancel_outlined;
    } else {
      badgeBg = Colors.orange.shade50;
      badgeText = Colors.orange.shade800;
      badgeIcon = Icons.schedule;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris Atas: Nama Pemesan & Badge Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.nama,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: badgeText.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 14, color: badgeText),
                      const SizedBox(width: 4),
                      Text(
                        booking.statusLabel,
                        style: TextStyle(
                          color: badgeText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Detail Kamar, No HP, dan Tanggal Masuk
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.meeting_room_outlined,
                    label: 'Kamar',
                    value: booking.nomorKamar != null
                        ? 'Kamar ${booking.nomorKamar}'
                        : 'ID: ${booking.kamarId}',
                    isBold: true,
                  ),
                  const Divider(height: 12),
                  _buildDetailRow(
                    icon: Icons.phone_outlined,
                    label: 'No. HP',
                    value: booking.noHp,
                  ),
                  const Divider(height: 12),
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Rencana Masuk',
                    value: booking.tanggalMasukFormatted,
                  ),
                ],
              ),
            ),

            // Tombol WhatsApp ke penyewa (semua status)
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green.shade800,
                  side: BorderSide(color: Colors.green.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: () => bukaWhatsApp(
                  context,
                  nomor: booking.noHp,
                  pesan: _pesanWhatsApp(booking),
                ),
                icon: const Icon(Icons.chat_outlined, size: 18),
                label: const Text('Hubungi via WhatsApp'),
              ),
            ),

            // Tombol Aksi (Setujui / Tolak) jika status masih Pending
            if (isPending) ...[
              const SizedBox(height: 14),
              if (isBusy)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                Row(
                  children: [
                    // Tombol Tolak
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _konfirmasiTolak(booking),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Tolak'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol Setujui
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _konfirmasiSetujui(booking),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Setujui'),
                      ),
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Pesan WhatsApp otomatis sesuai status booking
  String _pesanWhatsApp(BookingModel booking) {
    final kamar = booking.nomorKamar ?? '';
    if (booking.isDisetujui) {
      return 'Halo ${booking.nama}, pengajuan sewa Kamar $kamar Anda DISETUJUI. '
          'Rencana masuk: ${booking.tanggalMasukFormatted}.';
    }
    if (booking.isDitolak) {
      return 'Halo ${booking.nama}, mohon maaf pengajuan sewa Kamar $kamar '
          'belum bisa kami setujui.';
    }
    return 'Halo ${booking.nama}, pengajuan sewa Kamar $kamar Anda sedang kami proses.';
  }

  // Row helper untuk informasi detail
  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}