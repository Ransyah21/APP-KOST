// lib/features/kamar/screens/form_kamar_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/kamar_model.dart';
import '../services/kamar_service.dart';

class FormKamarScreen extends StatefulWidget {
  /// Jika kamar bernilai null -> Mode Tambah Kamar Baru
  /// Jika kamar terisi -> Mode Edit Kamar yang sudah ada
  final KamarModel? kamar;

  const FormKamarScreen({
    super.key,
    this.kamar,
  });

  @override
  State<FormKamarScreen> createState() => _FormKamarScreenState();
}

class _FormKamarScreenState extends State<FormKamarScreen> {
  final _formKey = GlobalKey<FormState>();
  final KamarService _kamarService = KamarService();
  final ImagePicker _imagePicker = ImagePicker();

  late TextEditingController _nomorController;
  late TextEditingController _hargaController;
  late TextEditingController _deskripsiController;
  late TextEditingController _fasilitasController;

  String _status = 'kosong';

  // Foto kamar: foto lama (sudah di server) + foto baru (belum diupload)
  List<String> _fotoLama = [];
  final List<Uint8List> _fotoBaruBytes = [];
  final List<String> _fotoBaruNama = [];

  // Denah ruangan (opsional)
  String? _denahLama;
  Uint8List? _denahBaruBytes;
  String? _denahBaruNama;

  bool _isSaving = false;

  bool get isEditMode => widget.kamar != null;

  @override
  void initState() {
    super.initState();
    final k = widget.kamar;
    _nomorController = TextEditingController(text: k?.nomor ?? '');
    _hargaController = TextEditingController(text: k != null ? k.harga.toString() : '');
    _deskripsiController = TextEditingController(text: k?.deskripsi ?? '');
    _fasilitasController = TextEditingController(text: k?.fasilitas.join(', ') ?? '');
    _status = k?.status.toLowerCase() ?? 'kosong';
    _fotoLama = List<String>.from(k?.fotoUrls ?? const []);
    _denahLama = k?.denahUrl;
  }

  @override
  void dispose() {
    _nomorController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _fasilitasController.dispose();
    super.dispose();
  }

