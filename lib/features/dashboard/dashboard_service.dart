import 'package:supabase_flutter/supabase_flutter.dart';

num _n(dynamic v) => v is num ? v : (num.tryParse('${v ?? 0}') ?? 0);
int _i(dynamic v) => _n(v).toInt();
double _d(dynamic v) => _n(v).toDouble();
Map<String, dynamic>? _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : null;

// ======================= OWNER =======================

class PemasukanBulanan {
  const PemasukanBulanan(this.bulan, this.tahun, this.total);
  final int bulan;
  final int tahun;
  final double total;
}

class OwnerDashboardData {
  const OwnerDashboardData({
    required this.kamarTotal,
    required this.kamarTerisi,
    required this.bookingPending,
    required this.tagihanBelumBayar,
    required this.tagihanMenunggu,
    required this.tagihanTerlambat,
    required this.totalTunggakan,
    required this.pemasukanBulanIni,
    required this.tagihanBulanIni,
    required this.keluhanPending,
    required this.keluhanProses,
    required this.grafik,
  });

  final int kamarTotal, kamarTerisi, bookingPending;
  final int tagihanBelumBayar, tagihanMenunggu, tagihanTerlambat;
  final int keluhanPending, keluhanProses;
  final double totalTunggakan, pemasukanBulanIni, tagihanBulanIni;
  final List<PemasukanBulanan> grafik;

  int get kamarKosong => kamarTotal - kamarTerisi;
  double get okupansi => kamarTotal == 0 ? 0 : kamarTerisi / kamarTotal;

  factory OwnerDashboardData.fromMap(Map<String, dynamic> m) {
    return OwnerDashboardData(
      kamarTotal: _i(m['kamar_total']),
      kamarTerisi: _i(m['kamar_terisi']),
      bookingPending: _i(m['booking_pending']),
      tagihanBelumBayar: _i(m['tagihan_belum_bayar']),
      tagihanMenunggu: _i(m['tagihan_menunggu']),
      tagihanTerlambat: _i(m['tagihan_terlambat']),
      totalTunggakan: _d(m['total_tunggakan']),
      pemasukanBulanIni: _d(m['pemasukan_bulan_ini']),
      tagihanBulanIni: _d(m['tagihan_bulan_ini']),
      keluhanPending: _i(m['keluhan_pending']),
      keluhanProses: _i(m['keluhan_proses']),
      grafik: [
        for (final g in (m['grafik'] as List? ?? const []))
          PemasukanBulanan(_i(g['bulan']), _i(g['tahun']), _d(g['total'])),
      ],
    );
  }
}

// ======================= PENGHUNI =======================

class KamarAktif {
  const KamarAktif({
    required this.nomor,
    required this.harga,
    required this.namaBooking,
    this.tanggalMasuk,
  });
  final String nomor;
  final double harga;
  final String namaBooking; // sama persis dengan booking.nama (dipakai modul tagihan)
  final DateTime? tanggalMasuk;
}

class TagihanTerdekat {
  const TagihanTerdekat(this.jumlah, this.jatuhTempo, this.bulan, this.tahun);
  final double jumlah;
  final DateTime? jatuhTempo;
  final int bulan, tahun;
}

class PenghuniDashboardData {
  const PenghuniDashboardData({
    this.kamarAktif,
    this.pendingNomor,
    this.belumBayar = 0,
    this.menunggu = 0,
    this.lunas = 0,
    this.terlambat = 0,
    this.totalBelumBayar = 0,
    this.terdekat,
    this.keluhanPending = 0,
    this.keluhanProses = 0,
    this.keluhanSelesai = 0,
    this.namaKos,
    this.noWa,
    this.bank,
    this.noRekening,
    this.atasNama,
  });

  final KamarAktif? kamarAktif;
  final String? pendingNomor; // nomor kamar yang sedang diajukan
  final int belumBayar, menunggu, lunas, terlambat;
  final double totalBelumBayar;
  final TagihanTerdekat? terdekat;
  final int keluhanPending, keluhanProses, keluhanSelesai;
  final String? namaKos, noWa, bank, noRekening, atasNama;

  bool get adaTagihan => belumBayar + menunggu + lunas > 0;

