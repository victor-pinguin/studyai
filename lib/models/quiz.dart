import 'subject.dart';

/// Eine Quizfrage mit Antwortmöglichkeiten.
class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correctIndex;

  /// Wird nach dem Antworten angezeigt.
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
        question: json['question'] as String? ?? '',
        options: (json['options'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        correctIndex: json['correctIndex'] as int? ?? 0,
        explanation: json['explanation'] as String? ?? '',
      );
}

/// Ergebnis eines abgeschlossenen Quiz.
class QuizResult {
  const QuizResult({
    required this.id,
    required this.taskId,
    required this.taskTitle,
    required this.subject,
    required this.correct,
    required this.total,
    required this.date,
  });

  final String id;
  final String? taskId;
  final String taskTitle;
  final Subject subject;
  final int correct;
  final int total;
  final DateTime date;

  int get percent => total == 0 ? 0 : ((correct / total) * 100).round();

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'taskTitle': taskTitle,
        'subject': subject.name,
        'correct': correct,
        'total': total,
        'date': date.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
        id: json['id'] as String,
        taskId: json['taskId'] as String?,
        taskTitle: json['taskTitle'] as String? ?? 'Quiz',
        subject: Subject.fromName(json['subject'] as String?),
        correct: json['correct'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        date: DateTime.tryParse(json['date'] as String? ?? '') ??
            DateTime.now(),
      );
}
