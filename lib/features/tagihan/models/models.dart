enum BillStatus { belumBayar, menungguVerifikasi, lunas }

extension BillStatusX on BillStatus {
  String get db => switch (this) {
        BillStatus.belumBayar => 'belum_bayar',
        BillStatus.menungguVerifikasi => 'menunggu_verifikasi',
        BillStatus.lunas => 'lunas',
      };

  String get label => switch (this) {
        BillStatus.belumBayar => 'Belum bayar',
        BillStatus.menungguVerifikasi => 'Menunggu verifikasi',
        BillStatus.lunas => 'Lunas',
      };

  static BillStatus fromDb(String s) =>
      BillStatus.values.firstWhere((e) => e.db == s, orElse: () => BillStatus.belumBayar);
}

class Bill {
  final String id;
  final String bookingId;
  final int bulan;
  final int tahun;
  final double jumlah;
  final DateTime jatuhTempo;
  final BillStatus status;
  final String namaPenghuni; // hasil join bills -> booking(nama)
  final String nomorKamar; // hasil join booking -> kamar(nomor)

  const Bill({
    required this.id,
    required this.bookingId,
    required this.bulan,
    required this.tahun,
    required this.jumlah,
    required this.jatuhTempo,
    required this.status,
    this.namaPenghuni = '-',
    this.nomorKamar = '-',
  });

  bool get terlambat =>
      status == BillStatus.belumBayar &&
      jatuhTempo.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  Bill copyWith({BillStatus? status}) => Bill(
        id: id,
        bookingId: bookingId,
        bulan: bulan,
        tahun: tahun,
        jumlah: jumlah,
        jatuhTempo: jatuhTempo,
        status: status ?? this.status,
        namaPenghuni: namaPenghuni,
        nomorKamar: nomorKamar,
      );

  /// Membaca baris dari: bills.select('*, booking(nama, kamar(nomor))')
  factory Bill.fromMap(Map<String, dynamic> m) {
    final booking = m['booking'] as Map<String, dynamic>?;
    final kamar = booking?['kamar'] as Map<String, dynamic>?;
    return Bill(
      id: m['id'] as String,
      bookingId: m['booking_id'] as String,
      bulan: m['periode_bulan'] as int,
      tahun: m['periode_tahun'] as int,
      jumlah: (m['jumlah'] as num).toDouble(),
      jatuhTempo: DateTime.parse(m['jatuh_tempo'] as String),
      status: BillStatusX.fromDb(m['status'] as String),
      namaPenghuni: (booking?['nama'] as String?) ?? '-',
      nomorKamar: (kamar?['nomor'] as String?) ?? '-',
    );
  }
}

class Payment {
  final String id;
  final String billId;
  final String? buktiPath;
  final String status; // menunggu | diterima | ditolak
  final DateTime tanggalBayar;

  const Payment({
    required this.id,
    required this.billId,
    required this.buktiPath,
    required this.status,
    required this.tanggalBayar,
  });

  factory Payment.fromMap(Map<String, dynamic> m) => Payment(
        id: m['id'] as String,
        billId: m['bill_id'] as String,
        buktiPath: m['bukti_url'] as String?,
        status: m['status'] as String,
        tanggalBayar: DateTime.parse(m['tanggal_bayar'] as String),
      );
}

/// Pilihan booking aktif (disetujui) untuk form "Buat tagihan".
class BookingOption {
  final String id;
  final String namaPenghuni;
  final String nomorKamar;
  final double hargaBulanan;

  const BookingOption({
    required this.id,
    required this.namaPenghuni,
    required this.nomorKamar,
    required this.hargaBulanan,
  });

  String get label => '$namaPenghuni — Kamar $nomorKamar';
}