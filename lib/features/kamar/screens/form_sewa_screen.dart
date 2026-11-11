// lib/features/kamar/screens/form_sewa_screen.dart

import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../services/kamar_service.dart';

class FormSewaScreen extends StatefulWidget {
  final KamarModel kamar;

  const FormSewaScreen({
    super.key,
    required this.kamar,
  });

  @override
  State<FormSewaScreen> createState() => _FormSewaScreenState();
}

class _FormSewaScreenState extends State<FormSewaScreen> {
  final _formKey = GlobalKey<FormState>();
  final KamarService _kamarService = KamarService();

  // Controller input form
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _noHpController = TextEditingController();

  // Tanggal mulai masuk kos (default besok hari)
  DateTime? _tanggalMasuk = DateTime.now().add(const Duration(days: 1));

  bool _isSubmitting = false;

  @override
  void dispose() {
    _namaController.dispose();
    _noHpController.dispose();
    super.dispose();
  }

  // Menampilkan dialog pemilihan tanggal masuk kos
  Future<void> _pilihTanggalMasuk() async {
    final now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggalMasuk ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalMasuk = picked;
      });
    }
  }

  // Format tanggal untuk tampilan UI (DD/MM/YYYY)
  String _formatTanggal(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString();
    return '$d/$m/$y';
  }

  // Submit permohonan booking ke Supabase
  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_tanggalMasuk == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih tanggal rencana masuk kos')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _kamarService.ajukanSewa(
        kamarId: widget.kamar.id,
        userId: null, // user_id diisi null dulu karena autentikasi belum ada
        nama: _namaController.text.trim(),
        noHp: _noHpController.text.trim(),
        tanggalMasuk: _tanggalMasuk!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Pengajuan sewa Kamar ${widget.kamar.nomor} berhasil dikirim! Menunggu persetujuan owner.',
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 3),
          ),
        );
        // Kembali ke halaman detail kamar dengan status sukses
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim pengajuan sewa: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Ajukan Sewa Kamar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ringkasan Kamar yang Disewa
              _buildRoomSummaryCard(),

              const SizedBox(height: 16),

              // Form Biodata Calon Penghuni
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Data Calon Penghuni',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pastikan data kontak aktif agar pemilik kos dapat menghubungi Anda.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 16),

                    // Input Nama Lengkap
                    TextFormField(
                      controller: _namaController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        hintText: 'Masukkan nama lengkap Anda',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama lengkap wajib diisi';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Input Nomor HP / WhatsApp
                    TextFormField(
                      controller: _noHpController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor HP / WhatsApp *',
                        hintText: 'Contoh: 081234567890',
                        prefixIcon: Icon(Icons.phone_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nomor HP wajib diisi';
                        }
                        if (value.trim().length < 8) {
                          return 'Nomor HP terlalu pendek';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Pilihan Tanggal Masuk Kos
                    InkWell(
                      onTap: _pilihTanggalMasuk,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Rencana Tanggal Masuk *',
                          prefixIcon: Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          _tanggalMasuk != null
                              ? _formatTanggal(_tanggalMasuk!)
                              : 'Pilih tanggal masuk',
                          style: TextStyle(
                            fontSize: 15,
                            color: _tanggalMasuk != null ? Colors.black87 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Catatan Informasi Alur Booking
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
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Status booking akan berstatus "Pending". Pemilik kos akan meninjau dan mengonfirmasi permohonan sewa Anda.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade900,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Tombol Submit Permohonan Sewa
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _submitForm,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(
                    _isSubmitting ? 'Mengirim Pengajuan...' : 'Kirim Pengajuan Sewa',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kartu ringkasan kamar yang dipilih
  Widget _buildRoomSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Foto Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 80,
              height: 60,
              child: widget.kamar.fotoUrl != null && widget.kamar.fotoUrl!.isNotEmpty
                  ? Image.network(
                      widget.kamar.fotoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey.shade200),
                    )
                  : Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.meeting_room_outlined, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Info Kamar
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kamar ${widget.kamar.nomor}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.kamar.hargaFormatted,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
