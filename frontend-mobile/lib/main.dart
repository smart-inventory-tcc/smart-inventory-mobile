import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const SmartInventoryApp());
}

class SmartInventoryApp extends StatelessWidget {
  const SmartInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiService = ApiService();
    return MaterialApp(
      title: 'Smart Inventory UMKM',
      theme: ThemeData(
        useMaterial3: true,
        // Monochrome minimal theme
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black87),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black12),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      home: LoginScreen(apiService: apiService),
    );
  }
}
