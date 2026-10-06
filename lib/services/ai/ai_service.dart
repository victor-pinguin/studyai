import '../../core/app_config.dart';
import '../../models/explanation.dart';
import '../../models/quiz.dart';
import 'api_ai_service.dart';
import 'mock_ai_service.dart';

/// Schnittstelle für alle KI-Funktionen.
///
/// Die App kennt nur diese Schnittstelle. Ob dahinter die kostenlose
/// Demo-KI ([MockAiService]) oder später eine echte KI ([ApiAiService])
/// steckt, ist für die Screens egal.
abstract class AiService {
  /// Erklärt eine Aufgabe Schritt für Schritt.
  /// [detailed] = ausführlichere Erklärungen (Pro).
  Future<Explanation> explain(String taskText, {bool detailed = false});

  /// Erstellt [count] Quizfragen (3–10) passend zur Aufgabe.
  Future<List<QuizQuestion>> createQuiz(String taskText, {int count = 5});
}

/// Wählt automatisch die richtige KI.
AiService createAiService() {
  if (AppConfig.useDemoAi) return MockAiService();
  return ApiAiService(baseUrl: AppConfig.aiApiBaseUrl);
}
