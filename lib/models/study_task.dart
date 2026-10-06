import 'subject.dart';

/// Eine Aufgabe, die der Nutzer fotografiert oder eingetippt hat.
class StudyTask {
  const StudyTask({
    required this.id,
    required this.text,
    required this.subject,
    required this.createdAt,
    this.explained = false,
    this.bestQuizPercent,
  });

  final String id;
  final String text;
  final Subject subject;
  final DateTime createdAt;

  /// Wurde die Aufgabe schon erklärt? (= „gelöste Aufgabe“ in der Statistik)
  final bool explained;

  /// Bestes Quiz-Ergebnis in Prozent (null = noch kein Quiz).
  final int? bestQuizPercent;

  /// Kurzer Titel für Listen (erste Zeile, max. 60 Zeichen).
  String get title {
    final firstLine = text.trim().split('\n').first.trim();
    if (firstLine.isEmpty) return 'Aufgabe';
    return firstLine.length > 60 ? '${firstLine.substring(0, 57)}...' : firstLine;
  }

  StudyTask copyWith({
    String? text,
    Subject? subject,
    bool? explained,
    int? bestQuizPercent,
  }) {
    return StudyTask(
      id: id,
      text: text ?? this.text,
      subject: subject ?? this.subject,
      createdAt: createdAt,
      explained: explained ?? this.explained,
      bestQuizPercent: bestQuizPercent ?? this.bestQuizPercent,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'subject': subject.name,
        'createdAt': createdAt.toIso8601String(),
        'explained': explained,
        'bestQuizPercent': bestQuizPercent,
      };

  factory StudyTask.fromJson(Map<String, dynamic> json) => StudyTask(
        id: json['id'] as String,
        text: json['text'] as String? ?? '',
        subject: Subject.fromName(json['subject'] as String?),
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
        explained: json['explained'] as bool? ?? false,
        bestQuizPercent: json['bestQuizPercent'] as int?,
      );
}
