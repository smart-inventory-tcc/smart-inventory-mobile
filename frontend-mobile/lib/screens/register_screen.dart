import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_provider.dart';
import 'dashboard_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late final AnimationController _animController;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }



  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Password diperlukan';
    if (v.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    // registerAction hanya butuh 3 parameter sesuai endpoint /auth/register
    await ref.read(authProvider.notifier).registerAction(
      _usernameController.text.trim(),
      _passwordController.text,
      'STAFF', // semua pendaftar dari mobile otomatis STAFF
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Dengarkan auth state untuk navigasi & error (AsyncValue<User?>)
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (!mounted) return;
      next.when(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 500),
                pageBuilder: (ctx, anim, secondAnim) => DashboardScreen(
                  apiService: ref.read(apiServiceProvider),
                  user: user,
                ),
                transitionsBuilder: (ctx, a, secondAnim, c) =>
                    FadeTransition(opacity: a, child: c),
              ),
            );
          }
        },
        loading: () {},
        error: (e, _) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(e.toString())));
        },
      );
    });

    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: FadeTransition(
        opacity: _fadeIn,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──────────────────────────────────────────────────
                Center(
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4), width: 1.5),
                    ),
                    child: Icon(Icons.person_add_rounded,
                        size: 28, color: cs.primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Buat Akun Pegawai',
                  style: tt.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi data di bawah untuk mendaftarkan akun baru',
                  style: tt.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // ── Username ──────────────────────────────────────────────
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(color: cs.onSurface),
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Username diperlukan'
                      : null,
                ),
                const SizedBox(height: 12),

                // ── Password ──────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  style: TextStyle(color: cs.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  validator: _validatePassword,
                ),
                const SizedBox(height: 28),

                // ── Tombol Daftar ─────────────────────────────────────────
                AnimatedScale(
                  scale: isLoading ? 0.97 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: FilledButton(
                    onPressed: isLoading ? null : _register,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Daftar Akun',
                            style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 12),

                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text('Kembali ke Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

