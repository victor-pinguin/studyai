import 'dart:math';

import 'package:flutter/material.dart';

import 'vocab.dart';

/// Die beiden Übungen im Deutsch-Trainer.
enum GermanTopic {
  articles('der, die, das', Icons.abc_rounded),
  spelling('Richtig schreiben', Icons.spellcheck_rounded);

  const GermanTopic(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Ein Wort, das man richtig schreiben soll.
class SpellingItem {
  const SpellingItem(this.correct, this.wrong);

  final String correct;
  final List<String> wrong;

  static const List<SpellingItem> all = [
    SpellingItem("Fahrrad", ["Farrad", "Fahrad", "Farhrad"]),
    SpellingItem("Vogel", ["Fogel", "Vogell", "Vohgel"]),
    SpellingItem("Familie", ["Famielie", "Familje", "Famillie"]),
    SpellingItem("Tochter", ["Tochta", "Tokter", "Toschter"]),
    SpellingItem("Zimmer", ["Cimmer", "Zimer", "Zimmerr"]),
    SpellingItem("Kaninchen", ["Kanienchen", "Kaninschen", "Kanninchen"]),
    SpellingItem("Schlüssel", ["Schlüsel", "Schlüßel", "Schlüsell"]),
    SpellingItem("Mädchen", ["Mädschen", "Medchen", "Mädchn"]),
    SpellingItem("Wasser", ["Waser", "Wassa", "Wasserr"]),
    SpellingItem("Fenster", ["Venster", "Fensta", "Fenstter"]),
    SpellingItem("Tier", ["Thier", "Tiehr", "Tir"]),
    SpellingItem("Junge", ["Jungee", "Junnge", "Yunge"]),
    SpellingItem("Milch", ["Milsch", "Millch", "Milck"]),
    SpellingItem("Apfel", ["Appfel", "Apfell", "Aphel"]),
    SpellingItem("Schule", ["Schuhle", "Shule", "Schulle"]),
    SpellingItem("Blume", ["Blumme", "Bluhme", "Plume"]),
    SpellingItem("Hand", ["Hant", "Handt", "Hannd"]),
    SpellingItem("Kind", ["Kint", "Kindt", "Kinnd"]),
    SpellingItem("Baum", ["Baumm", "Paum", "Bauhm"]),
    SpellingItem("Auto", ["Autto", "Auhto", "Ato"]),
    SpellingItem("Freund", ["Freunt", "Froind", "Freundt"]),
    SpellingItem("Sonne", ["Sone", "Sonnne", "Zonne"]),
    SpellingItem("Uhr", ["Ur", "Uhrr", "Uahr"]),
    SpellingItem("Vater", ["Fater", "Vatter", "Vahter"]),
    SpellingItem("Garten", ["Garden", "Gartten", "Gahrten"]),
    SpellingItem("Butter", ["Buter", "Butta", "Buttter"]),
  ];
}

/// Eine Frage im Deutsch-Trainer.
class GermanQuestion {
  const GermanQuestion({
    required this.topic,
    required this.prompt,
    required this.hint,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  final GermanTopic topic;
  final String prompt;
  final String hint;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  String get answer => options[correctIndex];
}

/// Erzeugt [count] Deutsch-Fragen. [topic] = null bedeutet „gemischt“.
List<GermanQuestion> buildGermanQuestions(
  GermanTopic? topic,
  int count, {
  Random? random,
}) {
  final rnd = random ?? Random();
  final questions = <GermanQuestion>[];
  final usedArticles = <String>{};
  final usedSpelling = <String>{};
  final nouns = VocabWord.nouns;

  while (questions.length < count) {
    final kind = topic ??
        (rnd.nextBool() ? GermanTopic.articles : GermanTopic.spelling);

    if (kind == GermanTopic.articles) {
      final word = nouns[rnd.nextInt(nouns.length)];
      if (usedArticles.contains(word.de) && usedArticles.length < nouns.length) {
        continue;
      }
      usedArticles.add(word.de);
      const options = ['der', 'die', 'das'];
      questions.add(GermanQuestion(
        topic: GermanTopic.articles,
        prompt: '___ ${word.withoutArticle}',
        hint: 'Welcher Artikel passt?',
        options: options,
        correctIndex: options.indexOf(word.article!),
        explanation: 'Richtig ist „${word.de}".',
      ));
    } else {
      final item = SpellingItem.all[rnd.nextInt(SpellingItem.all.length)];
      if (usedSpelling.contains(item.correct) &&
          usedSpelling.length < SpellingItem.all.length) {
        continue;
      }
      usedSpelling.add(item.correct);
      final options = [item.correct, ...item.wrong]..shuffle(rnd);
      questions.add(GermanQuestion(
        topic: GermanTopic.spelling,
        prompt: 'Welches Wort ist richtig geschrieben?',
        hint: 'Schau genau hin',
        options: options,
        correctIndex: options.indexOf(item.correct),
        explanation: 'Richtig geschrieben: „${item.correct}".',
      ));
    }
  }
  return questions;
}
