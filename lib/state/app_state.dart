import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../core/sounds.dart';
import '../core/utils.dart';
import '../models/quiz.dart';
import '../models/reward.dart';
import '../models/study_task.dart';
import '../models/vocab.dart';
import '../models/subject.dart';
import '../services/storage/study_repository.dart';

/// Zentraler App-Zustand: Aufgaben, Quiz-Ergebnisse, Einstellungen, Limits.
///
/// Screens lesen mit `context.watch<AppState>()` und rufen Methoden mit
/// `context.read<AppState>()` auf.
class AppState extends ChangeNotifier {
  AppState(this._repo);

  final StudyRepository _repo;

  List<StudyTask> _tasks = [];
  List<QuizResult> _quizResults = [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _isPro = false;
  String _usageDay = '';
  int _usageCount = 0;
  List<EarnedSticker> _rewards = [];
  int _bonusStars = 0;
  LearnLanguage _learnLanguage = LearnLanguage.italian;
  bool _soundOn = true;
  int _perfectCount = 0;

  // ---------------------------------------------------------------------------
  // Laden & Speichern
  // ---------------------------------------------------------------------------

  Future<void> load() async {
    _tasks = await _repo.loadTasks();
    _quizResults = await _repo.loadQuizResults();
    final s = await _repo.loadSettings();
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == s['themeMode'],
      orElse: () => ThemeMode.system,
    );
    _isPro = s['isPro'] as bool? ?? false;
    _usageDay = s['usageDay'] as String? ?? '';
    _usageCount = s['usageCount'] as int? ?? 0;
    _rewards = (s['rewards'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .map(EarnedSticker.decode)
        .whereType<EarnedSticker>()
        .toList();
    _bonusStars = s['bonusStars'] as int? ?? 0;
    _learnLanguage = LearnLanguage.byName(s['learnLanguage'] as String? ?? '');
    _soundOn = s['soundOn'] as bool? ?? true;
    _perfectCount = s['perfectCount'] as int? ?? 0;
    Sounds.instance.enabled = _soundOn;
    notifyListeners();
  }

  Future<void> _saveSettings() => _repo.saveSettings({
        'themeMode': _themeMode.name,
        'isPro': _isPro,
        'usageDay': _usageDay,
        'usageCount': _usageCount,
        'rewards': [for (final r in _rewards) r.encode()],
        'bonusStars': _bonusStars,
        'learnLanguage': _learnLanguage.name,
        'soundOn': _soundOn,
        'perfectCount': _perfectCount,
      });

  // ---------------------------------------------------------------------------
  // Einstellungen: Theme & Pro
  // ---------------------------------------------------------------------------

  ThemeMode get themeMode => _themeMode;

  /// System → Hell → Dunkel → System
  void cycleThemeMode() {
    _themeMode = switch (_themeMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    notifyListeners();
    _saveSettings();
  }

  /// Sprache, die gerade gelernt wird (Italienisch, Englisch, …).
  LearnLanguage get learnLanguage => _learnLanguage;

  void setLearnLanguage(LearnLanguage language) {
    _learnLanguage = language;
    notifyListeners();
    _saveSettings();
  }

  /// Töne und Vibrieren an oder aus.
  bool get soundOn => _soundOn;

  void toggleSound() {
    _soundOn = !_soundOn;
    Sounds.instance.enabled = _soundOn;
    if (_soundOn) Sounds.instance.tap();
    notifyListeners();
    _saveSettings();
  }

  bool get isPro => _isPro;
  PlanLimits get limits => _isPro ? PlanLimits.pro : PlanLimits.free;

  /// Demo: Pro ohne Bezahlung aktivieren.
  /// Später: nur nach erfolgreichem In-App-Kauf (z. B. über RevenueCat).
  void setPro(bool value) {
    _isPro = value;
    notifyListeners();
    _saveSettings();
  }

  // ---------------------------------------------------------------------------
  // Tageslimit für KI-Anfragen
  // ---------------------------------------------------------------------------

  int get usedAiRequestsToday =>
      _usageDay == Utils.dayKey(DateTime.now()) ? _usageCount : 0;

  int get remainingAiRequests {
    final left = limits.dailyAiRequests - usedAiRequestsToday;
    return left < 0 ? 0 : left;
  }

  /// Verbraucht eine KI-Anfrage. Gibt false zurück, wenn das Limit erreicht ist.
  bool tryUseAiRequest() {
    if (remainingAiRequests <= 0) return false;
    final today = Utils.dayKey(DateTime.now());
    if (_usageDay != today) {
      _usageDay = today;
      _usageCount = 0;
    }
    _usageCount++;
    notifyListeners();
    _saveSettings();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Aufgaben
  // ---------------------------------------------------------------------------

  /// Neueste zuerst.
  List<StudyTask> get tasks => List.unmodifiable(_tasks);

  StudyTask? taskById(String id) {
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<StudyTask> addTask(String text) async {
    final task = StudyTask(
      id: Utils.newId(),
      text: text.trim(),
      subject: Subject.detect(text),
      createdAt: DateTime.now(),
    );
    _tasks = [task, ..._tasks];
    notifyListeners();
    await _repo.saveTasks(_tasks);
    return task;
  }

  Future<void> updateTaskText(String id, String text) async {
    await _updateTask(
      id,
      (t) => t.copyWith(text: text.trim(), subject: Subject.detect(text)),
    );
  }

  Future<void> markExplained(String id) =>
      _updateTask(id, (t) => t.copyWith(explained: true));

  Future<void> deleteTask(String id) async {
    _tasks = _tasks.where((t) => t.id != id).toList();
    notifyListeners();
    await _repo.saveTasks(_tasks);
  }

  Future<void> _updateTask(String id, StudyTask Function(StudyTask) change) async {
    _tasks = [for (final t in _tasks) t.id == id ? change(t) : t];
    notifyListeners();
    await _repo.saveTasks(_tasks);
  }

  // ---------------------------------------------------------------------------
  // Quiz
  // ---------------------------------------------------------------------------

  List<QuizResult> get quizResults => List.unmodifiable(_quizResults);

  Future<void> addQuizResult(QuizResult result) async {
    _quizResults = [result, ..._quizResults];
    final taskId = result.taskId;
    if (taskId != null) {
      final task = taskById(taskId);
      if (task != null &&
          (task.bestQuizPercent == null || result.percent > task.bestQuizPercent!)) {
        _tasks = [
          for (final t in _tasks)
            t.id == taskId ? t.copyWith(bestQuizPercent: result.percent) : t,
        ];
        await _repo.saveTasks(_tasks);
      }
    }
    notifyListeners();
    await _repo.saveQuizResults(_quizResults);
  }

  // ---------------------------------------------------------------------------
  // Belohnungen
  // ---------------------------------------------------------------------------

  /// Gesammelte Sticker, neueste zuerst.
  List<EarnedSticker> get rewards => List.unmodifiable(_rewards);

  /// Extra-Sterne aus Belohnungen.
  int get bonusStars => _bonusStars;

  /// Der gesammelte Sticker zu dieser Id – oder null, wenn noch nicht erspielt.
  EarnedSticker? earnedSticker(String id) {
    for (final r in _rewards) {
      if (r.stickerId == id) return r;
    }
    return null;
  }

  /// Wie oft schon alles richtig war.
  int get perfectCount => _perfectCount;

  /// Belohnung nach einem Quiz: Gold bei 100 %, Silber ab 80 %.
  /// Gibt null zurück, wenn es (noch) keine Belohnung gibt.
  Future<Reward?> grantReward(int percent) async {
    if (percent < 80) return null;
    final tier = percent >= 100 ? RewardTier.gold : RewardTier.silver;
    if (percent >= 100) _perfectCount++;
    final bonus = tier == RewardTier.gold ? 2 : 1;
    Sticker? next;
    for (final s in Sticker.all) {
      if (earnedSticker(s.id) == null) {
        next = s;
        break;
      }
    }
    if (next != null) {
      _rewards = [EarnedSticker(stickerId: next.id, tier: tier), ..._rewards];
    }
    _bonusStars += bonus;
    notifyListeners();
    await _saveSettings();
    return Reward(tier: tier, bonusStars: bonus, sticker: next);
  }

  // ---------------------------------------------------------------------------
  // Statistik
  // ---------------------------------------------------------------------------

  int get solvedCount => _tasks.where((t) => t.explained).length;

  /// Sterne für ein Quiz-Ergebnis: 3 Sterne ab 90 %, 2 ab 70 %, 1 ab 40 %.
  static int starsFor(int percent) =>
      percent >= 90 ? 3 : percent >= 70 ? 2 : percent >= 40 ? 1 : 0;

  /// Gesammelte Sterne: 1 pro verstandener Aufgabe + Quiz-Sterne + Belohnungen.
  int get starCount =>
      solvedCount +
      _bonusStars +
      _quizResults.fold<int>(0, (s, r) => s + starsFor(r.percent));

  /// Level: alle 5 Sterne ein neues Level.
  int get starLevel => starCount ~/ 5 + 1;
  int get starsInLevel => starCount % 5;
  int get quizCount => _quizResults.length;

  int get averageQuizPercent {
    if (_quizResults.isEmpty) return 0;
    final sum = _quizResults.fold<int>(0, (s, r) => s + r.percent);
    return (sum / _quizResults.length).round();
  }

  /// Punkte: 10 pro erklärter Aufgabe, 5 pro richtiger Quiz-Antwort.
  int get xp =>
      solvedCount * 10 + _quizResults.fold<int>(0, (s, r) => s + r.correct * 5);

  int get level => xp ~/ 100 + 1;
  double get levelProgress => (xp % 100) / 100;

  /// Aktivitäten (Aufgaben + Quizze) der letzten 7 Tage, ältester Tag zuerst.
  List<(DateTime, int)> get activityLast7Days {
    final today = Utils.dayOnly(DateTime.now());
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final key = Utils.dayKey(day);
      final count = _tasks.where((t) => Utils.dayKey(t.createdAt) == key).length +
          _quizResults.where((r) => Utils.dayKey(r.date) == key).length;
      return (day, count);
    });
  }

  /// Tage in Folge mit mindestens einer Aktivität (heute oder bis gestern).
  int get streakDays {
    final activeDays = <String>{
      ..._tasks.map((t) => Utils.dayKey(t.createdAt)),
      ..._quizResults.map((r) => Utils.dayKey(r.date)),
    };
    var day = Utils.dayOnly(DateTime.now());
    if (!activeDays.contains(Utils.dayKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (activeDays.contains(Utils.dayKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Meilensteine der Übungs-Flamme.
  static const List<int> streakMilestones = [3, 7, 14, 30];

  /// Name der aktuellen Flammen-Stufe.
  String get streakLabel {
    final d = streakDays;
    if (d >= 30) return 'Drachenfeuer';
    if (d >= 14) return 'Feuerball';
    if (d >= 7) return 'Flamme';
    if (d >= 3) return 'Feuerchen';
    return 'Funke';
  }

  /// Nächster Meilenstein – null, wenn schon alle erreicht sind.
  int? get nextStreakMilestone {
    for (final m in streakMilestones) {
      if (streakDays < m) return m;
    }
    return null;
  }

  /// Längste Übungs-Serie, die es je gab.
  int get bestStreakDays {
    final days = <DateTime>{
      ..._tasks.map((t) => Utils.dayOnly(t.createdAt)),
      ..._quizResults.map((r) => Utils.dayOnly(r.date)),
    }.toList()
      ..sort();
    var best = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      final hours = prev == null ? 0 : d.difference(prev).inHours;
      run = (hours >= 20 && hours <= 28) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }

  /// War an diesem Tag etwas los? (für die Flammen-Punkte der Woche)
  bool wasActiveOn(DateTime day) {
    final key = Utils.dayKey(day);
    return _tasks.any((t) => Utils.dayKey(t.createdAt) == key) ||
        _quizResults.any((r) => Utils.dayKey(r.date) == key);
  }

  /// Durchschnittliches Quiz-Ergebnis pro Fach (Pro-Statistik).
  Map<Subject, int> get averagePercentBySubject {
    final map = <Subject, List<int>>{};
    for (final r in _quizResults) {
      map.putIfAbsent(r.subject, () => []).add(r.percent);
    }
    return {
      for (final e in map.entries)
        e.key: (e.value.reduce((a, b) => a + b) / e.value.length).round(),
    };
  }

  /// Sehr einfacher persönlicher Lernplan (Pro). Später: von der KI erstellt.
  List<String> get learningPlan {
    final bySubject = averagePercentBySubject;
    if (bySubject.isEmpty && _tasks.isEmpty) {
      return ['Fotografiere deine erste Aufgabe – dann erstelle ich deinen Plan.'];
    }
    final weak = bySubject.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    final focus = weak.isNotEmpty ? weak.first.key : _tasks.first.subject;
    return [
      'Heute: 15 Min. ${focus.label} – eine Aufgabe erklären lassen und nachrechnen.',
      'Morgen: Quiz zu ${focus.label} mit 5 Fragen. Ziel: mindestens 80 %.',
      'In 3 Tagen: Die Aufgaben von heute ohne Hilfe wiederholen.',
      'Wochenende: Alle Aufgaben mit weniger als 70 % im Quiz erneut üben.',
    ];
  }
}
