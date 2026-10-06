import 'subject.dart';

/// Ein einzelner Erklärschritt.
class ExplanationStep {
  const ExplanationStep({
    required this.title,
    required this.content,
    this.detail,
  });

  final String title;
  final String content;

  /// Zusätzliche „Warum?“-Erklärung (nur Pro / detaillierte Erklärungen).
  final String? detail;

  Map<String, dynamic> toJson() =>
      {'title': title, 'content': content, 'detail': detail};

  factory ExplanationStep.fromJson(Map<String, dynamic> json) =>
      ExplanationStep(
        title: json['title'] as String? ?? '',
        content: json['content'] as String? ?? '',
        detail: json['detail'] as String?,
      );
}

/// Komplette Schritt-für-Schritt-Erklärung einer Aufgabe.
class Explanation {
  const Explanation({
    required this.subject,
    required this.summary,
    required this.steps,
    required this.tip,
    this.solution,
    this.isDemo = false,
  });

  final Subject subject;

  /// Worum geht es in der Aufgabe? (1–2 Sätze)
  final String summary;
  final List<ExplanationStep> steps;

  /// Lern-Tipp am Ende.
  final String tip;

  /// Die Lösung wird erst nach den Schritten auf Wunsch angezeigt.
  final String? solution;

  /// true = von der Platzhalter-KI erzeugt.
  final bool isDemo;

  /// Format, das später auch dein Backend zurückgeben sollte.
  factory Explanation.fromJson(Map<String, dynamic> json) => Explanation(
        subject: Subject.fromName(json['subject'] as String?),
        summary: json['summary'] as String? ?? '',
        steps: (json['steps'] as List<dynamic>? ?? [])
            .map((e) => ExplanationStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        tip: json['tip'] as String? ?? '',
        solution: json['solution'] as String?,
      );
}
