import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized design system for the AI CV Analyzer.
///
/// Futuristic dark-blue palette with a glowing cyan accent, glassmorphism
/// helpers, and reusable text styles. Everything the rest of the app needs
/// to "look right" lives here.
class AppColors {
  AppColors._();

  // Core backgrounds
  static const Color bgDeep = Color(0xFF0B132B);
  static const Color bgMid = Color(0xFF1C2541);
  static const Color bgElevated = Color(0xFF243358);

  // Accent
  static const Color accent = Color(0xFF48CAE4);
  static const Color accentGlow = Color(0x6648CAE4);
  static const Color accentDim = Color(0xFF2A9D8F);

  // Semantic
  static const Color success = Color(0xFF4ADE80);
  static const Color warning = Color(0xFFFACC15);
  static const Color error = Color(0xFFF87171);
  static const Color danger = Color(0xFFFB7185);

  // Neutrals
  static const Color textPrimary = Color(0xFFE8EEF7);
  static const Color textSecondary = Color(0xFF9FB3C8);
  static const Color textMuted = Color(0xFF6B7A99);
  static const Color border = Color(0x3348CAE4);
  static const Color glassFill = Color(0x14FFFFFF);
  static const Color glassStroke = Color(0x33FFFFFF);
}

/// Maps an ATS score (0-100) to a semantic color.
Color scoreColor(double score) {
  if (score < 50) return AppColors.error;
  if (score < 75) return AppColors.warning;
  return AppColors.success;
}

class AppTheme {
  AppTheme._();

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgDeep,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accent,
        secondary: AppColors.accentDim,
        surface: AppColors.bgMid,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.spaceGroteskTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.15,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgMid,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.glassStroke, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }

  /// A linear gradient used for glowing CTA buttons and accents.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF48CAE4), Color(0xFF2A9D8F)],
  );

  /// A subtle radial glow used behind hero elements.
  static const RadialGradient accentGlow = RadialGradient(
    colors: [Color(0x5548CAE4), Colors.transparent],
    stops: [0.0, 1.0],
  );

  /// Standard rounded-corner radius used across glass containers.
  static const double kRadius = 20;
}

/// Reusable glassmorphism box decoration. Pair with [GlassContainer] for the
/// BackdropFilter blur; this is the visual layer painted on top.
BoxDecoration glassDecoration({
  Color? color,
  Border? border,
  List<BoxShadow>? shadows,
  double radius = AppTheme.kRadius,
  Gradient? gradient,
}) {
  return BoxDecoration(
    color: color ?? AppColors.glassFill,
    borderRadius: BorderRadius.circular(radius),
    border: border ??
        Border.all(color: AppColors.glassStroke, width: 1),
    boxShadow: shadows ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
    gradient: gradient,
  );
}