  void _tampilkanPesan(String pesan, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(pesan),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
      ),
    );
  }

  // Pilih BANYAK foto sekaligus (tanpa batas jumlah)
  Future<void> _pilihFoto() async {
    try {
      final List<XFile> files = await _imagePicker.pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;

      final bytesList = <Uint8List>[];
      final namaList = <String>[];
      for (final f in files) {
        bytesList.add(await f.readAsBytes());
        namaList.add(f.name);
      }
      setState(() {
        _fotoBaruBytes.addAll(bytesList);
        _fotoBaruNama.addAll(namaList);
      });
    } catch (e) {
      _tampilkanPesan('Gagal memilih foto: $e', error: true);
    }
  }

  void _hapusFotoLama(int index) {
    setState(() => _fotoLama.removeAt(index));
  }

  void _hapusFotoBaru(int index) {
    setState(() {
      _fotoBaruBytes.removeAt(index);
      _fotoBaruNama.removeAt(index);
    });
  }

  // Pilih 1 gambar denah
  Future<void> _pilihDenah() async {
    try {
      final XFile? f = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (f == null) return;
      final bytes = await f.readAsBytes();
      setState(() {
        _denahBaruBytes = bytes;
        _denahBaruNama = f.name;
      });
    } catch (e) {
      _tampilkanPesan('Gagal memilih denah: $e', error: true);
    }
  }

  void _hapusDenah() {
    setState(() {
      _denahBaruBytes = null;
      _denahBaruNama = null;
      _denahLama = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // 1. Upload foto baru (jika ada), gabungkan dengan foto lama
      final List<String> semuaFoto = List<String>.from(_fotoLama);
      if (_fotoBaruBytes.isNotEmpty) {
        final urlBaru = await _kamarService.uploadBanyakFotoKamar(
          listBytes: _fotoBaruBytes,
          listFileNames: _fotoBaruNama,
        );
        semuaFoto.addAll(urlBaru);
      }

      // 2. Upload denah baru (jika ada)
      String? denahFinal = _denahLama;
      if (_denahBaruBytes != null) {
        denahFinal = await _kamarService.uploadDenahKamar(
          bytes: _denahBaruBytes!,
          fileName: _denahBaruNama ?? 'denah.jpg',
        );
      }

      final listFasilitas = _fasilitasController.text
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      final hargaInt = int.parse(_hargaController.text.trim());
      final nomorStr = _nomorController.text.trim();
      final deskripsiStr = _deskripsiController.text.trim();

      if (isEditMode) {
        await _kamarService.updateKamar(
          id: widget.kamar!.id,
          nomor: nomorStr,
          harga: hargaInt,
          deskripsi: deskripsiStr.isNotEmpty ? deskripsiStr : null,
          fasilitas: listFasilitas,
          fotoUrls: semuaFoto,
          denahUrl: denahFinal,
          status: _status,
        );
        _tampilkanPesan('Kamar $nomorStr berhasil diperbarui');
      } else {
        await _kamarService.tambahKamar(
          nomor: nomorStr,
          harga: hargaInt,
          deskripsi: deskripsiStr.isNotEmpty ? deskripsiStr : null,
          fasilitas: listFasilitas,
          fotoUrls: semuaFoto,
          denahUrl: denahFinal,
          status: _status,
        );
        _tampilkanPesan('Kamar $nomorStr berhasil ditambahkan');
      }

      // Kembali dengan nilai true agar daftar kamar refresh
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _tampilkanPesan('Terjadi kesalahan: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = isEditMode ? 'Edit Kamar ${widget.kamar!.nomor}' : 'Tambah Kamar Baru';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFotoSection(),
              const SizedBox(height: 16),
              _buildDenahSection(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nomorController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Kamar *',
                        hintText: 'Contoh: 101, 202',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => (value == null || value.trim().isEmpty)
                          ? 'Nomor kamar wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hargaController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Sewa per Bulan (Rp) *',
                        hintText: 'Contoh: 1500000',
                        prefixIcon: Icon(Icons.payments_outlined),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Harga sewa wajib diisi';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Masukkan angka harga yang valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _status,
                      decoration: const InputDecoration(
                        labelText: 'Status Kamar',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'kosong', child: Text('Kosong (Tersedia)')),
                        DropdownMenuItem(
                            value: 'terisi', child: Text('Terisi (Sudah ada penghuni)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _status = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _fasilitasController,
                      decoration: const InputDecoration(
                        labelText: 'Fasilitas Kamar',
                        hintText: 'AC, WiFi, Kamar Mandi Dalam',
                        helperText: 'Pisahkan setiap fasilitas dengan tanda koma (,)',
                        prefixIcon: Icon(Icons.checklist_rtl_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _deskripsiController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi Kamar (Opsional)',
                        hintText: 'Tuliskan catatan detail mengenai kamar...',
                        prefixIcon: Icon(Icons.description_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _submitForm,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(isEditMode ? Icons.save_outlined : Icons.add_circle_outline),
                  label: Text(_isSaving
                      ? 'Menyimpan...'
                      : (isEditMode ? 'Simpan Perubahan' : 'Tambah Kamar')),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ===== Bagian foto kamar (banyak foto) =====
  Widget _buildFotoSection() {
    final int total = _fotoLama.length + _fotoBaruBytes.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Foto Kamar',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              Text('$total foto',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Foto pertama jadi foto sampul. Bisa pilih banyak foto sekaligus.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < _fotoLama.length; i++)
                _thumbnail(
                  child: Image.network(
                    _fotoLama[i],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey.shade200),
                  ),
                  onHapus: () => _hapusFotoLama(i),
                  sampul: i == 0,
                ),
              for (int i = 0; i < _fotoBaruBytes.length; i++)
                _thumbnail(
                  child: Image.memory(_fotoBaruBytes[i], fit: BoxFit.cover),
                  onHapus: () => _hapusFotoBaru(i),
                  sampul: _fotoLama.isEmpty && i == 0,
                ),
              // Tombol tambah foto
              InkWell(
                onTap: _pilihFoto,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined,
                          size: 30, color: Colors.blue.shade600),
                      const SizedBox(height: 4),
                      Text('Tambah',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== Bagian denah ruangan (opsional, 1 gambar) =====
  Widget _buildDenahSection() {
    final bool adaBaru = _denahBaruBytes != null;
    final bool adaLama = _denahLama != null && _denahLama!.isNotEmpty;

    return Container(
      width: double.infinity,
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
            'Denah Ruangan (Opsional)',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            'Upload gambar tampak atas ruangan (posisi kasur, lemari, pintu, dll).',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          if (adaBaru || adaLama)
            Stack(
              alignment: Alignment.topRight,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Container(
                      color: Colors.grey.shade100,
                      child: adaBaru
                          ? Image.memory(_denahBaruBytes!, fit: BoxFit.contain)
                          : Image.network(_denahLama!, fit: BoxFit.contain),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.7),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _pilihDenah,
                        icon: const Icon(Icons.change_circle_outlined, size: 16),
                        label: const Text('Ganti'),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          foregroundColor: Colors.white,
                        ),
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: _hapusDenah,
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            InkWell(
              onTap: _pilihDenah,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.architecture_outlined,
                          size: 36, color: Colors.blue.shade600),
                      const SizedBox(height: 8),
                      Text('Pilih Gambar Denah',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Kotak thumbnail foto dengan tombol hapus dan label sampul
  Widget _thumbnail({
    required Widget child,
    required VoidCallback onHapus,
    bool sampul = false,
  }) {
    return SizedBox(
      width: 90,
      height: 90,
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: child,
            ),
          ),
          if (sampul)
            Positioned(
              left: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade700,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Sampul',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              onTap: onHapus,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.85),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}