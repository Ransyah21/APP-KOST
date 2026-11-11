// lib/features/kamar/widgets/kamar_card.dart

import 'package:flutter/material.dart';
import '../models/kamar_model.dart';

class KamarCard extends StatelessWidget {
  final KamarModel kamar;
  final VoidCallback? onTap;

  const KamarCard({
    super.key,
    required this.kamar,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKosong = kamar.isKosong;

    // Foto sampul utama (fotoUrl atau foto pertama dari fotoUrls)
    final String? fotoSampul = kamar.fotoUrl ??
        (kamar.fotoUrls.isNotEmpty ? kamar.fotoUrls.first : null);

    final int jumlahFoto = kamar.fotoUrls.length;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bagian Foto Sampul Kamar dan Badge
            Stack(
              children: [
                // Gambar Kamar
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: fotoSampul != null && fotoSampul.isNotEmpty
                      ? Image.network(
                          fotoSampul,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return _buildPlaceholderFoto();
                          },
                        )
                      : _buildPlaceholderFoto(),
                ),

                // Badge Status (Kosong / Terisi) di pojok kanan atas
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isKosong ? Colors.green.shade600 : Colors.red.shade600,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isKosong ? Icons.check_circle_outline : Icons.cancel_outlined,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isKosong ? 'Kosong' : 'Terisi',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Badge Jumlah Foto jika ada lebih dari 1 foto (di pojok kiri bawah)
                if (jumlahFoto > 1)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library_outlined,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$jumlahFoto foto',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // Informasi Nomor Kamar, Harga, dan Fasilitas
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nomor Kamar
                      Text(
                        'Kamar ${kamar.nomor}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      // Harga per bulan
                      Text(
                        kamar.hargaFormatted,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),

                  // Fasilitas singkat (jika ada)
                  if (kamar.fasilitas.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: kamar.fasilitas.take(3).map((f) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            f,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder jika belum ada foto atau gagal load foto
  Widget _buildPlaceholderFoto() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 6),
            Text(
              'Belum ada foto',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
