// lib/features/kamar/screens/daftar_kamar_screen.dart

import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../services/kamar_service.dart';
import '../widgets/kamar_card.dart';
import 'detail_kamar_screen.dart';
import 'form_kamar_screen.dart';
import 'kelola_booking_screen.dart';

class DaftarKamarScreen extends StatefulWidget {
  /// Variabel role dummy opsional (default false = penyewa, true = owner)
  final bool initialIsOwner;

  const DaftarKamarScreen({
    super.key,
    this.initialIsOwner = false,
  });

  @override
  State<DaftarKamarScreen> createState() => _DaftarKamarScreenState();
}

class _DaftarKamarScreenState extends State<DaftarKamarScreen> {
  // Instance service untuk komunikasi ke database Supabase
  final KamarService _kamarService = KamarService();

  // Role dummy sementara (bisa diubah langsung dari UI untuk keperluan testing)
  late bool isOwner;

  // Filter status aktif ('Semua', 'Kosong', 'Terisi')
  String _selectedFilter = 'Semua';

  // Future untuk menampung data kamar
  late Future<List<KamarModel>> _futureKamar;

  @override
  void initState() {
    super.initState();
    isOwner = widget.initialIsOwner;
    _refreshData();
  }

  // Fungsi untuk memuat ulang data dari Supabase
  void _refreshData() {
    setState(() {
      _futureKamar = _kamarService.getDaftarKamar(
        statusFilter: _selectedFilter == 'Semua' ? null : _selectedFilter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Daftar Kamar Kos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Tombol Kelola Booking khusus Owner (Langkah 5)
          if (isOwner)
            IconButton(
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Kelola Booking Sewa',
              onPressed: () async {
                // Membuka Halaman Owner Kelola Booking
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KelolaBookingScreen(),
                  ),
                );
                // Refresh data kamar karena status kamar bisa berubah menjadi 'terisi' saat disetujui
                _refreshData();
              },
            ),

          // Toggle dummy role (Penyewa <-> Owner) untuk mempermudah testing
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              avatar: Icon(
                isOwner ? Icons.admin_panel_settings : Icons.person_outline,
                size: 16,
                color: isOwner ? Colors.purple : Colors.blue,
              ),
              label: Text(
                isOwner ? 'Mode: Owner' : 'Mode: Penyewa',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isOwner ? Colors.purple.shade700 : Colors.blue.shade700,
                ),
              ),
              backgroundColor: isOwner ? Colors.purple.shade50 : Colors.blue.shade50,
              onPressed: () {
                setState(() {
                  isOwner = !isOwner;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isOwner
                          ? 'Beralih ke mode Pemilik Kos (Owner)'
                          : 'Beralih ke mode Calon Penghuni (Penyewa)',
                    ),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Status Bar
          _buildFilterBar(),

          // Konten List Kamar
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _refreshData();
                await _futureKamar;
              },
              child: FutureBuilder<List<KamarModel>>(
                future: _futureKamar,
                builder: (context, snapshot) {
                  // Kondisi 1: Sedang memuat data
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  // Kondisi 2: Terjadi error saat ambil data
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Gagal mengambil data kamar',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _refreshData,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final listKamar = snapshot.data ?? [];

                  // Kondisi 3: Data kosong
                  if (listKamar.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 12),
                              Text(
                                'Belum ada data kamar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _selectedFilter == 'Semua'
                                    ? 'Data kamar di tabel Supabase masih kosong.'
                                    : 'Tidak ada kamar dengan status "$_selectedFilter".',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  // Kondisi 4: Data berhasil dimuat
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: listKamar.length,
                    itemBuilder: (context, index) {
                      final kamar = listKamar[index];
                      return KamarCard(
                        kamar: kamar,
                        onTap: () async {
                          // Navigasi ke Halaman Detail Kamar
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailKamarScreen(
                                kamar: kamar,
                                isOwner: isOwner,
                              ),
                            ),
                          );
                          // Refresh daftar jika ada perubahan saat kembali
                          _refreshData();
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),

      // Tombol Tambah Kamar (khusus Owner)
      floatingActionButton: isOwner
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Membuka Form Tambah Kamar Kosong
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FormKamarScreen(),
                  ),
                );
                // Jika berhasil disimpan, refresh otomatis daftar kamar
                if (result == true) {
                  _refreshData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kamar'),
            )
          : null,
    );
  }

  // Bar pilihan filter (Semua / Kosong / Terisi)
  Widget _buildFilterBar() {
    final filters = ['Semua', 'Kosong', 'Terisi'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              selectedColor: Colors.blue.shade100,
              checkmarkColor: Colors.blue.shade800,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue.shade900 : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                  _refreshData();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}