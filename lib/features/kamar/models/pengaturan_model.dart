// lib/features/kamar/models/pengaturan_model.dart

class PengaturanKos {
  final int id;
  final String? namaKos;
  final String? namaOwner;
  final String? noWa;
  final String? alamat;
  final String? patokan;
  final String? bank;
  final String? noRekening;
  final String? atasNama;

  PengaturanKos({
    this.id = 1,
    this.namaKos,
    this.namaOwner,
    this.noWa,
    this.alamat,
    this.patokan,
    this.bank,
    this.noRekening,
    this.atasNama,
  });

  /// Factory untuk memetakan data JSON dari tabel 'pengaturan_kos' Supabase
  factory PengaturanKos.fromJson(Map<String, dynamic> json) {
    return PengaturanKos(
      id: json['id'] as int? ?? 1,
      namaKos: json['nama_kos'] as String?,
      namaOwner: json['nama_owner'] as String?,
      noWa: json['no_wa'] as String?,
      alamat: json['alamat'] as String?,
      patokan: json['patokan'] as String?,
      bank: json['bank'] as String?,
      noRekening: json['no_rekening'] as String?,
      atasNama: json['atas_nama'] as String?,
    );
  }

  /// Mengubah objek PengaturanKos menjadi Map JSON untuk disimpan ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_kos': namaKos?.trim(),
      'nama_owner': namaOwner?.trim(),
      'no_wa': noWa?.trim(),
      'alamat': alamat?.trim(),
      'patokan': patokan?.trim(),
      'bank': bank?.trim(),
      'no_rekening': noRekening?.trim(),
      'atas_nama': atasNama?.trim(),
    };
  }

  /// Cek apakah nomor WhatsApp pemilik sudah diisi dan valid
  bool get hasWhatsApp => noWa != null && noWa!.trim().isNotEmpty;

  /// Copy with untuk memudahkan manipulasi state lokal
  PengaturanKos copyWith({
    int? id,
    String? namaKos,
    String? namaOwner,
    String? noWa,
    String? alamat,
    String? patokan,
    String? bank,
    String? noRekening,
    String? atasNama,
  }) {
    return PengaturanKos(
      id: id ?? this.id,
      namaKos: namaKos ?? this.namaKos,
      namaOwner: namaOwner ?? this.namaOwner,
      noWa: noWa ?? this.noWa,
      alamat: alamat ?? this.alamat,
      patokan: patokan ?? this.patokan,
      bank: bank ?? this.bank,
      noRekening: noRekening ?? this.noRekening,
      atasNama: atasNama ?? this.atasNama,
    );
  }
}
