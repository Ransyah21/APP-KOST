import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Penjaga pintu: belum login -> LoginScreen, sudah login -> HomeScreen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<AuthState>? _sub;
  String? _userId;
  UserProfile? _profile;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.instance.currentSession?.user.id;
    _sub = AuthService.instance.authChanges.listen(_onAuthChange);
    _muatProfil();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onAuthChange(AuthState state) {
    if (state.event != AuthChangeEvent.signedIn &&
        state.event != AuthChangeEvent.signedOut) {
      return;
    }
    final id = state.session?.user.id;
    if (id == _userId) return; // bukan pergantian akun, abaikan
    _userId = id;
    if (!mounted) return;
    // Tutup layar yang menumpuk (misalnya Register) sebelum ganti halaman.
    Navigator.of(context).popUntil((route) => route.isFirst);
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    if (AuthService.instance.currentSession == null) {
      if (!mounted) return;
      setState(() {
        _profile = null;
        _error = null;
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final p = await AuthService.instance.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = p;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (AuthService.instance.currentSession == null) {
      return const LoginScreen();
    }
    final profile = _profile;
    if (_error != null || profile == null) {
      return _ProfilGagal(
        error: _error,
        onCobaLagi: _muatProfil,
        onKeluar: AuthService.instance.logout,
      );
    }
    return HomeScreen(profile: profile);
  }
}

class _ProfilGagal extends StatelessWidget {
  const _ProfilGagal({
    required this.error,
    required this.onCobaLagi,
    required this.onKeluar,
  });

  final Object? error;
  final VoidCallback onCobaLagi;
  final VoidCallback onKeluar;

  @override
  Widget build(BuildContext context) {
    final pesan = error != null
        ? AuthService.pesanError(error!)
        : 'Akun ini belum punya profil. Hubungi owner.';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 40),
                const SizedBox(height: 12),
                Text('Profil akun tidak bisa dimuat',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(pesan, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                FilledButton(onPressed: onCobaLagi, child: const Text('Coba lagi')),
                TextButton(onPressed: onKeluar, child: const Text('Keluar')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
