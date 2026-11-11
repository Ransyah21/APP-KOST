// lib/features/kamar/screens/detail_kamar_screen.dart

import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../services/kamar_service.dart';
import 'form_kamar_screen.dart';
import 'form_sewa_screen.dart';

class DetailKamarScreen extends StatefulWidget {
  final KamarModel kamar;
  final bool isOwner;

  const DetailKamarScreen({
    super.key,
    required this.kamar,
    this.isOwner = false,
  });

  @override
  State<DetailKamarScreen> createState() => _DetailKamarScreenState();
}

class _DetailKamarScreenState extends State<DetailKamarScreen> {
  final KamarService _kamarService = KamarService();
  late KamarModel _currentKamar;
  bool _isLoading = false;
  bool _isDeleting = false;

  // Controller & index untuk slider banyak foto
  late final PageController _pageController;
  int _currentFotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentKamar = widget.kamar;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi untuk memuat ulang data kamar jika ada perubahan data
  Future<void> _refreshDetail() async {
    setState(() => _isLoading = true);
    try {
      final updated = await _kamarService.getDetailKamar(_currentKamar.id);
      if (updated != null && mounted) {
        setState(() {
          _currentKamar = updated;
          _currentFotoIndex = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal refresh data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Dialog konfirmasi hapus kamar khusus owner
  Future<void> _showKonfirmasiHapusDialog(BuildContext context) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: Text(
            'Hapus Kamar ${_currentKamar.nomor}?',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Kamar ${_currentKamar.nomor} beserta datanya akan dihapus permanen dari sistem kos. Tindakan ini tidak dapat dibatalkan.',
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Hapus Kamar'),
            ),
          ],
        );
      },
    );

    if (confirm == true && mounted) {
      setState(() => _isDeleting = true);
      try {
        await _kamarService.hapusKamar(_currentKamar.id);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kamar ${_currentKamar.nomor} berhasil dihapus'),
              backgroundColor: Colors.green.shade700,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isDeleting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus kamar: $e'),
              backgroundColor: Colors.red.shade700,
            ),
          );
        }
      }
    }
  }

  // Membuka tampilan foto layar penuh yang bisa di-zoom
  void _openFullScreenImage(BuildContext context, List<String> listFoto, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(
          imageUrls: listFoto,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  // Helper untuk menentukan icon fasilitas secara otomatis berdasarkan kata kunci
  IconData _getIconForFasilitas(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('ac') || lower.contains('pendingin')) {
      return Icons.ac_unit;
    } else if (lower.contains('wifi') || lower.contains('internet')) {
      return Icons.wifi;
    } else if (lower.contains('mandi') || lower.contains('toilet') || lower.contains('water heater')) {
      return Icons.bathtub_outlined;
    } else if (lower.contains('kasur') || lower.contains('bed') || lower.contains('springbed')) {
      return Icons.bed_outlined;
    } else if (lower.contains('lemari')) {
      return Icons.door_sliding_outlined;
    } else if (lower.contains('meja') || lower.contains('kursi') || lower.contains('belajar')) {
      return Icons.desk_outlined;
    } else if (lower.contains('tv') || lower.contains('televisi')) {
      return Icons.tv;
    } else if (lower.contains('dapur') || lower.contains('kitchen')) {
      return Icons.soup_kitchen_outlined;
    } else if (lower.contains('parkir') || lower.contains('motor') || lower.contains('mobil')) {
      return Icons.local_parking_outlined;
    }
    return Icons.check_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final bool isKosong = _currentKamar.isKosong;

    // Kumpulkan daftar foto yang ada (foto_urls, atau fallback ke foto_url)
    final List<String> photos = _currentKamar.fotoUrls.isNotEmpty
        ? _currentKamar.fotoUrls
        : (_currentKamar.fotoUrl != null && _currentKamar.fotoUrl!.isNotEmpty
            ? [_currentKamar.fotoUrl!]
            : []);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Detail Kamar ${_currentKamar.nomor}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Segarkan data',
            onPressed: _isLoading ? null : _refreshDetail,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Slider Foto Kamar (PageView dengan Indikator Titik & Teks "N/Total")
            _buildPhotoSlider(photos, isKosong),

            // 2. Info Utama (Nomor & Harga)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kamar ${_currentKamar.nomor}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isKosong
                                  ? 'Siap huni sekarang'
                                  : 'Saat ini sedang ditempati penghuni',
                              style: TextStyle(
                                fontSize: 13,
                                color: isKosong ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Harga
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _currentKamar.hargaFormatted,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            'Termasuk listrik & air',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 3. Deskripsi Kamar
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Deskripsi Kamar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _currentKamar.deskripsi != null && _currentKamar.deskripsi!.trim().isNotEmpty
                        ? _currentKamar.deskripsi!
                        : 'Belum ada catatan deskripsi khusus untuk kamar ini.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 4. Fasilitas Kamar
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Fasilitas Kamar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${_currentKamar.fasilitas.length} fasilitas',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_currentKamar.fasilitas.isEmpty)
                    Text(
                      'Belum ada daftar fasilitas yang ditambahkan.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    )
                  else
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _currentKamar.fasilitas.map((fasilitas) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.blue.shade100,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getIconForFasilitas(fasilitas),
                                size: 16,
                                color: Colors.blue.shade800,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                fasilitas,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 5. Bagian Denah Ruangan (InteractiveViewer Pinch-to-Zoom)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Denah Ruangan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (_currentKamar.hasDenah)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.zoom_in, size: 14, color: Colors.blue.shade800),
                              const SizedBox(width: 4),
                              Text(
                                'Pinch Zoom',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (_currentKamar.hasDenah)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 230,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Center(
                                child: Image.network(
                                  _currentKamar.denahUrl!,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Center(child: Text('Gagal memuat gambar denah')),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '* Gunakan 2 jari (pinch) untuk memperbesar atau menggeser gambar denah.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                        ),
                      ],
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.map_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 6),
                            Text(
                              'Denah belum tersedia',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 6. Informasi Tambahan
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Tambahan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('ID Kamar', _currentKamar.id),
                  _buildInfoRow(
                    'Jumlah Foto',
                    '${photos.length} Foto',
                  ),
                  _buildInfoRow(
                    'Tanggal Input',
                    _currentKamar.createdAt != null
                        ? '${_currentKamar.createdAt!.day}/${_currentKamar.createdAt!.month}/${_currentKamar.createdAt!.year}'
                        : '-',
                  ),
                  _buildInfoRow('Tipe Sewa', 'Bulanan'),
                ],
              ),
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),

      // 7. Bottom Action Bar (Sesuai Role Dummy)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: widget.isOwner
              ? _buildOwnerActionBar(context)
              : _buildPenyewaActionBar(context, isKosong),
        ),
      ),
    );
  }

  // Widget Slider Banyak Foto Kamar dengan Indikator Titik & Counter "N/Total"
  Widget _buildPhotoSlider(List<String> photos, bool isKosong) {
    if (photos.isEmpty) {
      return Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: _buildPlaceholderFoto(),
          ),
          _buildStatusBadge(isKosong),
        ],
      );
    }

    return Stack(
      children: [
        // PageView Slider Foto
        AspectRatio(
          aspectRatio: 16 / 10,
          child: PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentFotoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final photoUrl = photos[index];
              return GestureDetector(
                onTap: () => _openFullScreenImage(context, photos, index),
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) =>
                      _buildPlaceholderFoto(),
                ),
              );
            },
          ),
        ),

        // Badge Status di Atas
        _buildStatusBadge(isKosong),

        // Counter Teks "2/5" di pojok kiri bawah foto
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentFotoIndex + 1}/${photos.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // Hint "Tap untuk perbesar" di pojok kanan bawah
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.fullscreen, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'Layar Penuh',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Indikator Titik di Tengah Bawah (jika lebih dari 1 foto)
        if (photos.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photos.length,
                (i) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: _currentFotoIndex == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentFotoIndex == i
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Badge Status Ketersediaan
  Widget _buildStatusBadge(bool isKosong) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isKosong ? Colors.green.shade600 : Colors.red.shade600,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isKosong ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              isKosong ? 'Kamar Kosong (Tersedia)' : 'Kamar Terisi',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilan tombol aksi untuk Calon Penghuni / Penyewa
  Widget _buildPenyewaActionBar(BuildContext context, bool isKosong) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isKosong ? Colors.blue.shade700 : Colors.grey.shade400,
          foregroundColor: Colors.white,
          elevation: isKosong ? 2 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: isKosong
            ? () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormSewaScreen(kamar: _currentKamar),
                  ),
                );
                if (result == true) {
                  _refreshDetail();
                }
              }
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isKosong ? Icons.assignment_turned_in_outlined : Icons.lock_outline,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isKosong ? 'Ajukan Sewa Kamar Ini' : 'Kamar Sudah Terisi (Tidak Tersedia)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // Tampilan tombol aksi untuk Pemilik Kos (Owner)
  Widget _buildOwnerActionBar(BuildContext context) {
    return Row(
      children: [
        // Tombol Edit Kamar
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade700),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FormKamarScreen(kamar: _currentKamar),
                  ),
                );
                if (result == true) {
                  _refreshDetail();
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Kamar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Tombol Hapus Kamar
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _isDeleting ? null : () => _showKonfirmasiHapusDialog(context),
              icon: _isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.delete_outline),
              label: Text(
                _isDeleting ? 'Menghapus...' : 'Hapus Kamar',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderFoto() {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.meeting_room_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Belum ada foto kamar',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget Layar Penuh dengan Fitur Zoom (InteractiveViewer)
class _FullScreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const _FullScreenImageViewer({
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Foto ${_currentIndex + 1} dari ${widget.imageUrls.length}',
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.imageUrls.length,
        onPageChanged: (i) => setState(() => _currentIndex = i),
        itemBuilder: (context, index) {
          return Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Image.network(
                widget.imageUrls[index],
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Text('Gagal memuat gambar', style: TextStyle(color: Colors.white))),
              ),
            ),
          );
        },
      ),
    );
  }
}
