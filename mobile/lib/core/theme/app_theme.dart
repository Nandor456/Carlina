import 'package:flutter/material.dart';
import '../models/document_model.dart';

abstract class AppTheme {
  static const _seedColor = Color(0xFF1565C0); // Deep blue

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          foregroundColor: Colors.white,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Color(0xCCFFFFFF),
          indicatorColor: Colors.white,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: TextStyle(fontWeight: FontWeight.w600),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(centerTitle: false, elevation: 0),
      );
}

// ── Status colours ────────────────────────────────────────────

extension DocumentStatusColor on DocumentStatus {
  Color get color => switch (this) {
        DocumentStatus.active => const Color(0xFF2E7D32),      // Green 800
        DocumentStatus.expiringSoon => const Color(0xFFF57F17), // Amber 900
        DocumentStatus.expired => const Color(0xFFC62828),     // Red 800
      };

  Color get lightColor => switch (this) {
        DocumentStatus.active => const Color(0xFFE8F5E9),
        DocumentStatus.expiringSoon => const Color(0xFFFFF8E1),
        DocumentStatus.expired => const Color(0xFFFFEBEE),
      };

  String get label => switch (this) {
        DocumentStatus.active => 'Valid',
        DocumentStatus.expiringSoon => 'Expiring Soon',
        DocumentStatus.expired => 'Expired',
      };

  IconData get icon => switch (this) {
        DocumentStatus.active => Icons.check_circle_rounded,
        DocumentStatus.expiringSoon => Icons.warning_amber_rounded,
        DocumentStatus.expired => Icons.cancel_rounded,
      };
}
