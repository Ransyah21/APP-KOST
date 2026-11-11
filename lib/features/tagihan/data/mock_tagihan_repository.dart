import 'dart:typed_data';
import '../models/models.dart';
import 'tagihan_repository.dart';

/// Data palsu di memori, supaya modul ini bisa dijalankan & didemokan
/// SENDIRIAN tanpa menunggu modul 1 & 2 atau Supabase.
class _MockData {
  final bills = <Bill>[
    Bill(id: 'b1', bookingId: 'k1', bulan: 11, tahun: 2026, jumlah: 1200000,
        jatuhTempo: DateTime(2026, 11, 5), status: BillStatus.belumBayar,
        namaPenghuni: 'Budi', nomorKamar: 'A1'),
    Bill(id: 'b2', bookingId: 'k1', bulan: 10, tahun: 2026, jumlah: 1200000,
        jatuhTempo: DateTime(2026, 10, 5), status: BillStatus.menungguVerifikasi,
        namaPenghuni: 'Budi', nomorKamar: 'A1'),
    Bill(id: 'b3', bookingId: 'k1', bulan: 9, tahun: 2026, jumlah: 1200000,
        jatuhTempo: DateTime(2026, 9, 5), status: BillStatus.lunas,
        namaPenghuni: 'Budi', nomorKamar: 'A1'),
    Bill(id: 'b4', bookingId: 'k2', bulan: 11, tahun: 2026, jumlah: 1500000,
        jatuhTempo: DateTime(2026, 11, 10), status: BillStatus.belumBayar,
        namaPenghuni: 'Sari', nomorKamar: 'B2'),
  ];
  final payments = <Payment>[
    Payment(id: 'p2', billId: 'b2', buktiPath: 'mock/p2', status: 'menunggu',
        tanggalBayar: DateTime(2026, 10, 6)),
  ];
  final files = <String, Uint8List>{};
  int seq = 100;
}

final _data = _MockData();

class MockTagihanRepository implements TagihanRepository {
  /// null = owner (lihat semua). Isi nama = penghuni (hanya tagihan miliknya).
  MockTagihanRepository({this.sebagaiPenghuni});
  final String? sebagaiPenghuni;

  Future<void> _delay() => Future.delayed(const Duration(milliseconds: 300));

  @override
  Future<List<Bill>> daftarTagihan() async {
    await _delay();
    final list = _data.bills
        .where((b) => sebagaiPenghuni == null || b.namaPenghuni == sebagaiPenghuni)
        .toList()
      ..sort((a, b) => (b.tahun * 100 + b.bulan).compareTo(a.tahun * 100 + a.bulan));
    return list;
  }

  @override
  Future<List<BookingOption>> daftarBookingAktif() async => const [
        BookingOption(id: 'k1', namaPenghuni: 'Budi', nomorKamar: 'A1', hargaBulanan: 1200000),
        BookingOption(id: 'k2', namaPenghuni: 'Sari', nomorKamar: 'B2', hargaBulanan: 1500000),
      ];

  @override
  Future<void> buatTagihan({
    required String bookingId,
    required int bulan,
    required int tahun,
    required double jumlah,
    required DateTime jatuhTempo,
  }) async {
    await _delay();
    if (_data.bills.any((b) => b.bookingId == bookingId && b.bulan == bulan && b.tahun == tahun)) {
      throw Exception('Tagihan periode ini untuk penghuni tersebut sudah ada');
    }
    final opt = (await daftarBookingAktif()).firstWhere((o) => o.id == bookingId);
    _data.bills.add(Bill(
      id: 'b${_data.seq++}', bookingId: bookingId, bulan: bulan, tahun: tahun,
      jumlah: jumlah, jatuhTempo: jatuhTempo, status: BillStatus.belumBayar,
      namaPenghuni: opt.namaPenghuni, nomorKamar: opt.nomorKamar,
    ));
  }

  @override
  Future<void> uploadBukti({
    required String billId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    await _delay();
    final id = 'p${_data.seq++}';
    _data.files['mock/$id'] = bytes;
    _data.payments.add(Payment(
        id: id, billId: billId, buktiPath: 'mock/$id', status: 'menunggu',
        tanggalBayar: DateTime.now()));
    _setStatus(billId, BillStatus.menungguVerifikasi);
  }

  @override
  Future<Payment?> pembayaranTerakhir(String billId) async {
    await _delay();
    final list = _data.payments.where((p) => p.billId == billId).toList()
      ..sort((a, b) => b.tanggalBayar.compareTo(a.tanggalBayar));
    return list.isEmpty ? null : list.first;
  }

  @override
  Future<Uint8List?> unduhBukti(String path) async => _data.files[path];

  @override
  Future<void> verifikasi({required String paymentId, required bool terima}) async {
    await _delay();
    final i = _data.payments.indexWhere((p) => p.id == paymentId);
    if (i < 0 || _data.payments[i].status != 'menunggu') {
      throw Exception('Pembayaran tidak ditemukan / sudah diproses');
    }
    final p = _data.payments[i];
    _data.payments[i] = Payment(
        id: p.id, billId: p.billId, buktiPath: p.buktiPath,
        status: terima ? 'diterima' : 'ditolak', tanggalBayar: p.tanggalBayar);
    _setStatus(p.billId, terima ? BillStatus.lunas : BillStatus.belumBayar);
  }

  void _setStatus(String billId, BillStatus s) {
    final i = _data.bills.indexWhere((b) => b.id == billId);
    _data.bills[i] = _data.bills[i].copyWith(status: s);
  }
}
