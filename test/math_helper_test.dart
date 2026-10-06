import 'package:flutter_test/flutter_test.dart';
import 'package:studysnap_ai/models/reward.dart';
import 'package:studysnap_ai/models/german.dart';
import 'package:studysnap_ai/models/vocab.dart';
import 'package:studysnap_ai/services/ai/math_helper.dart';
import 'package:studysnap_ai/screens/times_table_screen.dart';
import 'package:studysnap_ai/services/ai/mock_ai_service.dart';

double? solve(String text) {
  final eq = MathHelper.findEquation(text);
  return eq == null ? null : MathHelper.solveLinear(eq)?.x;
}

double? calc(String text) {
  final expr = MathHelper.findExpression(text);
  return expr == null ? null : MathHelper.evaluateWithSteps(expr)?.result;
}

void main() {
  group('Lineare Gleichungen', () {
    final cases = <String, double>{
      'Aufgabe 1: 2x + 3 = 11': 4,
      'Löse: 5x − 2 = 3x + 8': 5,
      'Löse nach x auf: 3(x + 2) = 2x + 1': -5,
      '2x = 3(x-1)': 3,
      'x/2 + 1 = 4': 6,
      'x : 3 + 1 = 2': 3,
      'Bestimme x: x : 4 = 2,5': 10,
      '3x = 7': 7 / 3,
      'a) 3x = 12': 4,
      '0,5x + 1 = 3': 4,
      '4 = 2x': 2,
      '-(x+1) = 2': -3,
      '7 - 2x = 3x - 8': 3,
      '1,5x − 0,5 = 2,5': 2,
    };
    cases.forEach((text, expected) {
      test('$text → x = $expected', () {
        expect(solve(text), closeTo(expected, 1e-9));
      });
    });

    test('Normalisierte Gleichung', () {
      expect(MathHelper.findEquation('Aufgabe 1: 2x + 3 = 11'), '2x+3=11');
    });

    test('Wird bewusst NICHT gelöst (lieber keine als eine falsche Lösung)', () {
      for (final text in [
        'x² + 3 = 12', 'x2 + 3 = 12', 'x^2=4', '2x+1=2x+3', 'x(x+1)=2',
        '6/x=2', 'max=5 Punkte', 'Um 10:30 Uhr', '6 : 2(x+1) = 1', 'x + y = 3',
      ]) {
        expect(solve(text), isNull, reason: text);
      }
    });
  });

  group('Rechenausdrücke', () {
    final cases = <String, double>{
      'Berechne: 12 + 7 · 3': 33,
      '(4 + 2) · 3 − 5': 13,
      '12 + 7 · 3 = 33': 33,
      '0,1 + 0,2': 0.3,
      '10 : 3': 10 / 3,
      '2(3+4)': 14,
      '(1+2)(3+4)': 21,
      '−3 · (−4)': 12,
      '20 : 4 : 5': 1,
      '100 − 3·4·2 + 6:3': 78,
    };
    cases.forEach((text, expected) {
      test('$text = $expected', () {
        expect(calc(text), closeTo(expected, 1e-9));
      });
    });

    test('Wird bewusst NICHT gerechnet', () {
      for (final text in ['2^3+1', '3² + 4', '6 : 2(1+2)', 'Um 10:30 Uhr', '20% von 50', '5 : 0']) {
        expect(calc(text), isNull, reason: text);
      }
    });

    test('Ergebnis-Anzeige ist exakt oder mit ≈ gekennzeichnet', () {
      expect(MathHelper.result(4), '= 4');
      expect(MathHelper.result(2.5), '= 2,5');
      expect(MathHelper.result(7 / 3), '= 7/3 ≈ 2,33');
    });
  });

  group('Demo-KI', () {
    final ai = MockAiService(delay: Duration.zero);

    test('Erklärung einer Gleichung enthält Lösung', () async {
      final e = await ai.explain('2x + 3 = 11');
      expect(e.solution, 'x = 4');
      expect(e.steps.length, greaterThanOrEqualTo(3));
    });

    test('Klammer-Gleichung bekommt Vereinfachungs-Schritt', () async {
      final e = await ai.explain('3(x + 2) = 2x + 1');
      expect(e.solution, 'x = -5');
      expect(e.steps.any((s) => s.title == 'Beide Seiten vereinfachen'), isTrue);
    });

    test('Quiz: richtige Antwort stimmt und Antworten sind verschieden', () async {
      for (final text in ['2x + 3 = 11', '12 + 7 · 3', 'Erkläre die Photosynthese.']) {
        for (final n in [3, 5, 10]) {
          final quiz = await ai.createQuiz(text, count: n);
          expect(quiz.length, n, reason: text);
          for (final q in quiz) {
            expect(q.options.length, 4);
            expect(q.options.toSet().length, 4, reason: 'Antworten doppelt');
            expect(q.correctIndex, inInclusiveRange(0, 3));
            final answer = q.options[q.correctIndex];
            if (q.question.startsWith('Löse die Gleichung')) {
              final x = solve(q.question.split('\n')[1])!;
              expect(answer, 'x = ${x.round()}');
            } else if (q.question.startsWith('Berechne')) {
              final r = calc(q.question.split('\n')[1])!;
              expect(answer, '${r.round()}');
            }
          }
        }
      }
    });
  });

  group('Belohnungen', () {
    test('Sticker haben eindeutige Ids', () {
      final ids = Sticker.all.map((s) => s.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('Gesammelte Sticker lassen sich speichern und wieder lesen', () {
      for (final s in Sticker.all) {
        for (final tier in RewardTier.values) {
          final raw = EarnedSticker(stickerId: s.id, tier: tier).encode();
          final back = EarnedSticker.decode(raw);
          expect(back?.stickerId, s.id);
          expect(back?.tier, tier);
          expect(back?.sticker?.name, s.name);
        }
      }
      expect(EarnedSticker.decode('kaputt'), isNull);
      expect(EarnedSticker.decode('s1:bronze'), isNull);
    });
  });

  group('Sprach-Trainer', () {
    test('Jedes Thema hat genug Wörter, Übersetzungen sind eindeutig', () {
      for (final topic in VocabTopic.values) {
        expect(VocabWord.byTopic(topic).length, greaterThanOrEqualTo(4),
            reason: topic.label);
      }
      for (final language in LearnLanguage.values) {
        final words = VocabWord.all.map((w) => w.tr(language)).toList();
        expect(words.toSet().length, words.length, reason: language.label);
        expect(words.any((w) => w.isEmpty), isFalse, reason: language.label);
      }
      final german = VocabWord.all.map((w) => w.de).toList();
      expect(german.toSet().length, german.length);
    });

    test('Fragen haben 4 verschiedene Antworten und die richtige stimmt', () {
      final topics = <VocabTopic?>[null, ...VocabTopic.values];
      for (final language in LearnLanguage.values) {
        for (final topic in topics) {
          for (var run = 0; run < 20; run++) {
            final questions =
                buildVocabQuestions(topic, 10, language: language);
            expect(questions.length, 10);
            for (final q in questions) {
              expect(q.options.length, 4);
              expect(q.options.toSet().length, 4, reason: 'Antwort doppelt');
              expect(q.options[q.correctIndex], q.answer);
              expect(q.answer,
                  q.toForeign ? q.word.tr(language) : q.word.de);
              if (topic != null) expect(q.word.topic, topic);
            }
          }
        }
      }
    });
  });

  group('Deutsch-Trainer', () {
    test('Artikel-Aufgaben haben genau einen richtigen Artikel', () {
      for (final w in VocabWord.nouns) {
        expect(['der', 'die', 'das'].contains(w.article), isTrue, reason: w.de);
        expect(w.withoutArticle.isNotEmpty, isTrue, reason: w.de);
      }
      expect(VocabWord.nouns.length, greaterThanOrEqualTo(20));
    });

    test('Rechtschreibung: vier verschiedene Schreibweisen', () {
      for (final item in SpellingItem.all) {
        expect(item.wrong.length, 3, reason: item.correct);
        expect({item.correct, ...item.wrong}.length, 4, reason: item.correct);
      }
    });

    test('Fragen stimmen und Antworten sind verschieden', () {
      final topics = <GermanTopic?>[null, ...GermanTopic.values];
      for (final topic in topics) {
        for (var run = 0; run < 50; run++) {
          final questions = buildGermanQuestions(topic, 10);
          expect(questions.length, 10);
          for (final q in questions) {
            expect(q.options.toSet().length, q.options.length);
            expect(q.correctIndex, inInclusiveRange(0, q.options.length - 1));
            if (q.topic == GermanTopic.articles) {
              expect(q.options, ['der', 'die', 'das']);
              expect(q.explanation.contains(q.answer), isTrue);
            } else {
              expect(q.options.length, 4);
              expect(q.explanation.contains(q.answer), isTrue);
            }
            if (topic != null) expect(q.topic, topic);
          }
        }
      }
    });
  });

  group('Einmaleins-Trainer', ()  {
    test('Jede Aufgabe hat 4 verschiedene Antworten und die richtige stimmt', () {
      for (var row = 0; row <= 9; row++) {
        for (var run = 0; run < 50; run++) {
          final questions = buildTimesQuestions(row, 10);
          expect(questions.length, 10);
          for (final q in questions) {
            expect(q.options.length, 4);
            expect(q.options.toSet().length, 4);
            expect(q.options[q.correctIndex], q.a * q.b);
            expect(q.a, inInclusiveRange(1, 9));
            expect(q.b, inInclusiveRange(1, 9));
            if (row != 0) expect(q.a, row);
          }
        }
      }
    });
  });
}
