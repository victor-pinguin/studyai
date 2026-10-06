import 'dart:math';

import 'package:flutter/material.dart';

/// Sprachen, die man in StudySnap lernen kann.
enum LearnLanguage {
  italian('Italienisch', 'Italien', 'Ciao!',
      [Color(0xFF008C45), Color(0xFFF4F5F0), Color(0xFFCD212A)], false),
  english('Englisch', 'Großbritannien', 'Hello!',
      [Color(0xFF012169), Color(0xFFFFFFFF), Color(0xFFC8102E)], false),
  french('Französisch', 'Frankreich', 'Salut!',
      [Color(0xFF0055A4), Color(0xFFFFFFFF), Color(0xFFEF4135)], false),
  spanish('Spanisch', 'Spanien', '¡Hola!',
      [Color(0xFFAA151B), Color(0xFFF1BF00), Color(0xFFAA151B)], true);

  const LearnLanguage(
      this.label, this.country, this.greeting, this.flagColors, this.horizontal);

  final String label;
  final String country;
  final String greeting;

  /// Drei Streifen der Flagge.
  final List<Color> flagColors;

  /// true: waagerechte Streifen (Spanien), sonst senkrecht.
  final bool horizontal;

  static LearnLanguage byName(String name) => values.firstWhere(
        (l) => l.name == name,
        orElse: () => LearnLanguage.italian,
      );
}

/// Themen des Sprach-Trainers.
enum VocabTopic {
  greetings('Begrüßung', Icons.waving_hand_rounded),
  numbers('Zahlen 1–10', Icons.pin_rounded),
  colors('Farben', Icons.palette_rounded),
  animals('Tiere', Icons.pets_rounded),
  food('Essen & Trinken', Icons.restaurant_rounded),
  family('Familie', Icons.family_restroom_rounded),
  school('Schule', Icons.school_rounded),
  everyday('Alltag', Icons.wb_sunny_rounded);

