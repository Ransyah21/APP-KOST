import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/login/core/app_theme.dart';
import 'features/login/screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://nrrlqhcaorisfywitsmt.supabase.co',
    publishableKey: 'sb_publishable_GltyFY3bsudxDyONtz_AnA_MY-24f3u',
  );
  runApp(
    MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const AuthGate(),
    ),
  );
}