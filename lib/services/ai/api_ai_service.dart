import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/explanation.dart';
import '../../models/quiz.dart';
import 'ai_service.dart';

/// Vorbereitung für die echte KI (z. B. Claude, OpenAI, Gemini).
///
/// WICHTIG: Den API-Schlüssel NIEMALS in die App einbauen – Apps können
/// entpackt werden. Stattdessen ruft die App dein eigenes kleines Backend auf
/// (z. B. Firebase Cloud Function, Supabase Edge Function, Cloudflare Worker).
/// Das Backend kennt den Schlüssel, spricht mit der KI und gibt JSON zurück.
///
/// Erwartetes JSON vom Backend:
///
/// POST {baseUrl}/explain   Body: {"text": "...", "detailed": true}
/// Antwort:
/// {
///   "subject": "math",
///   "summary": "...",
///   "steps": [{"title": "...", "content": "...", "detail": "..."}],
///   "tip": "...",
///   "solution": "..."
/// }
///
/// POST {baseUrl}/quiz      Body: {"text": "...", "count": 5}
/// Antwort:
/// {"questions": [{"question": "...", "options": ["A","B","C","D"],
///                 "correctIndex": 0, "explanation": "..."}]}
class ApiAiService implements AiService {
  ApiAiService({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  // Später: Login-Token (z. B. Firebase Auth) mitsenden.
  Map<String, String> get _headers => {'Content-Type': 'application/json'};

  @override
  Future<Explanation> explain(String taskText, {bool detailed = false}) async {
    final json = await _post('/explain', {'text': taskText, 'detailed': detailed});
    return Explanation.fromJson(json);
  }

  @override
  Future<List<QuizQuestion>> createQuiz(String taskText, {int count = 5}) async {
    final json = await _post('/quiz', {'text': taskText, 'count': count});
    return (json['questions'] as List<dynamic>)
        .map((q) => QuizQuestion.fromJson(q as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await _client
        .post(
          Uri.parse('$baseUrl$path'),
          headers: _headers,
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw Exception('KI-Server Fehler ${response.statusCode}');
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }
}
