import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

/// Semua urusan login/register/logout lewat file ini.
/// Kalau nanti metode login diganti (email, nomor HP), cukup ubah [login] di sini.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final SupabaseClient _db = Supabase.instance.client;

  Stream<AuthState> get authChanges => _db.auth.onAuthStateChange;
  Session? get currentSession => _db.auth.currentSession;

  /// Apakah [username] masih bebas dipakai?
  Future<bool> isUsernameAvailable(String username) async {
    final res = await _db.rpc('username_available', params: {
      'p_username': username,
    });
    return res == true;
  }

  /// Daftar sebagai penghuni. Role selalu 'penghuni' (diatur trigger di database).
  Future<AuthResponse> register({
    required String nama,
    required String username,
    required String email,
    required String noHp,
    required String password,
  }) {
    return _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {
        'nama': nama.trim(),
        'username': username.trim().toLowerCase(),
        'no_hp': noHp.trim(),
      },
    );
  }

  /// Login pakai username: cari email-nya dulu, lalu login seperti biasa.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    final email = await _db.rpc('get_login_email', params: {
      'p_username': username.trim(),
    });
    if (email == null) {
      // Pesan sama dengan password salah, supaya username tidak bisa ditebak.
      throw const AuthException('Invalid login credentials');
    }
    await _db.auth.signInWithPassword(
      email: email as String,
      password: password,
    );
  }

  /// Profil (username, nama, role) akun yang sedang login.
  Future<UserProfile?> fetchProfile() async {
    final user = _db.auth.currentUser;
    if (user == null) return null;
    final data =
        await _db.from('profiles').select().eq('id', user.id).maybeSingle();
    if (data == null) return null;
    return UserProfile.fromMap(data);
  }

  Future<void> logout() => _db.auth.signOut();

  /// Ubah error teknis jadi pesan yang bisa dibaca pengguna.
  static String pesanError(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('email not confirmed')) {
        return 'Email belum diverifikasi. Cek inbox, lalu klik link verifikasinya.';
      }
      if (m.contains('invalid login credentials')) {
        return 'Username atau password salah.';
      }
      if (m.contains('already registered') ||
          m.contains('already been registered')) {
        return 'Email ini sudah terdaftar.';
      }
      if (m.contains('database error')) {
        return 'Username sudah dipakai. Pilih username lain.';
      }
      if (m.contains('rate limit')) {
        return 'Terlalu banyak percobaan. Coba lagi beberapa menit lagi.';
      }
      return e.message;
    }
    if (e is PostgrestException) {
      return 'Gagal menghubungi server: ${e.message}';
    }
    return 'Terjadi kesalahan. Periksa koneksi internet, lalu coba lagi.';
  }
}
