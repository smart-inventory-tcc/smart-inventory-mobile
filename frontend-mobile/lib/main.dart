import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'services/notification_service.dart';

// ─── Palette (Disesuaikan dari Gambar Referensi) ─────────────────────────────
// Primary    : Steel Blue Sweater (Warna utama aplikasi)       #5E7E9B
// Secondary  : Burnt Terracotta Backdrop (Aksen kontras)       #E27D38
// Background : Soft Warm Cream (Latar belakang aplikasi)       #F5EFEB
// Surface    : Pure White (Background untuk Card/Form)         #FFFFFF
// Card       : Muted Warm Beige (Dari swatch palet kiri bawah)  #EFE6DD
// Text High  : Dark Indigo/Navy (Dari warna rambut & bayangan) #151922
// Text Med   : Slate Gray (Untuk subtitle atau text sekunder)  #758291
// Divider    : Light Warm Gray                                 #E3D9CF
// Error      : Muted Rose (Dari aksen makeup mata/bibir)       #C25953
// ────────────────────────────────────────────────────────────────────────────

const Color _kPrimary = Color(0xFF5E7E9B); // Steel Blue (Sweater)
const Color _kSecondary = Color(
  0xFFE27D38,
); // Burnt Terracotta (Background gambar)
const Color _kBg = Color(0xFFF5EFEB); // Soft Warm Cream
const Color _kSurface = Color(0xFFFFFFFF); // Pure White
const Color _kCard = Color(0xFFEFE6DD); // Muted Warm Beige
const Color _kOnPrimary = Color(0xFFFFFFFF); // White text on primary
const Color _kTextHigh = Color(0xFF151922); // Dark Indigo/Navy
const Color _kTextMed = Color(0xFF758291); // Slate Gray
const Color _kDivider = Color(0xFFE3D9CF); // Light Warm Gray
const Color _kError = Color(0xFFC25953); // Muted Rose

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  runApp(const ProviderScope(child: SmartInventoryApp()));
}

class SmartInventoryApp extends StatelessWidget {
  const SmartInventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Inventory UMKM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: _kBg,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: _kPrimary,
          onPrimary: _kOnPrimary,
          secondary: _kSecondary,
          onSecondary: _kOnPrimary,
          error: _kError,
          onError: _kOnPrimary,
          surface: _kSurface,
          onSurface: _kTextHigh,
          surfaceContainerHighest: _kCard,
          outline: _kDivider,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: _kSurface,
          foregroundColor: _kTextHigh,
          surfaceTintColor: Colors.transparent,
          shadowColor: _kDivider,
          titleTextStyle: TextStyle(
            color: _kTextHigh,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: _kCard,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: _kDivider, width: 0.9),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: _kOnPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              letterSpacing: 0.3,
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimary,
            foregroundColor: _kOnPrimary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: _kPrimary),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kSurface,
          labelStyle: const TextStyle(color: _kTextMed),
          hintStyle: const TextStyle(color: _kTextMed),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kDivider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kDivider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kPrimary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _kError),
          ),
          prefixIconColor: _kTextMed,
          suffixIconColor: _kTextMed,
        ),
        dividerTheme: const DividerThemeData(color: _kDivider, thickness: 0.9),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: _kPrimary,
          foregroundColor: _kOnPrimary,
          shape: StadiumBorder(),
          elevation: 3,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: _kTextHigh,
          contentTextStyle: const TextStyle(color: _kSurface),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          behavior: SnackBarBehavior.floating,
        ),
        dropdownMenuTheme: const DropdownMenuThemeData(
          menuStyle: MenuStyle(
            backgroundColor: WidgetStatePropertyAll(_kSurface),
          ),
        ),
        textTheme: const TextTheme(
          headlineSmall: TextStyle(
            color: _kTextHigh,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: _kTextHigh,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: _kTextHigh,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          bodyLarge: TextStyle(color: _kTextHigh, fontSize: 15),
          bodyMedium: TextStyle(color: _kTextMed, fontSize: 13),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
