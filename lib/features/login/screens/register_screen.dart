import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/validators.dart';
import '../services/auth_service.dart';

/// Register khusus penghuni. Akun owner dibuat manual di Supabase.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  final _password = TextEditingController();
  final _konfirmasi = TextEditingController();
  bool _sembunyi = true;
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    _username.dispose();
    _email.dispose();
    _noHp.dispose();
    _password.dispose();
    _konfirmasi.dispose();
    super.dispose();
  }

  void _tampilPesan(String pesan) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _daftar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final username = _username.text.trim().toLowerCase();
      final email = _email.text.trim();

      final bebas = await AuthService.instance.isUsernameAvailable(username);
      if (!mounted) return;
      if (!bebas) {
        _tampilPesan('Username "$username" sudah dipakai. Pilih username lain.');
        return;
      }

      final res = await AuthService.instance.register(
        nama: _nama.text,
        username: username,
        email: email,
        noHp: _noHp.text,
        password: _password.text,
      );
      if (!mounted) return;

      // Kalau verifikasi email dimatikan di Supabase, sesi langsung ada dan
      // AuthGate sendiri membuka menu utama.
      if (res.session != null) return;

      await _dialogCekEmail(email, username);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _tampilPesan(AuthService.pesanError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _dialogCekEmail(String email, String username) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Cek email kamu'),
        content: Text(
          'Link verifikasi sudah dikirim ke $email. '
          'Klik link itu, lalu masuk dengan username "$username".',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ke halaman masuk'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar penghuni')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Buat akun penghuni',
                      style: tema.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nama,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(labelText: 'Nama lengkap'),
                      validator: Validators.nama,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _username,
                      enabled: !_loading,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newUsername],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9._]')),
                        LengthLimitingTextInputFormatter(20),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        helperText: 'Dipakai untuk masuk. Huruf kecil, angka, titik, garis bawah.',
                      ),
                      validator: Validators.username,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: Validators.email,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _noHp,
                      enabled: !_loading,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9+]')),
                        LengthLimitingTextInputFormatter(16),
                      ],
                      decoration: const InputDecoration(labelText: 'Nomor HP'),
                      validator: Validators.noHp,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: _sembunyi,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        helperText: 'Minimal 8 karakter.',
                        suffixIcon: IconButton(
                          tooltip: _sembunyi
                              ? 'Tampilkan password'
                              : 'Sembunyikan password',
                          icon: Icon(_sembunyi
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () =>
                              setState(() => _sembunyi = !_sembunyi),
                        ),
                      ),
                      validator: Validators.password,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _konfirmasi,
                      enabled: !_loading,
                      obscureText: _sembunyi,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _daftar(),
                      decoration: const InputDecoration(
                        labelText: 'Ulangi password',
                      ),
                      validator: (v) =>
                          Validators.konfirmasiPassword(v, _password.text),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                      ),
                      onPressed: _loading ? null : _daftar,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5),
                            )
                          : const Text('Daftar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
