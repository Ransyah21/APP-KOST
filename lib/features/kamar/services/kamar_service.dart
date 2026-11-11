// lib/features/kamar/services/kamar_service.dart

import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kamar_model.dart';
import '../models/booking_model.dart';
import '../models/pengaturan_model.dart';

class KamarService {
  // Mengambil instance Supabase Client
  final SupabaseClient _supabase = Supabase.instance.client;

  // ==========================================
  // BAGIAN 1: MANAJEMEN KAMAR (CRUD & FETCH)
  // ==========================================

  /// Mengambil semua data kamar dari tabel 'kamar'
  /// Bisa difilter berdasarkan status ('kosong' atau 'terisi')
  Future<List<KamarModel>> getDaftarKamar({String? statusFilter}) async {
    try {
      var query = _supabase.from('kamar').select();

      // Tambahkan filter status jika dipilih
      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter.toLowerCase() != 'semua') {
        query = query.eq('status', statusFilter.toLowerCase());
      }

      // Urutkan berdasarkan nomor kamar secara ascending
      final response = await query.order('nomor', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => KamarModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar kamar: $e');
    }
  }

  /// Mendengarkan perubahan data secara realtime
  Stream<List<KamarModel>> streamDaftarKamar() {
    return _supabase
        .from('kamar')
        .stream(primaryKey: ['id'])
        .order('nomor', ascending: true)
        .map((data) => data.map((json) => KamarModel.fromJson(json)).toList());
  }

  /// Mengambil detail satu kamar berdasarkan ID
  Future<KamarModel?> getDetailKamar(String id) async {
    try {
      final response = await _supabase
          .from('kamar')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return KamarModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal memuat detail kamar: $e');
    }
  }

