// lib/features/kamar/utils/wa_helper.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mengubah nomor 08xx / 8xx / +62xx / 62xx menjadi format 62xx (hanya angka)
String normalisasiNomor(String input) {
  var n = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (n.startsWith('0')) {
    n = '62${n.substring(1)}';
  } else if (n.startsWith('8')) {
    n = '62$n';
  }
  return n;
}

/// Membuka chat WhatsApp ke [nomor] dengan [pesan] yang sudah terisi.
/// Di HP membuka aplikasi WhatsApp, di browser membuka WhatsApp Web.
Future<void> bukaWhatsApp(
  BuildContext context, {
  required String nomor,
  required String pesan,
}) async {
  final messenger = ScaffoldMessenger.of(context);
  final n = normalisasiNomor(nomor);

  if (n.length < 9) {
    messenger.showSnackBar(
      const SnackBar(content: Text('Nomor WhatsApp tidak valid')),
    );
    return;
  }

  final uri = Uri.parse('https://wa.me/$n?text=${Uri.encodeComponent(pesan)}');

  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Tidak bisa membuka WhatsApp')),
      );
    }
  } catch (e) {
    messenger.showSnackBar(
      SnackBar(content: Text('Gagal membuka WhatsApp: $e')),
    );
  }
}