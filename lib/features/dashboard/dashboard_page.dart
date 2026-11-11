import 'package:flutter/material.dart';

import '../login/models/user_profile.dart';
import 'owner_dashboard.dart';
import 'penghuni_dashboard.dart';

/// Pintu masuk dashboard setelah login. Role dibaca dari tabel `profiles`
/// (lewat AuthGate), lalu tampilan dibedakan:
///   owner    -> OwnerDashboard
///   penghuni -> PenghuniDashboard
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return profile.isOwner
        ? OwnerDashboard(profile: profile)
        : PenghuniDashboard(profile: profile);
  }
}