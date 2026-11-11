// lib/features/kamar/models/booking_model.dart

class BookingModel {
  final String id;
  final String kamarId;
  final String? userId;
  final String nama;
  final String noHp;
  final DateTime tanggalMasuk;
  final String status; // 'pending', 'disetujui', atau 'ditolak'
  final DateTime? createdAt;
  final String? nomorKamar; // Diambil jika query melakukan join ke tabel kamar

  BookingModel({
    required this.id,
    required this.kamarId,
    this.userId,
    required this.nama,
    required this.noHp,
    required this.tanggalMasuk,
    required this.status,
    this.createdAt,
    this.nomorKamar,
  });

  // Konversi dari data JSON Supabase ke BookingModel
  factory BookingModel.fromJson(Map<String, dynamic> json) {
    // Penanganan relasi join tabel kamar: kamar(nomor)
    String? resolvedNomor;
    if (json['kamar'] != null && json['kamar'] is Map) {
      resolvedNomor = json['kamar']['nomor']?.toString();
    }

    return BookingModel(
      id: json['id']?.toString() ?? '',
      kamarId: json['kamar_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      nama: json['nama']?.toString() ?? '',
      noHp: json['no_hp']?.toString() ?? '',
      tanggalMasuk: json['tanggal_masuk'] != null
          ? (DateTime.tryParse(json['tanggal_masuk'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: (json['status']?.toString().toLowerCase()) ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      nomorKamar: resolvedNomor,
    );
  }

  // Konversi dari BookingModel ke Map untuk disimpan di Supabase
  Map<String, dynamic> toJson() {
    return {
      'kamar_id': kamarId,
      'user_id': userId,
      'nama': nama,
      'no_hp': noHp,
      'tanggal_masuk': tanggalMasuk.toIso8601String().split('T').first,
      'status': status,
    };
  }

  // Helper status booking
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isDisetujui => status.toLowerCase() == 'disetujui';
  bool get isDitolak => status.toLowerCase() == 'ditolak';

  // Helper label status bahasa Indonesia
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      default:
        return 'Pending';
    }
  }

  // Format tanggal masuk DD/MM/YYYY sederhana
  String get tanggalMasukFormatted {
    final d = tanggalMasuk.day.toString().padLeft(2, '0');
    final m = tanggalMasuk.month.toString().padLeft(2, '0');
    final y = tanggalMasuk.year.toString();
    return '$d/$m/$y';
  }
}
