import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import 'tagihan_repository.dart';

/// Versi yang disesuaikan dengan database tim:
/// - tabel booking (nama, no_hp, status) dan kamar (nomor, harga)
/// - TIDAK butuh login / RPC, semua lewat query biasa
class SupabaseTagihanRepository implements TagihanRepository {
  /// [sebagaiPenghuni]: null = owner (lihat semua tagihan).
  /// Isi dengan nama penghuni (sama persis dengan booking.nama)
  /// kalau ingin hanya menampilkan tagihan miliknya.
  /// Nanti kalau login sudah jadi, filter ini bisa diganti pakai user_id.
  SupabaseTagihanRepository(this._db, {this.sebagaiPenghuni});

  final SupabaseClient _db;
  final String? sebagaiPenghuni;

  static const _bucket = 'bukti-bayar';

  @override
  Future<List<Bill>> daftarTagihan() async {
    final rows = await _db
        .from('bills')
        .select('*, booking(nama, kamar(nomor))')
        .order('periode_tahun', ascending: false)
        .order('periode_bulan', ascending: false);

    var list =
        (rows as List).map((r) => Bill.fromMap(r as Map<String, dynamic>)).toList();

    final nama = sebagaiPenghuni?.trim().toLowerCase();
    if (nama != null && nama.isNotEmpty) {
      list = list.where((b) => b.namaPenghuni.trim().toLowerCase() == nama).toList();
    }
    return list;
  }

  @override
  Future<List<BookingOption>> daftarBookingAktif() async {
    final rows = await _db
        .from('booking')
        .select('id, nama, kamar(nomor, harga)')
        .eq('status', 'disetujui');

    return (rows as List).map((r) {
      final m = r as Map<String, dynamic>;
      final kamar = m['kamar'] as Map<String, dynamic>?;
      return BookingOption(
        id: m['id'] as String,
        namaPenghuni: (m['nama'] as String?) ?? '-',
        nomorKamar: (kamar?['nomor'] as String?) ?? '-',
        hargaBulanan: ((kamar?['harga'] as num?) ?? 0).toDouble(),
      );
    }).toList();
  }

  @override
  Future<void> buatTagihan({
    required String bookingId,
    required int bulan,
    required int tahun,
    required double jumlah,
    required DateTime jatuhTempo,
  }) async {
    try {
      await _db.from('bills').insert({
        'booking_id': bookingId,
        'periode_bulan': bulan,
        'periode_tahun': tahun,
        'jumlah': jumlah,
        'jatuh_tempo': jatuhTempo.toIso8601String().substring(0, 10),
        'status': 'belum_bayar',
      });
    } on PostgrestException catch (e) {
      // 23505 = unique violation (tagihan periode itu sudah ada)
      if (e.code == '23505') {
        throw Exception('Tagihan periode ini untuk penghuni tersebut sudah ada');
      }
      rethrow;
    }
  }

  @override
  Future<void> uploadBukti({
    required String billId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    var ext = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    if (!['jpg', 'jpeg', 'png', 'webp'].contains(ext)) ext = 'jpg';
    final mime = ext == 'jpg' ? 'jpeg' : ext;
    final path = '${billId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

    // 1. Upload gambar ke Storage
    await _db.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$mime'),
        );

    // 2. Catat pembayaran (menunggu verifikasi owner)
    await _db.from('payments').insert({
      'bill_id': billId,
      'bukti_url': path,
      'status': 'menunggu',
    });

    // 3. Ubah status tagihan
    await _db.from('bills').update({'status': 'menunggu_verifikasi'}).eq('id', billId);
  }

  @override
  Future<Payment?> pembayaranTerakhir(String billId) async {
    final rows = await _db
        .from('payments')
        .select()
        .eq('bill_id', billId)
        .order('tanggal_bayar', ascending: false)
        .limit(1);
    final list = rows as List;
    return list.isEmpty ? null : Payment.fromMap(list.first as Map<String, dynamic>);
  }

  @override
  Future<Uint8List?> unduhBukti(String path) => _db.storage.from(_bucket).download(path);

  @override
  Future<void> verifikasi({required String paymentId, required bool terima}) async {
    final p = await _db.from('payments').select().eq('id', paymentId).maybeSingle();
    if (p == null || p['status'] != 'menunggu') {
      throw Exception('Pembayaran tidak ditemukan / sudah diproses');
    }

    // Terima -> payment diterima, tagihan lunas
    // Tolak  -> payment ditolak, tagihan kembali belum_bayar
    await _db
        .from('payments')
        .update({'status': terima ? 'diterima' : 'ditolak'}).eq('id', paymentId);
    await _db
        .from('bills')
        .update({'status': terima ? 'lunas' : 'belum_bayar'}).eq('id', p['bill_id']);
  }
}