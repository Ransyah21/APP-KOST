enum ComplaintStatus {
  pending,
  proses,
  selesai;

  String get label => switch (this) {
        ComplaintStatus.pending => 'Pending',
        ComplaintStatus.proses => 'Diproses',
        ComplaintStatus.selesai => 'Selesai',
      };

  static ComplaintStatus fromValue(String? value) =>
      ComplaintStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => ComplaintStatus.pending,
      );
}

class Complaint {
  const Complaint({
    required this.id,
    required this.penghuniId,
    required this.judul,
    required this.isi,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.roomId,
    this.penghuniNama,
    this.nomorKamar,
  });

  final String id;
  final String penghuniId;
  final String? roomId;
  final String judul;
  final String isi;
  final ComplaintStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Diisi dari join `users(nama)` dan `rooms(nomor_kamar)`.
  final String? penghuniNama;
  final String? nomorKamar;

  factory Complaint.fromMap(Map<String, dynamic> m) {
    final user = m['users'] as Map<String, dynamic>?;
    final room = m['rooms'] as Map<String, dynamic>?;
    return Complaint(
      id: m['id'] as String,
      penghuniId: m['penghuni_id'] as String,
      roomId: m['room_id'] as String?,
      judul: m['judul'] as String,
      isi: m['isi'] as String,
      status: ComplaintStatus.fromValue(m['status'] as String?),
      createdAt: DateTime.parse(m['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(m['updated_at'] as String).toLocal(),
      penghuniNama: user?['nama'] as String?,
      nomorKamar: room?['nomor_kamar'] as String?,
    );
  }
}
