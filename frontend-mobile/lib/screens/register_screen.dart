// FITUR REGISTRASI DINONAKTIFKAN
// Semua akun staff dibuat oleh Owner melalui panel admin.
// File ini dipertahankan agar tidak ada breaking import, namun tidak digunakan.

import 'package:flutter/material.dart';

/// Stub — tidak digunakan di aplikasi mobile.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Fitur registrasi tidak tersedia.')),
    );
  }
}
