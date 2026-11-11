// lib/features/kamar/models/kamar_model.dart

class KamarModel {
  final String id;
  final String nomor;
  final int harga;
  final String? deskripsi;
  final List<String> fasilitas;
  final String? fotoUrl; // Foto sampul utama
  final List<String> fotoUrls; // Daftar banyak foto kamar
  final String? denahUrl; // Foto denah ruangan (opsional)
  final String status; // 'kosong' atau 'terisi'
  final DateTime? createdAt;

  KamarModel({
    required this.id,
    required this.nomor,
    required this.harga,
    this.deskripsi,
    this.fasilitas = const [],
    this.fotoUrl,
    this.fotoUrls = const [],
    this.denahUrl,
    required this.status,
    this.createdAt,
  });

  // Konversi dari JSON (data Supabase) ke objek KamarModel
  factory KamarModel.fromJson(Map<String, dynamic> json) {
    // 1. Penanganan fasilitas jika berupa List<dynamic> atau String
    List<String> listFasilitas = [];
    if (json['fasilitas'] != null) {
      if (json['fasilitas'] is List) {
        listFasilitas = List<String>.from(json['fasilitas'].map((item) => item.toString()));
      } else if (json['fasilitas'] is String) {
        listFasilitas = (json['fasilitas'] as String)
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    // 2. Penanganan banyak foto (foto_urls). Jika kosong fallback ke foto_url lama
    List<String> resolvedFotoUrls = [];
    if (json['foto_urls'] != null && json['foto_urls'] is List) {
      resolvedFotoUrls = List<String>.from(
        (json['foto_urls'] as List)
            .map((item) => item.toString())
            .where((url) => url.trim().isNotEmpty),
      );
    }

    final singleFoto = json['foto_url']?.toString();
    if (resolvedFotoUrls.isEmpty && singleFoto != null && singleFoto.trim().isNotEmpty) {
      resolvedFotoUrls.add(singleFoto.trim());
    }

    // 3. Foto sampul: gunakan foto_url atau foto pertama dari foto_urls
    final resolvedFotoSampul = (singleFoto != null && singleFoto.trim().isNotEmpty)
        ? singleFoto.trim()
        : (resolvedFotoUrls.isNotEmpty ? resolvedFotoUrls.first : null);

    return KamarModel(
      id: json['id']?.toString() ?? '',
      nomor: json['nomor']?.toString() ?? '-',
      harga: json['harga'] is num ? (json['harga'] as num).toInt() : 0,
      deskripsi: json['deskripsi']?.toString(),
      fasilitas: listFasilitas,
      fotoUrl: resolvedFotoSampul,
      fotoUrls: resolvedFotoUrls,
      denahUrl: json['denah_url']?.toString(),
      status: (json['status']?.toString().toLowerCase()) ?? 'kosong',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  // Konversi dari objek KamarModel ke Map (untuk simpan ke Supabase)
  Map<String, dynamic> toJson() {
    return {
      'nomor': nomor,
      'harga': harga,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas.join(', '),
      'foto_url': fotoUrl ?? (fotoUrls.isNotEmpty ? fotoUrls.first : null),
      'foto_urls': fotoUrls,
      'denah_url': denahUrl,
      'status': status,
    };
  }

  // Helper untuk cek apakah kamar masih kosong
  bool get isKosong => status.toLowerCase() == 'kosong';

  // Helper cek apakah kamar memiliki denah
  bool get hasDenah => denahUrl != null && denahUrl!.trim().isNotEmpty;

  // Helper format harga ke Rupiah sederhana tanpa package tambahan
  String get hargaFormatted {
    final str = harga.toString();
    final buffer = StringBuffer();
    int count = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      buffer.write(str[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return 'Rp ${buffer.toString().split('').reversed.join('')} / bulan';
  }
}
