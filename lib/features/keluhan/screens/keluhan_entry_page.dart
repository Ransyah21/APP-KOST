import 'package:flutter/material.dart';

import 'my_complaints_page.dart';
import 'owner_complaints_page.dart';

/// Pintu masuk modul Keluhan. Dipanggil dari kartu menu "Keluhan" /
/// "Keluhan saya" di menu utama (modul 1):
///
///   Navigator.push(context, MaterialPageRoute(
///     builder: (_) => KeluhanEntryPage(role: role), // 'owner' atau 'penghuni'
///   ));
class KeluhanEntryPage extends StatelessWidget {
  const KeluhanEntryPage({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    return role == 'owner'
        ? const OwnerComplaintsPage()
        : const MyComplaintsPage();
  }
}