  /// Upload satu foto kamar ke Supabase Storage bucket 'foto-kamar'
  /// Menggunakan bytes (Uint8List) sehingga kompatibel untuk Web, Android, & iOS
  Future<String> uploadFotoKamar({
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'kamar_${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      await _supabase.storage.from('foto-kamar').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType ?? 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage.from('foto-kamar').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload foto kamar: $e');
    }
  }

  /// Upload banyak foto kamar sekaligus ke Supabase Storage (bucket 'foto-kamar')
  Future<List<String>> uploadBanyakFotoKamar({
    required List<Uint8List> listBytes,
    required List<String> listFileNames,
  }) async {
    try {
      List<String> uploadedUrls = [];
      for (int i = 0; i < listBytes.length; i++) {
        final bytes = listBytes[i];
        final name = i < listFileNames.length ? listFileNames[i] : 'foto_$i.jpg';
        final url = await uploadFotoKamar(bytes: bytes, fileName: name);
        uploadedUrls.add(url);
      }
      return uploadedUrls;
    } catch (e) {
      throw Exception('Gagal upload banyak foto kamar: $e');
    }
  }

  /// Upload foto denah ruangan ke bucket 'foto-kamar' dengan prefix 'denah_'
  Future<String> uploadDenahKamar({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final cleanName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = 'denah_${DateTime.now().millisecondsSinceEpoch}_$cleanName';

      await _supabase.storage.from('foto-kamar').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage.from('foto-kamar').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      throw Exception('Gagal upload denah ruangan: $e');
    }
  }

  /// Menambah data kamar baru ke tabel 'kamar'
  /// Menyimpan foto_urls, denah_url, dan foto_url (foto sampul = foto pertama)
  /// Fasilitas disimpan sebagai String join(', ')
  Future<KamarModel> tambahKamar({
    required String nomor,
    required int harga,
    String? deskripsi,
    List<String> fasilitas = const [],
    List<String> fotoUrls = const [],
    String? denahUrl,
    String status = 'kosong',
  }) async {
    try {
      final String? fotoSampul = fotoUrls.isNotEmpty ? fotoUrls.first : null;

      final payload = {
        'nomor': nomor.trim(),
        'harga': harga,
        'deskripsi': deskripsi?.trim(),
        'fasilitas': fasilitas.join(', '),
        'foto_url': fotoSampul,
        'foto_urls': fotoUrls,
        'denah_url': denahUrl,
        'status': status.toLowerCase(),
      };

      final response =
          await _supabase.from('kamar').insert(payload).select().single();

      return KamarModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal menambah kamar baru: $e');
    }
  }

  /// Memperbarui (edit) data kamar yang sudah ada
  Future<KamarModel> updateKamar({
    required String id,
    required String nomor,
    required int harga,
    String? deskripsi,
    List<String> fasilitas = const [],
    List<String> fotoUrls = const [],
    String? denahUrl,
    required String status,
  }) async {
    try {
      final String? fotoSampul = fotoUrls.isNotEmpty ? fotoUrls.first : null;

      final payload = {
        'nomor': nomor.trim(),
        'harga': harga,
        'deskripsi': deskripsi?.trim(),
        'fasilitas': fasilitas.join(', '),
        'foto_url': fotoSampul,
        'foto_urls': fotoUrls,
        'denah_url': denahUrl,
        'status': status.toLowerCase(),
      };

      final response = await _supabase
          .from('kamar')
          .update(payload)
          .eq('id', id)
          .select()
          .single();

      return KamarModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal memperbarui kamar: $e');
    }
  }

  /// Menghapus data kamar berdasarkan ID
  Future<void> hapusKamar(String id) async {
    try {
      await _supabase.from('kamar').delete().eq('id', id);
    } catch (e) {
      throw Exception('Gagal menghapus kamar: $e');
    }
  }

  // ==========================================
  // BAGIAN 2: MANAJEMEN BOOKING SEWA
  // ==========================================

  /// Mengajukan sewa kamar (penghuni) ke tabel 'booking'
  /// Default status adalah 'pending'
  Future<BookingModel> ajukanSewa({
    required String kamarId,
    String? userId,
    required String nama,
    required String noHp,
    required DateTime tanggalMasuk,
  }) async {
    try {
      final payload = {
        'kamar_id': kamarId,
        'user_id': userId, // null sementara sampai modul autentikasi siap
        'nama': nama.trim(),
        'no_hp': noHp.trim(),
        'tanggal_masuk': tanggalMasuk.toIso8601String().split('T').first,
        'status': 'pending',
      };

      final response = await _supabase
          .from('booking')
          .insert(payload)
          .select('*, kamar(nomor)')
          .single();

      return BookingModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Gagal mengajukan sewa kamar: $e');
    }
  }

  /// Mengambil daftar permohonan booking untuk owner
  /// Bisa difilter berdasarkan status ('pending', 'disetujui', 'ditolak', 'semua')
  Future<List<BookingModel>> getDaftarBooking({String? statusFilter}) async {
    try {
      var query = _supabase.from('booking').select('*, kamar(nomor)');

      if (statusFilter != null &&
          statusFilter.isNotEmpty &&
          statusFilter.toLowerCase() != 'semua') {
        query = query.eq('status', statusFilter.toLowerCase());
      }

      // Urutkan permohonan booking terbaru di atas
      final response = await query.order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data
          .map((json) => BookingModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar booking: $e');
    }
  }

  /// Menyetujui booking oleh owner:
  /// 1. Ubah status booking menjadi 'disetujui'
  /// 2. Otomatis ubah status kamar terkait menjadi 'terisi'
  Future<void> setujuiBooking({
    required String bookingId,
    required String kamarId,
  }) async {
    try {
      await _supabase
          .from('booking')
          .update({'status': 'disetujui'}).eq('id', bookingId);

      await _supabase.from('kamar').update({'status': 'terisi'}).eq('id', kamarId);
    } catch (e) {
      throw Exception('Gagal menyetujui booking: $e');
    }
  }

  /// Menolak booking oleh owner: ubah status booking menjadi 'ditolak'
  Future<void> tolakBooking({required String bookingId}) async {
    try {
      await _supabase
          .from('booking')
          .update({'status': 'ditolak'}).eq('id', bookingId);
    } catch (e) {
      throw Exception('Gagal menolak booking: $e');
    }
  }

  // ==========================================
  // BAGIAN 3: PENGATURAN / INFO KOS
  // ==========================================

  /// Mengambil info kos (baris id = 1), bisa null jika belum ada
  Future<PengaturanKos?> getPengaturanKos() async {
    try {
      final response = await _supabase
          .from('pengaturan_kos')
          .select()
          .eq('id', 1)
          .maybeSingle();

      if (response == null) return null;
      return PengaturanKos.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat info kos: $e');
    }
  }

  /// Menyimpan info kos. Selalu menulis ke baris id = 1
  /// (parameter id diterima agar cocok dengan pemanggilan di halaman, tapi diabaikan).
  /// Memakai upsert, jadi tetap aman walau barisnya belum ada.
  Future<void> simpanPengaturanKos({
    Object? id,
    String? namaKos,
    String? namaOwner,
    String? noWa,
    String? alamat,
    String? patokan,
    String? bank,
    String? noRekening,
    String? atasNama,
  }) async {
    try {
      // Teks kosong disimpan sebagai null
      String? bersih(String? v) {
        final t = v?.trim();
        return (t == null || t.isEmpty) ? null : t;
      }

      await _supabase.from('pengaturan_kos').upsert({
        'id': 1,
        'nama_kos': bersih(namaKos),
        'nama_owner': bersih(namaOwner),
        'no_wa': bersih(noWa),
        'alamat': bersih(alamat),
        'patokan': bersih(patokan),
        'bank': bersih(bank),
        'no_rekening': bersih(noRekening),
        'atas_nama': bersih(atasNama),
      });
    } catch (e) {
      throw Exception('Gagal menyimpan info kos: $e');
    }
  }
}