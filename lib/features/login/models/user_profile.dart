/// Profil akun yang sedang login (baris tabel `profiles`).
/// Anggota lain: pakai [id] sebagai foreign key ke penghuni/owner.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.nama,
    required this.role,
    this.noHp,
  });

  static const String roleOwner = 'owner';
  static const String rolePenghuni = 'penghuni';

  final String id;
  final String username;
  final String nama;
  final String? noHp;
  final String role;

  bool get isOwner => role == roleOwner;
  bool get isPenghuni => role == rolePenghuni;
  String get labelRole => isOwner ? 'Owner' : 'Penghuni';

  factory UserProfile.fromMap(Map<String, dynamic> m) {
    return UserProfile(
      id: m['id'] as String,
      username: m['username'] as String,
      nama: m['nama'] as String,
      noHp: m['no_hp'] as String?,
      role: m['role'] as String,
    );
  }
}