  factory PenghuniDashboardData.fromMap(Map<String, dynamic> m) {
    final aktif = _map(m['kamar_aktif']);
    final pending = _map(m['booking_pending']);
    final tagihan = _map(m['tagihan']) ?? const <String, dynamic>{};
    final dekat = _map(tagihan['terdekat']);
    final keluhan = _map(m['keluhan']) ?? const <String, dynamic>{};
    final kos = _map(m['kos']) ?? const <String, dynamic>{};

    return PenghuniDashboardData(
      kamarAktif: aktif == null
          ? null
          : KamarAktif(
              nomor: '${aktif['nomor'] ?? '-'}',
              harga: _d(aktif['harga']),
              namaBooking: '${aktif['nama'] ?? ''}',
              tanggalMasuk: DateTime.tryParse('${aktif['tanggal_masuk']}'),
            ),
      pendingNomor: pending == null ? null : '${pending['nomor'] ?? '-'}',
      belumBayar: _i(tagihan['belum_bayar']),
      menunggu: _i(tagihan['menunggu']),
      lunas: _i(tagihan['lunas']),
      terlambat: _i(tagihan['terlambat']),
      totalBelumBayar: _d(tagihan['total_belum_bayar']),
      terdekat: dekat == null
          ? null
          : TagihanTerdekat(
              _d(dekat['jumlah']),
              DateTime.tryParse('${dekat['jatuh_tempo']}'),
              _i(dekat['periode_bulan']),
              _i(dekat['periode_tahun']),
            ),
      keluhanPending: _i(keluhan['pending']),
      keluhanProses: _i(keluhan['proses']),
      keluhanSelesai: _i(keluhan['selesai']),
      namaKos: kos['nama_kos'] as String?,
      noWa: kos['no_wa'] as String?,
      bank: kos['bank'] as String?,
      noRekening: kos['no_rekening'] as String?,
      atasNama: kos['atas_nama'] as String?,
    );
  }
}

// ======================= SERVICE =======================
// Semua data diambil langsung dari tabel Supabase (tanpa SQL/RPC),
// lalu dihitung di sini.

class DashboardService {
  DashboardService([SupabaseClient? client])
      : _db = client ?? Supabase.instance.client;

  final SupabaseClient _db;

  static DateTime get _hariIni {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// Status semua keluhan (opsional per penghuni). Kalau tabel
  /// `complaints` belum ada / error, dianggap kosong supaya dashboard tetap jalan.
  Future<List<String>> _statusKeluhan({String? penghuniId}) async {
    try {
      var q = _db.from('complaints').select('status');
      if (penghuniId != null) q = q.eq('penghuni_id', penghuniId);
      final rows = await q;
      return [for (final r in rows) '${r['status']}'];
    } catch (_) {
      return const [];
    }
  }

  // ----------------------- OWNER -----------------------
  Future<OwnerDashboardData> owner() async {
    final today = _hariIni;

    final kamar = await _db.from('kamar').select('status');
    final pending = await _db.from('booking').select('id').eq('status', 'pending');
    final bills = await _db
        .from('bills')
        .select('jumlah, jatuh_tempo, status, periode_bulan, periode_tahun');
    final keluhan = await _statusKeluhan();

    var belum = 0, menunggu = 0, telat = 0;
    double tunggakan = 0, pemasukan = 0, tagihanBulanIni = 0;
    final perBulan = <int, double>{}; // key: tahun*100+bulan

    for (final b in bills) {
      final st = '${b['status']}';
      final jml = _d(b['jumlah']);
      final bln = _i(b['periode_bulan']);
      final thn = _i(b['periode_tahun']);
      final jt = DateTime.tryParse('${b['jatuh_tempo']}');

      if (st == 'belum_bayar') belum++;
      if (st == 'menunggu_verifikasi') menunggu++;
      if (st == 'belum_bayar' && jt != null && jt.isBefore(today)) {
        telat++;
        tunggakan += jml;
      }
      if (bln == today.month && thn == today.year) {
        tagihanBulanIni += jml;
        if (st == 'lunas') pemasukan += jml;
      }
      if (st == 'lunas') {
        final key = thn * 100 + bln;
        perBulan[key] = (perBulan[key] ?? 0) + jml;
      }
    }

    final grafik = <PemasukanBulanan>[];
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(today.year, today.month - i);
      grafik.add(PemasukanBulanan(
        d.month,
        d.year,
        perBulan[d.year * 100 + d.month] ?? 0,
      ));
    }

    return OwnerDashboardData(
      kamarTotal: kamar.length,
      kamarTerisi:
          kamar.where((r) => '${r['status']}'.toLowerCase() == 'terisi').length,
      bookingPending: pending.length,
      tagihanBelumBayar: belum,
      tagihanMenunggu: menunggu,
      tagihanTerlambat: telat,
      totalTunggakan: tunggakan,
      pemasukanBulanIni: pemasukan,
      tagihanBulanIni: tagihanBulanIni,
      keluhanPending: keluhan.where((s) => s == 'pending').length,
      keluhanProses: keluhan.where((s) => s == 'proses').length,
      grafik: grafik,
    );
  }

