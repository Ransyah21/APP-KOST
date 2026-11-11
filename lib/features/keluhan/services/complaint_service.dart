import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/complaint.dart';

/// Semua akses data modul Keluhan (tabel `complaints`).
/// Hak akses sebenarnya dijaga oleh RLS di Supabase, bukan oleh kode ini.
class ComplaintService {
  ComplaintService([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  String get _uid {
    final user = _db.auth.currentUser;
    if (user == null) throw Exception('Belum login');
    return user.id;
  }

  /// Kamar aktif penghuni (booking berstatus `disetujui`), untuk mengisi
  /// room_id otomatis. Mengembalikan null jika modul 2 belum ada / belum
  /// ada booking, sehingga keluhan tetap bisa dikirim.
  Future<String?> findActiveRoomId() async {
    try {
      final row = await _db
          .from('bookings')
          .select('room_id')
          .eq('penghuni_id', _uid)
          .eq('status', 'disetujui')
          .limit(1)
          .maybeSingle();
      return row?['room_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Penghuni mengirim keluhan baru (status otomatis `pending`).
  Future<void> kirimKeluhan({
    required String judul,
    required String isi,
    String? roomId,
  }) async {
    await _db.from('complaints').insert({
      'penghuni_id': _uid,
      'room_id': roomId,
      'judul': judul,
      'isi': isi,
      'status': ComplaintStatus.pending.name,
    });
  }

  /// Keluhan milik penghuni yang sedang login.
  Future<List<Complaint>> keluhanSaya() => _ambil(penghuniId: _uid);

  /// Semua keluhan (untuk owner; RLS membatasi penghuni ke miliknya sendiri).
  Future<List<Complaint>> semuaKeluhan() => _ambil();

  /// Owner mengubah status keluhan.
  Future<void> ubahStatus(String id, ComplaintStatus status) async {
    final res = await _db
        .from('complaints')
        .update({'status': status.name})
        .eq('id', id)
        .select('id');
    // RLS menolak dengan diam-diam (0 baris), jadi dicek manual.
    if (res.isEmpty) {
      throw Exception('Status tidak berubah. Pastikan login sebagai owner.');
    }
  }

  Future<List<Complaint>> _ambil({String? penghuniId}) async {
    Future<List<Map<String, dynamic>>> query(String kolom) {
      var req = _db.from('complaints').select(kolom);
      if (penghuniId != null) req = req.eq('penghuni_id', penghuniId);
      return req.order('created_at', ascending: false);
    }

    List<Map<String, dynamic>> rows;
    try {
      rows = await query('*, users(nama), rooms(nomor_kamar)');
    } on PostgrestException {
      // Tabel rooms (modul 2) belum ada / belum ter-relasi: tanpa nomor kamar.
      rows = await query('*, users(nama)');
    }
    return rows.map(Complaint.fromMap).toList();
  }
}
