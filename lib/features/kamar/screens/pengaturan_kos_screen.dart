// lib/features/kamar/screens/pengaturan_kos_screen.dart

import 'package:flutter/material.dart';
import '../services/kamar_service.dart';

class PengaturanKosScreen extends StatefulWidget {
  const PengaturanKosScreen({super.key});

  @override
  State<PengaturanKosScreen> createState() => _PengaturanKosScreenState();
}

class _PengaturanKosScreenState extends State<PengaturanKosScreen> {
  final KamarService _kamarService = KamarService();
  final _formKey = GlobalKey<FormState>();

  // Text Editing Controller untuk setiap kolom tabel 'pengaturan_kos'
  final TextEditingController _namaKosController = TextEditingController();
  final TextEditingController _namaOwnerController = TextEditingController();
  final TextEditingController _noWaController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _patokanController = TextEditingController();
  final TextEditingController _bankController = TextEditingController();
  final TextEditingController _noRekeningController = TextEditingController();
  final TextEditingController _atasNamaController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPengaturan();
  }

  @override
  void dispose() {
    _namaKosController.dispose();
    _namaOwnerController.dispose();
    _noWaController.dispose();
    _alamatController.dispose();
    _patokanController.dispose();
    _bankController.dispose();
    _noRekeningController.dispose();
    _atasNamaController.dispose();
    super.dispose();
  }

  /// Memuat data pengaturan kos dari Supabase (baris id = 1)
  Future<void> _loadPengaturan() async {
    setState(() => _isLoading = true);
    try {
      final pengaturan = await _kamarService.getPengaturanKos();
      if (pengaturan != null && mounted) {
        _namaKosController.text = pengaturan.namaKos ?? '';
        _namaOwnerController.text = pengaturan.namaOwner ?? '';
        _noWaController.text = pengaturan.noWa ?? '';
        _alamatController.text = pengaturan.alamat ?? '';
        _patokanController.text = pengaturan.patokan ?? '';
        _bankController.text = pengaturan.bank ?? '';
        _noRekeningController.text = pengaturan.noRekening ?? '';
        _atasNamaController.text = pengaturan.atasNama ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat pengaturan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Menyimpan perubahan pengaturan kos ke tabel 'pengaturan_kos'
  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _kamarService.simpanPengaturanKos(
        id: 1,
        namaKos: _namaKosController.text,
        namaOwner: _namaOwnerController.text,
        noWa: _noWaController.text,
        alamat: _alamatController.text,
        patokan: _patokanController.text,
        bank: _bankController.text,
        noRekening: _noRekeningController.text,
        atasNama: _atasNamaController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Pengaturan & Info Kos berhasil disimpan!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pengaturan: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Pengaturan & Info Kos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner petunjuk
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade800, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Informasi ini digunakan sebagai kontak resmi pemilik kos, tujuan chat WhatsApp oleh calon penyewa, dan informasi rekening sewa.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // KELOMPOK 1: IDENTITAS & KONTAK
                    _buildSectionHeader(
                      icon: Icons.storefront_outlined,
                      title: 'Identitas & Kontak Pemilik',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _namaKosController,
                          label: 'Nama Kos',
                          hint: 'Contoh: Kos Putri Sejahtera',
                          icon: Icons.home_work_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _namaOwnerController,
                          label: 'Nama Pemilik / Pengelola',
                          hint: 'Contoh: Ibu Hj. Maryam',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 14),
                        // Field No WhatsApp dengan validasi ketat
                        _buildTextField(
                          controller: _noWaController,
                          label: 'Nomor WhatsApp Pemilik *',
                          hint: 'Contoh: 081234567890 atau 6281234567890',
                          icon: Icons.phone_android_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nomor WhatsApp wajib diisi untuk fitur chat';
                            }
                            final clean = value.replaceAll(RegExp(r'\D'), '');
                            if (clean.length < 9) {
                              return 'Nomor WhatsApp minimal 9 digit angka';
                            }
                            return null;
                          },
                          helperText: 'Hanya angka, minimal 9 digit (bisa diawali 08 atau 62)',
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // KELOMPOK 2: ALAMAT & PATOKAN
                    _buildSectionHeader(
                      icon: Icons.place_outlined,
                      title: 'Alamat & Lokasi',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _alamatController,
                          label: 'Alamat Lengkap Kos',
                          hint: 'Contoh: Jl. Melati No. 45, RT 02/RW 05, Kelurahan Kebon Jeruk',
                          icon: Icons.map_outlined,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _patokanController,
                          label: 'Patokan Lokasi',
                          hint: 'Contoh: 100 meter di belakang Indomaret, gang pagar hitam',
                          icon: Icons.navigation_outlined,
                          maxLines: 2,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // KELOMPOK 3: REKENING PEMBAYARAN
                    _buildSectionHeader(
                      icon: Icons.account_balance_outlined,
                      title: 'Rekening Bank Pembayaran',
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      children: [
                        _buildTextField(
                          controller: _bankController,
                          label: 'Nama Bank / E-Wallet',
                          hint: 'Contoh: BCA / Mandiri / BRI / GoPay',
                          icon: Icons.account_balance_outlined,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _noRekeningController,
                          label: 'Nomor Rekening',
                          hint: 'Contoh: 1234567890',
                          icon: Icons.credit_card_outlined,
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 14),
                        _buildTextField(
                          controller: _atasNamaController,
                          label: 'Atas Nama (Pemilik Rekening)',
                          hint: 'Contoh: Maryam Santoso',
                          icon: Icons.badge_outlined,
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Tombol Simpan
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isSaving ? null : _simpan,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'Menyimpan...' : 'Simpan Pengaturan Kos',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade800),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? helperText,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 1.5),
        ),
      ),
    );
  }
}
