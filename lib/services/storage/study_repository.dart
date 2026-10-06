import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/quiz.dart';
import '../../models/study_task.dart';

/// Speicher-Schnittstelle.
///
/// Heute: lokal auf dem Gerät ([LocalStudyRepository]).
/// Später: z. B. `FirebaseStudyRepository` oder `SupabaseStudyRepository`
/// mit Benutzerkonto und Cloud-Sync – die Screens bleiben unverändert.
abstract class StudyRepository {
  Future<List<StudyTask>> loadTasks();
  Future<void> saveTasks(List<StudyTask> tasks);

  Future<List<QuizResult>> loadQuizResults();
  Future<void> saveQuizResults(List<QuizResult> results);

  Future<Map<String, dynamic>> loadSettings();
  Future<void> saveSettings(Map<String, dynamic> settings);
}

class LocalStudyRepository implements StudyRepository {
  LocalStudyRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _tasksKey = 'tasks_v1';
  static const _quizKey = 'quiz_results_v1';
  static const _settingsKey = 'settings_v1';

  @override
  Future<List<StudyTask>> loadTasks() async => _readList(_tasksKey)
      .map(StudyTask.fromJson)
      .toList();

  @override
  Future<void> saveTasks(List<StudyTask> tasks) =>
      _prefs.setString(_tasksKey, jsonEncode(tasks.map((t) => t.toJson()).toList()));

  @override
  Future<List<QuizResult>> loadQuizResults() async => _readList(_quizKey)
      .map(QuizResult.fromJson)
      .toList();

  @override
  Future<void> saveQuizResults(List<QuizResult> results) =>
      _prefs.setString(_quizKey, jsonEncode(results.map((r) => r.toJson()).toList()));

  @override
  Future<Map<String, dynamic>> loadSettings() async {
    final raw = _prefs.getString(_settingsKey);
    if (raw == null) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> saveSettings(Map<String, dynamic> settings) =>
      _prefs.setString(_settingsKey, jsonEncode(settings));

  List<Map<String, dynamic>> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .toList();
    } catch (_) {
      return []; // defekte Daten nicht zum Absturz führen lassen
    }
  }
}
