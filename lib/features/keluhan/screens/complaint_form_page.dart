import 'package:flutter/material.dart';

import '../services/complaint_service.dart';
import '../utils/format.dart';

/// Form kirim keluhan (penghuni). Pop dengan `true` jika berhasil terkirim.
class ComplaintFormPage extends StatefulWidget {
  const ComplaintFormPage({super.key});

  @override
  State<ComplaintFormPage> createState() => _ComplaintFormPageState();
}

class _ComplaintFormPageState extends State<ComplaintFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _judul = TextEditingController();
  final _isi = TextEditingController();
  final _service = ComplaintService();
  bool _mengirim = false;

  @override
  void dispose() {
    _judul.dispose();
    _isi.dispose();
    super.dispose();
  }

  Future<void> _kirim() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _mengirim = true);
    try {
      final roomId = await _service.findActiveRoomId();
      await _service.kirimKeluhan(
        judul: _judul.text.trim(),
        isi: _isi.text.trim(),
        roomId: roomId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keluhan terkirim')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim: ${pesanError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kirim Keluhan')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _judul,
              enabled: !_mengirim,
              maxLength: 100,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Judul keluhan',
                hintText: 'Contoh: AC kamar tidak dingin',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Judul wajib diisi' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _isi,
              enabled: !_mengirim,
              maxLength: 1000,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Isi keluhan',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Isi keluhan wajib diisi';
                if (t.length < 10) return 'Jelaskan minimal 10 karakter';
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _mengirim ? null : _kirim,
              child: _mengirim
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }
}
