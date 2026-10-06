import 'package:flutter/material.dart';

/// Fachbereich einer Aufgabe. Wird automatisch erkannt (später durch die KI).
enum Subject {
  math('Mathe', Icons.calculate_rounded, Color(0xFF6C4DFF)),
  language('Sprachen', Icons.translate_rounded, Color(0xFFFF7A59)),
  science('Naturwissenschaften', Icons.science_rounded, Color(0xFF1DB97A)),
  general('Allgemein', Icons.menu_book_rounded, Color(0xFF3FA9F5));

  const Subject(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static Subject fromName(String? name) => Subject.values.firstWhere(
        (s) => s.name == name,
        orElse: () => Subject.general,
      );

  /// Einfache, regelbasierte Erkennung – reicht für die Demo.
  static Subject detect(String text) {
    final t = text.toLowerCase();

    final hasMathPattern =
        RegExp(r'\d\s*[+\-*/:×·÷=]\s*[\dx(]').hasMatch(t) ||
            RegExp(r'\d\s*x\b').hasMatch(t);
    const mathWords = [
      'berechne', 'gleichung', 'löse', 'rechne', 'bruch', 'prozent',
      'dreieck', 'fläche', 'umfang', 'winkel', 'funktion', 'summe',
    ];
    if (hasMathPattern || mathWords.any(t.contains)) return Subject.math;

    const languageWords = [
      'englisch', 'english', 'translate', 'übersetze', 'vokabel', 'grammatik',
      'französisch', 'spanisch', 'latein', 'verb', 'satz', 'gedicht',
      'erörterung', 'aufsatz',
    ];
    if (languageWords.any(t.contains)) return Subject.language;

    const scienceWords = [
      'biologie', 'chemie', 'physik', 'zelle', 'atom', 'molekül', 'energie',
      'photosynthese', 'kraft', 'reaktion', 'element', 'organismus', 'strom',
    ];
    if (scienceWords.any(t.contains)) return Subject.science;

    return Subject.general;
  }
}
