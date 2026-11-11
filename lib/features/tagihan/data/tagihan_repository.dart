import 'dart:typed_data';
import '../models/models.dart';

/// Kontrak data modul Tagihan. UI hanya bicara ke interface ini,
/// jadi bisa jalan dengan Supabase (asli) atau Mock (demo tanpa backend).
abstract class TagihanRepository {
  /// Owner: semua tagihan. Penghuni: hanya miliknya (dijaga RLS).
  Future<List<Bill>> daftarTagihan();

  /// Owner: booking berstatus 'disetujui' untuk dipilih saat buat tagihan.
  Future<List<BookingOption>> daftarBookingAktif();

  Future<void> buatTagihan({
    required String bookingId,
    required int bulan,
    required int tahun,
    required double jumlah,
    required DateTime jatuhTempo,
  });

  /// Penghuni: upload foto bukti -> payment 'menunggu', bill 'menunggu_verifikasi'.
  Future<void> uploadBukti({
    required String billId,
    required Uint8List bytes,
    required String fileName,
  });

  Future<Payment?> pembayaranTerakhir(String billId);

  Future<Uint8List?> unduhBukti(String path);

  /// Owner: terima -> bill 'lunas'; tolak -> bill kembali 'belum_bayar'.
  Future<void> verifikasi({required String paymentId, required bool terima});
}
