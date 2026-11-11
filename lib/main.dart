import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import dari feature Kamar
import 'package:kos_app/features/kamar/kamar_feature.dart';
import 'package:kos_app/features/kamar/screens/kelola_booking_screen.dart';

// Import dari feature Tagihan
import 'package:kos_app/features/tagihan/data/supabase_tagihan_repository.dart';
import 'package:kos_app/features/tagihan/pages/tagihan_list_page.dart';

// Import dari feature Login & Auth
import 'package:kos_app/features/login/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nrrlqhcaorisfywitsmt.supabase.co',
    publishableKey: 'sb_publishable_GltyFY3bsudxDyONtz_AnA_MY-24f3u',
  );
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorSchemeSeed: Colors.blue,
      useMaterial3: true,
    ),
    home: const MenuTes(),
  ));
}

class MenuTes extends StatelessWidget {
  const MenuTes({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SupabaseTagihanRepository(Supabase.instance.client);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Tes & Preview Kos App'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- PREVIEW DASHBOARD (UTAMA) ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DashboardPreviewScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.dashboard),
                  label: const Text('Preview Dashboard Owner'),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // --- TES HALAMAN INDIVIDUAL ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DaftarKamarScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.meeting_room),
                  label: const Text('Kamar & Booking'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const KelolaBookingScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.bookmark_added),
                  label: const Text('Kelola Booking (Owner)'),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TagihanListPage(repo: repo, isOwner: true),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long),
                  label: const Text('Tagihan (Owner)'),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),

              // --- TES ALUR AUTH / LOGIN ---
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AuthGate(),
                    ),
                  ),
                  icon: const Icon(Icons.lock),
                  label: const Text('Tes Alur Auth Gate / Login'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// SCREEN PREVIEW DASHBOARD UNTUK TESTING UI
// ==========================================
class DashboardPreviewScreen extends StatelessWidget {
  const DashboardPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SupabaseTagihanRepository(Supabase.instance.client);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Owner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifikasi dipencet')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ringkasan Kos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Card Statistik Dummy
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: const [
                _StatCard(
                  title: 'Kamar Terisi',
                  value: '8 / 10',
                  icon: Icons.door_front_door,
                  color: Colors.blue,
                ),
                _StatCard(
                  title: 'Tagihan Pending',
                  value: '3',
                  icon: Icons.pending_actions,
                  color: Colors.orange,
                ),
                _StatCard(
                  title: 'Keluhan Aktif',
                  value: '2',
                  icon: Icons.report_problem,
                  color: Colors.red,
                ),
                _StatCard(
                  title: 'Estimasi Masuk',
                  value: 'Rp 4.500.000',
                  icon: Icons.payments,
                  color: Colors.green,
                ),
              ],
            ),

            const SizedBox(height: 24),

            const Text(
              'Akses Cepat Halaman',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Card Shortcut ke Halaman-halaman Fitur
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.meeting_room, color: Colors.blue),
                    title: const Text('Daftar & Status Kamar'),
                    subtitle: const Text('Lihat & atur detail kamar kos'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DaftarKamarScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.bookmark_added, color: Colors.purple),
                    title: const Text('Kelola Booking'),
                    subtitle: const Text('Konfirmasi sewa calon penghuni'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const KelolaBookingScreen(),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.orange),
                    title: const Text('Kelola Tagihan'),
                    subtitle: const Text('Verifikasi bukti bayar & tagihan'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TagihanListPage(repo: repo, isOwner: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}