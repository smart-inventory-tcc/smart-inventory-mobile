import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user.dart';
import '../services/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
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
      duration: const Duration(milliseconds: 550),
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).loginAction(
          _usernameController.text.trim(),
          _passwordController.text.trim(),
        );
  }

  void _navigateToDashboard(User user) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (ctx, anim, secondAnim) => DashboardScreen(
          apiService: ref.read(apiServiceProvider),
          user: user,
        ),
        transitionsBuilder: (ctx, a, secondAnim, c) =>
            FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ── Listen perubahan auth state ───────────────────────────────────────────
    ref.listen<AsyncValue<User?>>(authProvider, (previous, next) {
      if (!mounted) return;

      next.when(
        data: (user) {
          if (user != null) _navigateToDashboard(user);
        },
        loading: () {},
        error: (e, _) {
          ScaffoldMessenger.of(context)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(e.toString())));
        },
      );
    });

    // isLoading: true saat AsyncLoading atau saat state masih awal & ada token
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeIn,
          child: Center(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Logo / Icon ──────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cs.primary.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        Icons.inventory_2_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Judul ─────────────────────────────────────────────────
                  Text(
                    'Smart Inventory',
                    style: tt.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Masuk ke akun Anda',
                    style: tt.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // ── Form ──────────────────────────────────────────────────
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _usernameController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            prefixIcon: Icon(Icons.person_outline_rounded),
                          ),
                          textInputAction: TextInputAction.next,
                          validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Username diperlukan'
                                  : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          style: TextStyle(color: cs.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon:
                                const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                              ),
                              onPressed: () => setState(() =>
                                  _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          validator: (v) => v == null || v.isEmpty
                              ? 'Password diperlukan'
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // ── Tombol Login ───────────────────────────────────
                        AnimatedScale(
                          scale: isLoading ? 0.97 : 1.0,
                          duration: const Duration(milliseconds: 120),
                          child: FilledButton(
                            onPressed: isLoading ? null : _login,
                            style: FilledButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 15),
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
                                : const Text('Masuk'),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Navigasi ke Register ───────────────────────────
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.of(context).push(
                                    PageRouteBuilder(
                                      transitionDuration:
                                          const Duration(milliseconds: 350),
                                      pageBuilder:
                                          (ctx, anim, secondAnim) =>
                                              const RegisterScreen(),
                                      transitionsBuilder:
                                          (ctx, a, secondAnim, c) =>
                                              FadeTransition(
                                                  opacity: a, child: c),
                                    ),
                                  ),
                          child: const Text(
                              'Belum punya akun? Daftar di sini'),
                        ),

                        const SizedBox(height: 20),
                        Divider(color: cs.outline),
                        const SizedBox(height: 12),

                        // ── Hint demo ──────────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 14,
                                color: cs.secondary.withValues(alpha: 0.7)),
                            const SizedBox(width: 6),
                            Text(
                              'Demo: owner / password123',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.secondary.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
