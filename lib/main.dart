import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kos_app/features/kamar/kamar_feature.dart';
import 'package:kos_app/features/tagihan/data/supabase_tagihan_repository.dart';
import 'package:kos_app/features/tagihan/pages/tagihan_list_page.dart';
import 'package:kos_app/features/kamar/screens/kelola_booking_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nrrlqhcaorisfywitsmt.supabase.co',
    publishableKey: 'sb_publishable_GltyFY3bsudxDyONtz_AnA_MY-24f3u',
  );
  runApp(MaterialApp(
    theme: ThemeData(colorSchemeSeed: Colors.blue),
    home: const MenuTes(),
  ));
}

class MenuTes extends StatelessWidget {
  const MenuTes({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = SupabaseTagihanRepository(Supabase.instance.client);
    return Scaffold(
      appBar: AppBar(title: const Text('Menu Tes')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DaftarKamarScreen())),
              child: const Text('Kamar & Booking'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const KelolaBookingScreen())),
              child: const Text('Kelola Booking (Owner)'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(
                      builder: (_) => TagihanListPage(repo: repo, isOwner: true))),
              child: const Text('Tagihan (Owner)'),
            ),
          ],
        ),
      ),
    );
  }
}