  // ----------------------- PENGHUNI -----------------------
  Future<PenghuniDashboardData> penghuni() async {
    final uid = _db.auth.currentUser?.id;
    if (uid == null) throw Exception('Belum login');
    final today = _hariIni;

    // Semua booking milik akun ini (ditautkan lewat booking.user_id)
    final bookings = await _db
        .from('booking')
        .select('id, nama, tanggal_masuk, status, kamar(nomor, harga)')
        .eq('user_id', uid)
        .order('created_at', ascending: false);

    Map<String, dynamic>? cari(String status) {
      for (final b in bookings) {
        if ('${b['status']}'.toLowerCase() == status) return b;
      }
      return null;
    }

    final aktif = cari('disetujui');
    final pend = cari('pending');
    final kamarAktif = _map(aktif?['kamar']);
    final kamarPend = _map(pend?['kamar']);

    // Tagihan dari semua booking milik akun ini
    final ids = [for (final b in bookings) '${b['id']}'];
    final bills = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('bills')
            .select('jumlah, jatuh_tempo, status, periode_bulan, periode_tahun')
            .inFilter('booking_id', ids);

    var belum = 0, menunggu = 0, lunas = 0, telat = 0;
    double totalBelum = 0;
    Map<String, dynamic>? terdekat;
    DateTime? terdekatTgl;

    for (final b in bills) {
      final st = '${b['status']}';
      final jt = DateTime.tryParse('${b['jatuh_tempo']}');
      if (st == 'lunas') lunas++;
      if (st == 'menunggu_verifikasi') menunggu++;
      if (st == 'belum_bayar') {
        belum++;
        totalBelum += _d(b['jumlah']);
        if (jt != null && jt.isBefore(today)) telat++;
        if (jt != null && (terdekatTgl == null || jt.isBefore(terdekatTgl))) {
          terdekatTgl = jt;
          terdekat = b;
        }
      }
    }

    final keluhan = await _statusKeluhan(penghuniId: uid);

    Map<String, dynamic>? kos;
    try {
      kos = await _db.from('pengaturan_kos').select().eq('id', 1).maybeSingle();
    } catch (_) {
      kos = null;
    }

    return PenghuniDashboardData(
      kamarAktif: aktif == null
          ? null
          : KamarAktif(
              nomor: '${kamarAktif?['nomor'] ?? '-'}',
              harga: _d(kamarAktif?['harga']),
              namaBooking: '${aktif['nama'] ?? ''}',
              tanggalMasuk: DateTime.tryParse('${aktif['tanggal_masuk']}'),
            ),
      pendingNomor: pend == null ? null : '${kamarPend?['nomor'] ?? '-'}',
      belumBayar: belum,
      menunggu: menunggu,
      lunas: lunas,
      terlambat: telat,
      totalBelumBayar: totalBelum,
      terdekat: terdekat == null
          ? null
          : TagihanTerdekat(
              _d(terdekat['jumlah']),
              terdekatTgl,
              _i(terdekat['periode_bulan']),
              _i(terdekat['periode_tahun']),
            ),
      keluhanPending: keluhan.where((s) => s == 'pending').length,
      keluhanProses: keluhan.where((s) => s == 'proses').length,
      keluhanSelesai: keluhan.where((s) => s == 'selesai').length,
      namaKos: kos?['nama_kos'] as String?,
      noWa: kos?['no_wa'] as String?,
      bank: kos?['bank'] as String?,
      noRekening: kos?['no_rekening'] as String?,
      atasNama: kos?['atas_nama'] as String?,
    );
  }

  /// Pesan error yang bisa dipahami pengguna.
  static String pesanError(Object e) {
    if (e is PostgrestException) return 'Gagal memuat data: ${e.message}';
    return 'Gagal memuat dashboard. Periksa koneksi internet, lalu coba lagi.';
  }
}