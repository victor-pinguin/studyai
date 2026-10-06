/// Zentrale Konfiguration der App.
///
/// Hier werden Limits der kostenlosen Version und der Pro-Version festgelegt.
/// Wenn du später Preise oder Limits ändern willst, musst du nur diese Datei
/// anpassen.
class AppConfig {
  AppConfig._();

  static const String appName = 'StudySnap AI';

  /// URL deines eigenen KI-Backends (später).
  ///
  /// Leer = Demo-Modus mit Platzhalter-KI (0 €).
  /// Setzen beim Starten:
  ///   flutter run --dart-define=AI_API_URL=https://dein-backend.de/api
  static const String aiApiBaseUrl = String.fromEnvironment('AI_API_URL');

  static bool get useDemoAi => aiApiBaseUrl.isEmpty;

  static const int minQuizQuestions = 3;
  static const int maxQuizQuestions = 10;
}

/// Limits pro Tarif. Die kostenlose Version bleibt sinnvoll nutzbar.
class PlanLimits {
  const PlanLimits({
    required this.dailyAiRequests,
    required this.maxQuizQuestions,
    required this.maxImageDimension,
    required this.detailedExplanations,
    required this.advancedStats,
    required this.learningPlans,
  });

  /// KI-Anfragen pro Tag (Erklären und Quiz zählen je 1 Anfrage).
  final int dailyAiRequests;

  /// Maximale Anzahl Quizfragen.
  final int maxQuizQuestions;

  /// Maximale Bildkantenlänge in Pixeln (größer = bessere Erkennung).
  final double maxImageDimension;

  final bool detailedExplanations;
  final bool advancedStats;
  final bool learningPlans;

  static const free = PlanLimits(
    dailyAiRequests: 15,
    maxQuizQuestions: 5,
    maxImageDimension: 1600,
    detailedExplanations: false,
    advancedStats: false,
    learningPlans: false,
  );

  static const pro = PlanLimits(
    dailyAiRequests: 200,
    maxQuizQuestions: 10,
    maxImageDimension: 3000,
    detailedExplanations: true,
    advancedStats: true,
    learningPlans: true,
  );
}
