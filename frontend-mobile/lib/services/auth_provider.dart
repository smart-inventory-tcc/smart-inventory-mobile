import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import 'api_service.dart';

// ── Singleton ApiService Provider ────────────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

// ── AuthNotifier — state: AsyncValue<User?> ───────────────────────────────────
//
// null  → belum login / sudah logout
// User  → berhasil login
// AsyncLoading → sedang proses
// AsyncError   → gagal (pesan error bisa langsung ditampilkan ke UI)

class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final ApiService _api;

  AuthNotifier(this._api) : super(const AsyncData(null)) {
    _restoreSession();
  }

  // Saat app dibuka: validasi token tersimpan via GET /auth/profile
  Future<void> _restoreSession() async {
    final token = await _api.readToken();
    if (token == null || token.isEmpty) return; // tetap AsyncData(null)

    try {
      final user = await _api.getProfile();
      state = AsyncData(user);
    } catch (_) {
      // Token kadaluarsa / tidak valid — bersihkan
      await _api.clearToken();
    }
  }

  /// Login — set AsyncLoading → panggil login → simpan token → fetch profile → AsyncData(user)
  Future<void> loginAction(String username, String password) async {
    state = const AsyncLoading();
    try {
      // 1. Login → dapat token, disimpan otomatis oleh ApiService
      await _api.login(username, password);

      // 2. Ambil data profil lengkap dengan token yang baru
      final user = await _api.getProfile();
      state = AsyncData(user);
    } catch (e, st) {
      // e adalah String error dari backend (misal: "Invalid credentials")
      state = AsyncError(e, st);
    }
  }


  /// Logout — hapus token dan reset ke null
  Future<void> logout() async {
    await _api.clearToken();
    state = const AsyncData(null);
  }
}

// ── Riverpod Provider ─────────────────────────────────────────────────────────
final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(apiServiceProvider));
});
