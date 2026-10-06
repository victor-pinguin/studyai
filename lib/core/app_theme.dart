import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design-System der App: Farben, Schriften, Radien, Light & Dark Mode.
///
/// Kinderfreundlich: runde Formen, große Schrift, freundliche Farben.
///  * Fredoka – Überschriften und Buttons (rund und verspielt)
///  * Nunito – Fließtext (sehr gut lesbar)
///  * DM Mono – Formeln und Zahlen
class AppTheme {
  AppTheme._();

  // Markenfarben
  static const Color violet = Color(0xFF7C5CFF); // Grape
  static const Color sky = Color(0xFF38BDF8);
  static const Color sun = Color(0xFFFFC53D);
  static const Color leaf = Color(0xFF35C77A);
  static const Color coral = Color(0xFFFF7A59);
  static const Color bubblegum = Color(0xFFFF7AB6);

  // Ältere Namen bleiben gültig, damit nichts bricht
  static const Color magenta = Color(0xFF5B8DFF);
  static const Color pink = bubblegum;
  static const Color mint = leaf;
  static const Color amber = sun;

  // Alte Namen bleiben gültig, damit nichts bricht
  static const Color primary = violet;
  static const Color secondary = sky;
  static const Color success = mint;
  static const Color error = coral;
  static const Color warning = amber;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [violet, Color(0xFF5B8DFF), sky],
    stops: [0, .5, 1],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [leaf, Color(0xFF8BD94B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Sonnen-Verlauf für „Sterne“-Aktionen und Plus.
  static const LinearGradient sunGradient = LinearGradient(
    colors: [sun, Color(0xFFFF9A3D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proGradient = LinearGradient(
    colors: [Color(0xFF3B2E80), Color(0xFF5B3FB8), violet],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Radien – bewusst groß und rund
  static const double rCard = 26;
  static const double rButton = 22;
  static const double rSmall = 18;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: violet,
      brightness: brightness,
      primary: isDark ? const Color(0xFFA996FF) : violet,
      secondary: sky,
    );

    final base = ThemeData(useMaterial3: true, brightness: brightness);
    final text = GoogleFonts.nunitoTextTheme(base.textTheme).copyWith(
      displaySmall: GoogleFonts.fredoka(
          fontSize: 34, height: 1.1, fontWeight: FontWeight.w600, letterSpacing: -.8),
      headlineMedium: GoogleFonts.fredoka(
          fontSize: 28, height: 1.15, fontWeight: FontWeight.w600, letterSpacing: -.6),
      headlineSmall: GoogleFonts.fredoka(
          fontSize: 24, height: 1.15, fontWeight: FontWeight.w600, letterSpacing: -.5),
      titleLarge: GoogleFonts.fredoka(fontSize: 20, height: 1.25, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.fredoka(fontSize: 17, height: 1.3, fontWeight: FontWeight.w700),
      titleSmall: GoogleFonts.fredoka(fontSize: 15, height: 1.3, fontWeight: FontWeight.w700),
    ).apply(
      bodyColor: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1B2559),
      displayColor: isDark ? const Color(0xFFEAF0FF) : const Color(0xFF1B2559),
    );

    final buttonShape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(rButton));
    final buttonText = GoogleFonts.fredoka(fontSize: 17.5, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF101636) : const Color(0xFFF3F7FF),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: buttonShape,
          textStyle: buttonText,
          backgroundColor: scheme.primary,
          foregroundColor: isDark ? const Color(0xFF161033) : Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: buttonShape,
          textStyle: buttonText,
          side: BorderSide(color: borderColorOf(isDark), width: 2.5),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: buttonText.copyWith(fontSize: 14.5)),
      ),
    );
  }

  /// Kartenfarbe
  static Color cardColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1A2148)
          : Colors.white;

  /// Etwas abgesetzter Hintergrund (z. B. Tipp-Karten, Eingabefelder)
  static Color subtleColor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF222B5C)
          : const Color(0xFFEDF3FF);

  /// Dezente Rahmenfarbe
  static Color borderColor(BuildContext context) =>
      borderColorOf(Theme.of(context).brightness == Brightness.dark);

  static Color borderColorOf(bool isDark) => isDark
      ? Colors.white.withValues(alpha: 0.11)
      : const Color(0xFF1B2559).withValues(alpha: 0.11);

  /// Weicher Schatten unter Karten
  static List<BoxShadow> softShadow(BuildContext context) => [
        BoxShadow(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.black.withValues(alpha: 0.55)
              : const Color(0xFF1B2559).withValues(alpha: 0.12),
          blurRadius: 30,
          offset: const Offset(0, 14),
        ),
      ];

  /// Schrift für Formeln und Zahlen
  static TextStyle mono(BuildContext context, {double size = 15, Color? color}) =>
      GoogleFonts.dmMono(
        fontSize: size,
        height: 1.45,
        color: color ?? Theme.of(context).colorScheme.onSurface,
      );
}