  const VocabTopic(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Ein deutsches Wort mit seinen Übersetzungen.
class VocabWord {
  const VocabWord(this.de, this.translations, this.topic);

  final String de;
  final Map<LearnLanguage, String> translations;
  final VocabTopic topic;

  String tr(LearnLanguage language) => translations[language] ?? de;

  /// Nomen mit Artikel – Grundlage für den Artikel-Trainer in Deutsch.
  String? get article {
    final first = de.split(' ').first;
    return const ['der', 'die', 'das'].contains(first) ? first : null;
  }

  String get withoutArticle =>
      article == null ? de : de.substring(article!.length + 1);

  static const List<VocabWord> all = [
    VocabWord('Hallo', {LearnLanguage.italian: "ciao", LearnLanguage.english: "hello", LearnLanguage.french: "salut", LearnLanguage.spanish: "hola"}, VocabTopic.greetings),
    VocabWord('Guten Morgen', {LearnLanguage.italian: "buongiorno", LearnLanguage.english: "good morning", LearnLanguage.french: "bonjour", LearnLanguage.spanish: "buenos días"}, VocabTopic.greetings),
    VocabWord('Willkommen', {LearnLanguage.italian: "benvenuto", LearnLanguage.english: "welcome", LearnLanguage.french: "bienvenue", LearnLanguage.spanish: "bienvenido"}, VocabTopic.greetings),
    VocabWord('Gute Nacht', {LearnLanguage.italian: "buonanotte", LearnLanguage.english: "good night", LearnLanguage.french: "bonne nuit", LearnLanguage.spanish: "buenas noches"}, VocabTopic.greetings),
    VocabWord('Auf Wiedersehen', {LearnLanguage.italian: "arrivederci", LearnLanguage.english: "goodbye", LearnLanguage.french: "au revoir", LearnLanguage.spanish: "adiós"}, VocabTopic.greetings),
    VocabWord('Bitte', {LearnLanguage.italian: "per favore", LearnLanguage.english: "please", LearnLanguage.french: "s'il vous plaît", LearnLanguage.spanish: "por favor"}, VocabTopic.greetings),
    VocabWord('Danke', {LearnLanguage.italian: "grazie", LearnLanguage.english: "thank you", LearnLanguage.french: "merci", LearnLanguage.spanish: "gracias"}, VocabTopic.greetings),
    VocabWord('Entschuldigung', {LearnLanguage.italian: "scusa", LearnLanguage.english: "sorry", LearnLanguage.french: "pardon", LearnLanguage.spanish: "perdón"}, VocabTopic.greetings),
    VocabWord('Ja', {LearnLanguage.italian: "sì", LearnLanguage.english: "yes", LearnLanguage.french: "oui", LearnLanguage.spanish: "sí"}, VocabTopic.greetings),
    VocabWord('Nein', {LearnLanguage.italian: "no", LearnLanguage.english: "no", LearnLanguage.french: "non", LearnLanguage.spanish: "no"}, VocabTopic.greetings),
    VocabWord('eins', {LearnLanguage.italian: "uno", LearnLanguage.english: "one", LearnLanguage.french: "un", LearnLanguage.spanish: "uno"}, VocabTopic.numbers),
    VocabWord('zwei', {LearnLanguage.italian: "due", LearnLanguage.english: "two", LearnLanguage.french: "deux", LearnLanguage.spanish: "dos"}, VocabTopic.numbers),
    VocabWord('drei', {LearnLanguage.italian: "tre", LearnLanguage.english: "three", LearnLanguage.french: "trois", LearnLanguage.spanish: "tres"}, VocabTopic.numbers),
    VocabWord('vier', {LearnLanguage.italian: "quattro", LearnLanguage.english: "four", LearnLanguage.french: "quatre", LearnLanguage.spanish: "cuatro"}, VocabTopic.numbers),
    VocabWord('fünf', {LearnLanguage.italian: "cinque", LearnLanguage.english: "five", LearnLanguage.french: "cinq", LearnLanguage.spanish: "cinco"}, VocabTopic.numbers),
    VocabWord('sechs', {LearnLanguage.italian: "sei", LearnLanguage.english: "six", LearnLanguage.french: "six", LearnLanguage.spanish: "seis"}, VocabTopic.numbers),
    VocabWord('sieben', {LearnLanguage.italian: "sette", LearnLanguage.english: "seven", LearnLanguage.french: "sept", LearnLanguage.spanish: "siete"}, VocabTopic.numbers),
    VocabWord('acht', {LearnLanguage.italian: "otto", LearnLanguage.english: "eight", LearnLanguage.french: "huit", LearnLanguage.spanish: "ocho"}, VocabTopic.numbers),
    VocabWord('neun', {LearnLanguage.italian: "nove", LearnLanguage.english: "nine", LearnLanguage.french: "neuf", LearnLanguage.spanish: "nueve"}, VocabTopic.numbers),
    VocabWord('zehn', {LearnLanguage.italian: "dieci", LearnLanguage.english: "ten", LearnLanguage.french: "dix", LearnLanguage.spanish: "diez"}, VocabTopic.numbers),
    VocabWord('rot', {LearnLanguage.italian: "rosso", LearnLanguage.english: "red", LearnLanguage.french: "rouge", LearnLanguage.spanish: "rojo"}, VocabTopic.colors),
    VocabWord('blau', {LearnLanguage.italian: "blu", LearnLanguage.english: "blue", LearnLanguage.french: "bleu", LearnLanguage.spanish: "azul"}, VocabTopic.colors),
    VocabWord('gelb', {LearnLanguage.italian: "giallo", LearnLanguage.english: "yellow", LearnLanguage.french: "jaune", LearnLanguage.spanish: "amarillo"}, VocabTopic.colors),
    VocabWord('grün', {LearnLanguage.italian: "verde", LearnLanguage.english: "green", LearnLanguage.french: "vert", LearnLanguage.spanish: "verde"}, VocabTopic.colors),
    VocabWord('schwarz', {LearnLanguage.italian: "nero", LearnLanguage.english: "black", LearnLanguage.french: "noir", LearnLanguage.spanish: "negro"}, VocabTopic.colors),
    VocabWord('weiß', {LearnLanguage.italian: "bianco", LearnLanguage.english: "white", LearnLanguage.french: "blanc", LearnLanguage.spanish: "blanco"}, VocabTopic.colors),
    VocabWord('orange', {LearnLanguage.italian: "arancione", LearnLanguage.english: "orange", LearnLanguage.french: "orange", LearnLanguage.spanish: "naranja"}, VocabTopic.colors),
    VocabWord('rosa', {LearnLanguage.italian: "rosa", LearnLanguage.english: "pink", LearnLanguage.french: "rose", LearnLanguage.spanish: "rosa"}, VocabTopic.colors),
    VocabWord('braun', {LearnLanguage.italian: "marrone", LearnLanguage.english: "brown", LearnLanguage.french: "marron", LearnLanguage.spanish: "marrón"}, VocabTopic.colors),
    VocabWord('grau', {LearnLanguage.italian: "grigio", LearnLanguage.english: "grey", LearnLanguage.french: "gris", LearnLanguage.spanish: "gris"}, VocabTopic.colors),
    VocabWord('der Hund', {LearnLanguage.italian: "il cane", LearnLanguage.english: "the dog", LearnLanguage.french: "le chien", LearnLanguage.spanish: "el perro"}, VocabTopic.animals),
    VocabWord('die Katze', {LearnLanguage.italian: "il gatto", LearnLanguage.english: "the cat", LearnLanguage.french: "le chat", LearnLanguage.spanish: "el gato"}, VocabTopic.animals),
    VocabWord('das Pferd', {LearnLanguage.italian: "il cavallo", LearnLanguage.english: "the horse", LearnLanguage.french: "le cheval", LearnLanguage.spanish: "el caballo"}, VocabTopic.animals),
    VocabWord('der Vogel', {LearnLanguage.italian: "l'uccello", LearnLanguage.english: "the bird", LearnLanguage.french: "l'oiseau", LearnLanguage.spanish: "el pájaro"}, VocabTopic.animals),
    VocabWord('der Fisch', {LearnLanguage.italian: "il pesce", LearnLanguage.english: "the fish", LearnLanguage.french: "le poisson", LearnLanguage.spanish: "el pez"}, VocabTopic.animals),
    VocabWord('die Kuh', {LearnLanguage.italian: "la mucca", LearnLanguage.english: "the cow", LearnLanguage.french: "la vache", LearnLanguage.spanish: "la vaca"}, VocabTopic.animals),
    VocabWord('das Schaf', {LearnLanguage.italian: "la pecora", LearnLanguage.english: "the sheep", LearnLanguage.french: "le mouton", LearnLanguage.spanish: "la oveja"}, VocabTopic.animals),
    VocabWord('das Schwein', {LearnLanguage.italian: "il maiale", LearnLanguage.english: "the pig", LearnLanguage.french: "le cochon", LearnLanguage.spanish: "el cerdo"}, VocabTopic.animals),
    VocabWord('die Maus', {LearnLanguage.italian: "il topo", LearnLanguage.english: "the mouse", LearnLanguage.french: "la souris", LearnLanguage.spanish: "el ratón"}, VocabTopic.animals),
    VocabWord('der Bär', {LearnLanguage.italian: "l'orso", LearnLanguage.english: "the bear", LearnLanguage.french: "l'ours", LearnLanguage.spanish: "el oso"}, VocabTopic.animals),
    VocabWord('das Brot', {LearnLanguage.italian: "il pane", LearnLanguage.english: "the bread", LearnLanguage.french: "le pain", LearnLanguage.spanish: "el pan"}, VocabTopic.food),
    VocabWord('der Apfel', {LearnLanguage.italian: "la mela", LearnLanguage.english: "the apple", LearnLanguage.french: "la pomme", LearnLanguage.spanish: "la manzana"}, VocabTopic.food),
    VocabWord('die Milch', {LearnLanguage.italian: "il latte", LearnLanguage.english: "the milk", LearnLanguage.french: "le lait", LearnLanguage.spanish: "la leche"}, VocabTopic.food),
    VocabWord('das Wasser', {LearnLanguage.italian: "l'acqua", LearnLanguage.english: "the water", LearnLanguage.french: "l'eau", LearnLanguage.spanish: "el agua"}, VocabTopic.food),
    VocabWord('der Käse', {LearnLanguage.italian: "il formaggio", LearnLanguage.english: "the cheese", LearnLanguage.french: "le fromage", LearnLanguage.spanish: "el queso"}, VocabTopic.food),
    VocabWord('die Pizza', {LearnLanguage.italian: "la pizza", LearnLanguage.english: "the pizza", LearnLanguage.french: "la pizza", LearnLanguage.spanish: "la pizza"}, VocabTopic.food),
    VocabWord('die Nudeln', {LearnLanguage.italian: "la pasta", LearnLanguage.english: "the pasta", LearnLanguage.french: "les pâtes", LearnLanguage.spanish: "la pasta"}, VocabTopic.food),
    VocabWord('das Eis', {LearnLanguage.italian: "il gelato", LearnLanguage.english: "the ice cream", LearnLanguage.french: "la glace", LearnLanguage.spanish: "el helado"}, VocabTopic.food),
    VocabWord('das Ei', {LearnLanguage.italian: "l'uovo", LearnLanguage.english: "the egg", LearnLanguage.french: "l'œuf", LearnLanguage.spanish: "el huevo"}, VocabTopic.food),
    VocabWord('der Saft', {LearnLanguage.italian: "il succo", LearnLanguage.english: "the juice", LearnLanguage.french: "le jus", LearnLanguage.spanish: "el zumo"}, VocabTopic.food),
    VocabWord('die Mutter', {LearnLanguage.italian: "la madre", LearnLanguage.english: "the mother", LearnLanguage.french: "la mère", LearnLanguage.spanish: "la madre"}, VocabTopic.family),
    VocabWord('der Vater', {LearnLanguage.italian: "il padre", LearnLanguage.english: "the father", LearnLanguage.french: "le père", LearnLanguage.spanish: "el padre"}, VocabTopic.family),
    VocabWord('die Schwester', {LearnLanguage.italian: "la sorella", LearnLanguage.english: "the sister", LearnLanguage.french: "la sœur", LearnLanguage.spanish: "la hermana"}, VocabTopic.family),
    VocabWord('der Bruder', {LearnLanguage.italian: "il fratello", LearnLanguage.english: "the brother", LearnLanguage.french: "le frère", LearnLanguage.spanish: "el hermano"}, VocabTopic.family),
    VocabWord('die Oma', {LearnLanguage.italian: "la nonna", LearnLanguage.english: "the grandma", LearnLanguage.french: "la grand-mère", LearnLanguage.spanish: "la abuela"}, VocabTopic.family),
    VocabWord('der Opa', {LearnLanguage.italian: "il nonno", LearnLanguage.english: "the grandpa", LearnLanguage.french: "le grand-père", LearnLanguage.spanish: "el abuelo"}, VocabTopic.family),
    VocabWord('das Kind', {LearnLanguage.italian: "il bambino", LearnLanguage.english: "the child", LearnLanguage.french: "l'enfant", LearnLanguage.spanish: "el niño"}, VocabTopic.family),
    VocabWord('die Familie', {LearnLanguage.italian: "la famiglia", LearnLanguage.english: "the family", LearnLanguage.french: "la famille", LearnLanguage.spanish: "la familia"}, VocabTopic.family),
    VocabWord('die Tante', {LearnLanguage.italian: "la zia", LearnLanguage.english: "the aunt", LearnLanguage.french: "la tante", LearnLanguage.spanish: "la tía"}, VocabTopic.family),
    VocabWord('der Onkel', {LearnLanguage.italian: "lo zio", LearnLanguage.english: "the uncle", LearnLanguage.french: "l'oncle", LearnLanguage.spanish: "el tío"}, VocabTopic.family),
    VocabWord('die Schule', {LearnLanguage.italian: "la scuola", LearnLanguage.english: "the school", LearnLanguage.french: "l'école", LearnLanguage.spanish: "la escuela"}, VocabTopic.school),
    VocabWord('das Buch', {LearnLanguage.italian: "il libro", LearnLanguage.english: "the book", LearnLanguage.french: "le livre", LearnLanguage.spanish: "el libro"}, VocabTopic.school),
    VocabWord('der Stift', {LearnLanguage.italian: "la penna", LearnLanguage.english: "the pen", LearnLanguage.french: "le stylo", LearnLanguage.spanish: "el bolígrafo"}, VocabTopic.school),
    VocabWord('das Heft', {LearnLanguage.italian: "il quaderno", LearnLanguage.english: "the notebook", LearnLanguage.french: "le cahier", LearnLanguage.spanish: "el cuaderno"}, VocabTopic.school),
    VocabWord('der Lehrer', {LearnLanguage.italian: "il maestro", LearnLanguage.english: "the teacher", LearnLanguage.french: "le maître", LearnLanguage.spanish: "el maestro"}, VocabTopic.school),
    VocabWord('die Tafel', {LearnLanguage.italian: "la lavagna", LearnLanguage.english: "the board", LearnLanguage.french: "le tableau", LearnLanguage.spanish: "la pizarra"}, VocabTopic.school),
    VocabWord('der Rucksack', {LearnLanguage.italian: "lo zaino", LearnLanguage.english: "the backpack", LearnLanguage.french: "le sac à dos", LearnLanguage.spanish: "la mochila"}, VocabTopic.school),
    VocabWord('die Hausaufgabe', {LearnLanguage.italian: "il compito", LearnLanguage.english: "the homework", LearnLanguage.french: "les devoirs", LearnLanguage.spanish: "los deberes"}, VocabTopic.school),
    VocabWord('die Pause', {LearnLanguage.italian: "la ricreazione", LearnLanguage.english: "the break", LearnLanguage.french: "la récréation", LearnLanguage.spanish: "el recreo"}, VocabTopic.school),
    VocabWord('der Freund', {LearnLanguage.italian: "l'amico", LearnLanguage.english: "the friend", LearnLanguage.french: "l'ami", LearnLanguage.spanish: "el amigo"}, VocabTopic.school),
    VocabWord('das Haus', {LearnLanguage.italian: "la casa", LearnLanguage.english: "the house", LearnLanguage.french: "la maison", LearnLanguage.spanish: "la casa"}, VocabTopic.everyday),
    VocabWord('der Tag', {LearnLanguage.italian: "il giorno", LearnLanguage.english: "the day", LearnLanguage.french: "le jour", LearnLanguage.spanish: "el día"}, VocabTopic.everyday),
    VocabWord('die Nacht', {LearnLanguage.italian: "la notte", LearnLanguage.english: "the night", LearnLanguage.french: "la nuit", LearnLanguage.spanish: "la noche"}, VocabTopic.everyday),
    VocabWord('die Sonne', {LearnLanguage.italian: "il sole", LearnLanguage.english: "the sun", LearnLanguage.french: "le soleil", LearnLanguage.spanish: "el sol"}, VocabTopic.everyday),
    VocabWord('der Mond', {LearnLanguage.italian: "la luna", LearnLanguage.english: "the moon", LearnLanguage.french: "la lune", LearnLanguage.spanish: "la luna"}, VocabTopic.everyday),
    VocabWord('das Auto', {LearnLanguage.italian: "la macchina", LearnLanguage.english: "the car", LearnLanguage.french: "la voiture", LearnLanguage.spanish: "el coche"}, VocabTopic.everyday),
    VocabWord('der Baum', {LearnLanguage.italian: "l'albero", LearnLanguage.english: "the tree", LearnLanguage.french: "l'arbre", LearnLanguage.spanish: "el árbol"}, VocabTopic.everyday),
    VocabWord('die Blume', {LearnLanguage.italian: "il fiore", LearnLanguage.english: "the flower", LearnLanguage.french: "la fleur", LearnLanguage.spanish: "la flor"}, VocabTopic.everyday),
    VocabWord('das Spiel', {LearnLanguage.italian: "il gioco", LearnLanguage.english: "the game", LearnLanguage.french: "le jeu", LearnLanguage.spanish: "el juego"}, VocabTopic.everyday),
    VocabWord('das Wort', {LearnLanguage.italian: "la parola", LearnLanguage.english: "the word", LearnLanguage.french: "le mot", LearnLanguage.spanish: "la palabra"}, VocabTopic.everyday),
  ];

  static List<VocabWord> byTopic(VocabTopic? topic) =>
      topic == null ? all : all.where((w) => w.topic == topic).toList();

  static List<VocabWord> get nouns =>
      all.where((w) => w.article != null).toList();
}

/// Eine Vokabelfrage mit vier Antworten.
class VocabQuestion {
  const VocabQuestion({
    required this.word,
    required this.language,
    required this.toForeign,
    required this.options,
    required this.correctIndex,
  });

  final VocabWord word;
  final LearnLanguage language;

  /// true: Deutsch → Fremdsprache. false: Fremdsprache → Deutsch.
  final bool toForeign;
  final List<String> options;
  final int correctIndex;

  String get prompt => toForeign ? word.de : word.tr(language);
  String get answer => toForeign ? word.tr(language) : word.de;
  String get hint => toForeign
      ? 'Wie heißt das auf ${language.label}?'
      : 'Was heißt das auf Deutsch?';
  String get explanation =>
      '„${word.de}" heißt auf ${language.label} „${word.tr(language)}".';
}

/// Erzeugt [count] Vokabelfragen. [topic] = null bedeutet „alles gemischt“.
List<VocabQuestion> buildVocabQuestions(
  VocabTopic? topic,
  int count, {
  LearnLanguage language = LearnLanguage.italian,
  Random? random,
}) {
  final rnd = random ?? Random();
  final pool = VocabWord.byTopic(topic);
  final questions = <VocabQuestion>[];
  final used = <String>{};

  while (questions.length < count) {
    final word = pool[rnd.nextInt(pool.length)];
    if (used.contains(word.de) && used.length < pool.length) continue;
    used.add(word.de);

    // Beide Richtungen, damit man Wörter wirklich kann
    final toForeign = rnd.nextBool();
    final answer = toForeign ? word.tr(language) : word.de;

    // Ablenker: zuerst aus demselben Thema, dann aus allen Wörtern
    final options = <String>{answer};
    for (final source in [pool, VocabWord.all]) {
      final others = source.where((w) => w.de != word.de).toList()..shuffle(rnd);
      for (final other in others) {
        if (options.length >= 4) break;
        options.add(toForeign ? other.tr(language) : other.de);
      }
      if (options.length >= 4) break;
    }

    final list = options.toList()..shuffle(rnd);
    questions.add(VocabQuestion(
      word: word,
      language: language,
      toForeign: toForeign,
      options: list,
      correctIndex: list.indexOf(answer),
    ));
  }
  return questions;
}
