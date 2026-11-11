/// Aturan validasi form. Dipakai di layar login dan register.
class Validators {
  static String? wajib(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label wajib diisi';
    return null;
  }

  static String? nama(String? v) {
    final e = wajib(v, 'Nama');
    if (e != null) return e;
    if (v!.trim().length < 3) return 'Nama minimal 3 karakter';
    return null;
  }

  static final RegExp _usernameRegex = RegExp(r'^[a-z0-9._]{4,20}$');

  static String? username(String? v) {
    final e = wajib(v, 'Username');
    if (e != null) return e;
    if (!_usernameRegex.hasMatch(v!.trim().toLowerCase())) {
      return 'Username 4-20 karakter: huruf, angka, titik, atau garis bawah';
    }
    return null;
  }

  static final RegExp _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String? v) {
    final e = wajib(v, 'Email');
    if (e != null) return e;
    if (!_emailRegex.hasMatch(v!.trim())) return 'Format email tidak valid';
    return null;
  }

  static final RegExp _hpRegex = RegExp(r'^(\+62|62|0)[0-9]{8,13}$');

  static String? noHp(String? v) {
    final e = wajib(v, 'Nomor HP');
    if (e != null) return e;
    if (!_hpRegex.hasMatch(v!.trim())) {
      return 'Nomor HP tidak valid (contoh: 081234567890)';
    }
    return null;
  }

  static String? password(String? v) {
    final e = wajib(v, 'Password');
    if (e != null) return e;
    if (v!.length < 8) return 'Password minimal 8 karakter';
    return null;
  }

  static String? konfirmasiPassword(String? v, String passwordAsli) {
    final e = wajib(v, 'Konfirmasi password');
    if (e != null) return e;
    if (v != passwordAsli) return 'Password tidak sama';
    return null;
  }
}
