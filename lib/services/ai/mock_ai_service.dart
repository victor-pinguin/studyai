import 'dart:math';

import '../../models/explanation.dart';
import '../../models/quiz.dart';
import '../../models/subject.dart';
import 'ai_service.dart';
import 'math_helper.dart';

/// Kostenlose Platzhalter-KI (0 €, offline).
///
/// * Mathe (Gleichungen, Rechenausdrücke): echte Schritt-für-Schritt-Lösung.
/// * Andere Fächer: strukturierte Lernanleitung (Operator erkennen,
///   Schlüsselbegriffe, Vorgehen) – aber keine inhaltliche Musterlösung.
///
/// Sobald ein Backend existiert, wird automatisch [ApiAiService] verwendet.
class MockAiService implements AiService {
  MockAiService({this.delay = const Duration(milliseconds: 900)});

  /// Simulierte „Denkzeit“, damit Ladeanimationen getestet werden können.
  final Duration delay;

  @override
  Future<Explanation> explain(String taskText, {bool detailed = false}) async {
    await Future<void>.delayed(delay);

    final equation = MathHelper.findEquation(taskText);
    if (equation != null) {
      final solution = MathHelper.solveLinear(equation);
      if (solution != null) return _explainLinear(solution, detailed);
    }

    final expression = MathHelper.findExpression(taskText);
    if (expression != null) {
      final solution = MathHelper.evaluateWithSteps(expression);
      if (solution != null) {
        return _explainArithmetic(expression, solution, detailed);
      }
    }

    return _explainGeneric(taskText, detailed);
  }

  @override
  Future<List<QuizQuestion>> createQuiz(String taskText, {int count = 5}) async {
    await Future<void>.delayed(delay);
    final n = count < 3 ? 3 : (count > 10 ? 10 : count);
    final random = Random(taskText.hashCode ^ DateTime.now().millisecond);
    final subject = Subject.detect(taskText);

    final List<QuizQuestion> questions;
    if (MathHelper.findEquation(taskText) != null) {
      questions = List.generate(
        n,
        (i) => i % 3 == 2 ? _conceptQuestion(random, i) : _equationQuestion(random),
      );
    } else if (subject == Subject.math) {
      questions = List.generate(n, (_) => _arithmeticQuestion(random));
    } else {
      questions = _genericQuiz(taskText, subject, n, random);
    }
    return questions;
  }

  // ===========================================================================
  // Erklärungen
  // ===========================================================================

  Explanation _explainLinear(LinearSolution s, bool detailed) {
    final a = s.a1 - s.a2;
    final rhs = s.b2 - s.b1;
    final steps = <ExplanationStep>[
      ExplanationStep(
        title: 'Aufgabe verstehen',
        content: 'Gesucht ist die Zahl x, für die beide Seiten gleich groß '
            'sind:\n${MathHelper.pretty(s.original)}',
        detail: detailed
            ? 'Stell dir die Gleichung wie eine Waage vor: Links und rechts '
                'liegt gleich viel. Was du auf einer Seite änderst, musst du '
                'auch auf der anderen Seite ändern – sonst kippt die Waage.'
            : null,
      ),
    ];

    if (s.needsSimplify) {
      steps.add(ExplanationStep(
        title: 'Beide Seiten vereinfachen',
        content: 'Klammern auflösen und gleiche Terme zusammenfassen '
            '(x-Terme zu x-Termen, Zahlen zu Zahlen):\n${s.equationText}',
        detail: detailed
            ? 'Eine Zahl vor der Klammer wird mit JEDEM Glied in der Klammer '
                'multipliziert: 3(x + 2) = 3x + 6.'
            : null,
      ));
    }

    if (s.a2.abs() > 1e-9) {
      final verb = s.a2 > 0 ? 'Subtrahiere' : 'Addiere';
      steps.add(ExplanationStep(
        title: 'x-Terme auf eine Seite bringen',
        content: '$verb ${MathHelper.linearToString(s.a2.abs(), 0)} auf beiden '
            'Seiten:\n${MathHelper.linearToString(a, s.b1)} = ${MathHelper.fmt(s.b2)}',
        detail: detailed
            ? 'Wir sammeln alle x auf der linken Seite, damit wir später nur '
                'noch einen x-Term haben.'
            : null,
      ));
    }

    if (s.b1.abs() > 1e-9) {
      final verb = s.b1 > 0 ? 'Subtrahiere' : 'Addiere';
      steps.add(ExplanationStep(
        title: 'Zahlen auf die andere Seite bringen',
        content: '$verb ${MathHelper.fmt(s.b1.abs())} auf beiden Seiten:\n'
            '${MathHelper.linearToString(a, 0)} = ${MathHelper.fmt(rhs)}',
        detail: detailed
            ? 'Die Umkehrung von „+ ${MathHelper.fmt(s.b1.abs())}“ ist '
                '„− ${MathHelper.fmt(s.b1.abs())}“. So verschwindet die Zahl '
                'links und x steht fast allein.'
            : null,
      ));
    }

    if ((a - 1).abs() > 1e-9) {
      final inverse = 1 / a;
      // Bei x : 4 oder (1/3)x ist „mal 4“ bzw. „mal 3“ einfacher als „geteilt durch 0,25“.
      if (a.abs() < 1 && MathHelper.isInt(inverse)) {
        steps.add(ExplanationStep(
          title: 'x allein stellen',
          content: 'Multipliziere beide Seiten mit ${MathHelper.fmtParen(inverse)}:\n'
              'x = ${MathHelper.fmtParen(rhs)} · ${MathHelper.fmtParen(inverse)}',
          detail: detailed
              ? '${MathHelper.linearToString(a, 0)} bedeutet x geteilt durch '
                  '${MathHelper.fmt(inverse.abs())}. Die Umkehrung von '
                  '„geteilt durch“ ist „mal“.'
              : null,
        ));
      } else {
        steps.add(ExplanationStep(
          title: 'Durch die Zahl vor x teilen',
          content: 'Teile beide Seiten durch ${MathHelper.fmtParen(a)}:\n'
              'x = ${MathHelper.fmtParen(rhs)} : ${MathHelper.fmtParen(a)}',
          detail: detailed
              ? '${MathHelper.linearToString(a, 0)} bedeutet '
                  '${MathHelper.fmtParen(a)} · x. Die Umkehrung von „mal“ ist '
                  '„geteilt durch“.'
              : null,
        ));
      }
    }

    final left = s.a1 * s.x + s.b1;
    final right = s.a2 * s.x + s.b2;
    steps.add(ExplanationStep(
      title: 'Probe machen',
      content: 'Setze dein Ergebnis für x in die ursprüngliche Gleichung ein.\n'
          'Links: ${MathHelper.approx(left)}   Rechts: ${MathHelper.approx(right)}\n'
          'Beide Seiten sind gleich – die Lösung stimmt.',
      detail: detailed
          ? 'Die Probe ist dein eingebauter Fehler-Detektor. In Tests gibt sie '
              'dir Sicherheit, ohne dass du jemanden fragen musst.'
          : null,
    ));

    return Explanation(
      subject: Subject.math,
      summary: 'Das ist eine lineare Gleichung. Ziel: x soll allein auf '
          'einer Seite stehen.',
      steps: steps,
      solution: 'x ${MathHelper.result(s.x)}',
      tip: 'Merksatz: Immer die Umkehr-Rechnung auf BEIDEN Seiten anwenden. '
          'Plus ↔ Minus, Mal ↔ Geteilt.',
      isDemo: true,
    );
  }

  Explanation _explainArithmetic(
    String expression,
    ArithmeticSolution s,
    bool detailed,
  ) {
    final steps = <ExplanationStep>[
      ExplanationStep(
        title: 'Rechenregeln merken',
        content: 'Aufgabe: ${MathHelper.pretty(expression)}\n\n'
            '1. Klammern zuerst\n2. Punkt vor Strich (· und : vor + und −)\n'
            '3. Dann von links nach rechts',
        detail: detailed
            ? 'Diese Reihenfolge gilt weltweit. Nur so kommt jeder bei der '
                'gleichen Aufgabe auf das gleiche Ergebnis.'
            : null,
      ),
    ];
    if (s.bracketSteps.isNotEmpty) {
      steps.add(ExplanationStep(
        title: 'Klammern ausrechnen',
        content: s.bracketSteps.join('\n'),
        detail: detailed
            ? 'Bei mehreren Klammern: Immer die innerste Klammer zuerst.'
            : null,
      ));
    }
    if (s.pointSteps.isNotEmpty) {
      steps.add(ExplanationStep(
        title: 'Punktrechnung (· und :)',
        content: s.pointSteps.join('\n'),
        detail: detailed
            ? 'Mal und Geteilt „binden stärker“ als Plus und Minus – deshalb '
                'kommen sie zuerst dran.'
            : null,
      ));
    }
    if (s.sumLine != null) {
      steps.add(ExplanationStep(
        title: 'Strichrechnung (+ und −)',
        content: s.sumLine!,
        detail: detailed ? 'Jetzt einfach von links nach rechts rechnen.' : null,
      ));
    }
    steps.add(const ExplanationStep(
      title: 'Ergebnis prüfen',
      content: 'Überschlage grob im Kopf: Passt die Größenordnung deines '
          'Ergebnisses? Wenn nicht, prüfe die Reihenfolge der Rechenschritte.',
    ));

    return Explanation(
      subject: Subject.math,
      summary: 'Ein Rechenausdruck mit mehreren Rechenarten. Entscheidend ist '
          'die richtige Reihenfolge.',
      steps: steps,
      solution: '${MathHelper.pretty(expression)} ${MathHelper.result(s.result)}',
      tip: 'Häufigster Fehler: einfach von links nach rechts rechnen. '
          'Markiere dir zuerst alle Mal- und Geteilt-Stellen.',
      isDemo: true,
    );
  }

  /// Operatoren aus Arbeitsaufträgen und was sie bedeuten.
  static const Map<String, String> _operators = {
    'nenne': 'Zähle Fakten kurz auf – ohne lange Erklärung.',
    'beschreibe': 'Gib mit eigenen Worten wieder, WIE etwas ist oder abläuft.',
    'erkläre': 'Mach verständlich, WARUM etwas so ist (Ursache → Wirkung).',
    'erläutere': 'Erkläre ausführlich und nenne Beispiele.',
    'begründe': 'Stütze eine Aussage mit Argumenten („…, weil …“).',
    'vergleiche': 'Stelle Gemeinsamkeiten UND Unterschiede gegenüber.',
    'bewerte': 'Bilde dir ein eigenes, begründetes Urteil.',
    'analysiere': 'Untersuche etwas genau nach bestimmten Gesichtspunkten.',
    'fasse zusammen': 'Gib das Wichtigste kurz und in eigenen Worten wieder.',
    'übersetze': 'Übertrage den Text sinngemäß in die andere Sprache.',
    'berechne': 'Finde das Ergebnis mit einem nachvollziehbaren Rechenweg.',
    'bestimme': 'Ermittle etwas – durch Rechnung oder Überlegung.',
    'skizziere': 'Zeichne oder beschreibe das Wesentliche vereinfacht.',
    'interpretiere': 'Deute den Inhalt und begründe deine Deutung am Text.',
  };

  Explanation _explainGeneric(String text, bool detailed) {
    final subject = Subject.detect(text);
    final lower = text.toLowerCase();
    final keywords = _keywords(text, max: 5);

    final foundOperator = _operators.keys.where(lower.contains).firstOrNull;
    final operatorText = foundOperator != null
        ? 'In deiner Aufgabe steht „$foundOperator“. Das bedeutet: '
            '${_operators[foundOperator]}'
        : 'Suche das Verb, das dir sagt, WAS du tun sollst '
            '(z. B. „nenne“, „erkläre“, „vergleiche“). Es bestimmt, wie '
            'ausführlich deine Antwort sein muss.';

    final plan = switch (subject) {
      Subject.math =>
        'Schreibe auf: Was ist gegeben? Was ist gesucht? Welche Formel '
            'verbindet beides? Rechne dann Schritt für Schritt.',
      Subject.language =>
        'Kläre unbekannte Wörter zuerst. Achte auf Zeitform und Satzbau. '
            'Formuliere in kurzen, klaren Sätzen.',
      Subject.science =>
        'Überlege: Welcher Vorgang oder welches Gesetz steckt dahinter? '
            'Beschreibe Ursache → Vorgang → Ergebnis.',
      Subject.general =>
        'Teile die Aufgabe in kleine Teilfragen. Beantworte eine nach der '
            'anderen und verbinde sie am Ende.',
    };

    final steps = <ExplanationStep>[
      ExplanationStep(
        title: 'Arbeitsauftrag verstehen',
        content: operatorText,
        detail: detailed
            ? 'Lehrkräfte bewerten oft genau danach, ob du den Operator '
                'erfüllt hast. „Nenne“ braucht Stichpunkte, „erkläre“ '
                'braucht ganze Sätze mit Begründung.'
            : null,
      ),
      ExplanationStep(
        title: 'Schlüsselbegriffe klären',
        content: keywords.isEmpty
            ? 'Markiere die wichtigsten Begriffe der Aufgabe und kläre, was '
                'sie bedeuten.'
            : 'Wichtige Begriffe: ${keywords.join(', ')}.\n'
                'Kannst du jeden davon in einem Satz erklären? Wenn nicht: '
                'zuerst nachschlagen.',
        detail: detailed
            ? 'Wer die Begriffe nicht sicher kennt, rät bei der Antwort. '
                'Schreib dir die Bedeutung kurz an den Rand.'
            : null,
      ),
      ExplanationStep(
        title: 'Vorgehen planen',
        content: plan,
        detail: detailed
            ? 'Ein kurzer Plan (2–3 Stichpunkte) spart Zeit und verhindert, '
                'dass du etwas vergisst.'
            : null,
      ),
      const ExplanationStep(
        title: 'Antwort formulieren',
        content: 'Beginne mit einem Satz, der die Frage direkt aufgreift. '
            'Dann Begründung oder Rechenweg, am Ende ein kurzes Fazit.',
      ),
      const ExplanationStep(
        title: 'Überprüfen',
        content: 'Lies die Aufgabe noch einmal: Hast du wirklich alles '
            'beantwortet, was gefragt war?',
      ),
    ];

    return Explanation(
      subject: subject,
      summary: 'Fach: ${subject.label}. So gehst du bei dieser Aufgabe '
          'systematisch vor.',
      steps: steps,
      solution: null,
      tip: 'Demo-Modus: Eine inhaltliche Musterlösung erscheint hier, sobald '
          'die echte KI angebunden ist. Mathe-Gleichungen und Rechenaufgaben '
          'löst die Demo schon komplett.',
      isDemo: true,
    );
  }

  // ===========================================================================
  // Quiz
  // ===========================================================================

  QuizQuestion _equationQuestion(Random r) {
    final a = r.nextInt(8) + 2; // 2..9
    final x = r.nextInt(12) + 1; // 1..12
    final b = r.nextInt(15) + 1; // 1..15
    final c = a * x + b;
    return _buildNumberQuestion(
      r,
      question: 'Löse die Gleichung:\n${a}x + $b = $c',
      correct: x,
      distractors: [x + 1, x - 1, c - b, x + 2, (c + b) ~/ a],
      prefix: 'x = ',
      explanation: '$c − $b = ${c - b}, also ${a}x = ${c - b}. '
          'Dann ${c - b} : $a = $x.',
    );
  }

  QuizQuestion _conceptQuestion(Random r, int i) {
    final a = r.nextInt(8) + 2;
    final b = r.nextInt(9) + 1;
    final c = a * (r.nextInt(9) + 1) + b;
    final pool = [
      (
        'Was ist der erste sinnvolle Schritt bei ${a}x + $b = $c?',
        ['$b auf beiden Seiten subtrahieren', 'Durch $c teilen', '$a addieren', 'x streichen'],
        'Zuerst die Zahl ohne x wegbringen: Die Umkehrung von „+ $b“ ist „− $b“.',
      ),
      (
        'Warum machst du die Probe?',
        ['Um zu prüfen, ob beide Seiten gleich sind', 'Weil es schneller geht', 'Um x zu verdoppeln', 'Sie ist nicht nötig'],
        'Bei der Probe setzt du x ein. Sind beide Seiten gleich, stimmt die Lösung.',
      ),
      (
        'Was bedeutet ${a}x?',
        ['$a · x', '$a + x', '$a − x', 'x : $a'],
        'Zwischen Zahl und Variable steht ein unsichtbares Malzeichen.',
      ),
      (
        'Was ist die Umkehrung von „· $a“?',
        [': $a', '+ $a', '− $a', '· $a'],
        'Mal und Geteilt heben sich gegenseitig auf.',
      ),
    ];
    final (q, opts, expl) = pool[(i ~/ 3) % pool.length];
    return _shuffled(r, q, opts, expl);
  }

  QuizQuestion _arithmeticQuestion(Random r) {
    final a = r.nextInt(20) + 1;
    final b = r.nextInt(9) + 2;
    final c = r.nextInt(9) + 2;
    final correct = a + b * c;
    return _buildNumberQuestion(
      r,
      question: 'Berechne:\n$a + $b · $c',
      correct: correct,
      distractors: [(a + b) * c, correct + 1, correct - b, a * b + c],
      explanation: 'Punkt vor Strich: $b · $c = ${b * c}, dann $a + ${b * c} = $correct. '
          '(Falsch wäre: ($a + $b) · $c = ${(a + b) * c}.)',
    );
  }

  List<QuizQuestion> _genericQuiz(
    String text,
    Subject subject,
    int count,
    Random r,
  ) {
    final result = <QuizQuestion>[];
    final keywords = _keywords(text, max: 4);
    const fakeWords = [
      'Vulkanausbruch', 'Stromrechnung', 'Fußballplatz', 'Wetterbericht',
      'Regenwald', 'Mittelalter', 'Schwerkraft', 'Satellit', 'Pyramide',
    ];

    // 1) Fragen zu Begriffen aus der eigenen Aufgabe
    for (final keyword in keywords) {
      final distractors = fakeWords
          .where((w) => !text.toLowerCase().contains(w.toLowerCase()))
          .toList()
        ..shuffle(r);
      if (distractors.length < 3) continue;
      result.add(_shuffled(
        r,
        'Welcher Begriff kommt in deiner Aufgabe vor?',
        [keyword, ...distractors.take(3)],
        '„$keyword“ steht in deiner Aufgabe. Kläre die Bedeutung aller '
            'Schlüsselbegriffe, bevor du antwortest.',
      ));
    }

    // 2) Operator-Fragen und Lernstrategie-Fragen
    final pool = <(String, List<String>, String)>[
      (
        'Was verlangt der Operator „erkläre“?',
        ['Gründe und Zusammenhänge verständlich machen', 'Nur Stichpunkte aufzählen', 'Eine Zeichnung anfertigen', 'Den Text abschreiben'],
        '„Erkläre“ bedeutet: Warum ist etwas so? Ursache → Wirkung.',
      ),
      (
        'Was verlangt der Operator „nenne“?',
        ['Fakten kurz aufzählen', 'Ausführlich begründen', 'Eine eigene Meinung bilden', 'Vor- und Nachteile abwägen'],
        '„Nenne“ = kurze Aufzählung ohne lange Erklärung.',
      ),
      (
        'Was gehört zu „vergleiche“?',
        ['Gemeinsamkeiten und Unterschiede', 'Nur Unterschiede', 'Nur die eigene Meinung', 'Eine Zusammenfassung'],
        'Ein Vergleich braucht immer beide Seiten: Was ist gleich, was ist anders?',
      ),
      (
        'Was ist der beste erste Schritt bei einer neuen Aufgabe?',
        ['Die Aufgabe genau lesen und den Operator markieren', 'Sofort losschreiben', 'Die Lösung raten', 'Die Aufgabe überspringen'],
        'Wer die Aufgabe genau versteht, verschwendet keine Zeit mit falschen Antworten.',
      ),
      (
        'Wie lernst du am nachhaltigsten?',
        ['In kurzen Einheiten über mehrere Tage verteilt', 'Alles am Abend vor dem Test', 'Nur durch Lesen', 'Nur durch Abschreiben'],
        'Verteiltes Lernen („Spaced Repetition“) hält Wissen am längsten im Gedächtnis.',
      ),
      (
        'Was hilft beim Verstehen eines schwierigen Textes?',
        ['Absätze in eigenen Worten zusammenfassen', 'Den Text schneller lesen', 'Nur die Überschrift lesen', 'Unbekannte Wörter ignorieren'],
        'Wenn du einen Absatz in eigenen Worten wiedergeben kannst, hast du ihn verstanden.',
      ),
      (
        'Wofür ist die Überprüfung am Ende gut?',
        ['Um zu sehen, ob alle Teilfragen beantwortet sind', 'Sie ist Zeitverschwendung', 'Um die Schrift zu verschönern', 'Um die Aufgabe zu ändern'],
        'Viele Punkte gehen verloren, weil eine Teilfrage vergessen wurde.',
      ),
      (
        'Was ist ein Schlüsselbegriff?',
        ['Ein Wort, das für die Aufgabe besonders wichtig ist', 'Das erste Wort im Satz', 'Ein Fremdwort', 'Ein Wort in Großbuchstaben'],
        'Schlüsselbegriffe tragen die Hauptaussage der Aufgabe.',
      ),
      (
        'Wie formulierst du eine Begründung?',
        ['Mit „…, weil …“ oder „…, da …“', 'Mit einer Frage', 'Nur mit einem Wort', 'Mit einem Ausrufezeichen'],
        'Eine Begründung verbindet eine Aussage mit ihrem Grund.',
      ),
      (
        'Was tust du, wenn du ein Wort nicht verstehst?',
        ['Nachschlagen oder aus dem Zusammenhang erschließen', 'Weiterlesen und ignorieren', 'Die Aufgabe abbrechen', 'Raten und nicht prüfen'],
        'Unbekannte Wörter führen oft zu falschen Antworten – kurz klären lohnt sich.',
      ),
    ]..shuffle(r);

    for (final (q, opts, expl) in pool) {
      if (result.length >= count) break;
      result.add(_shuffled(r, q, opts, expl));
    }
    return result.take(count).toList();
  }

  // ===========================================================================
  // Hilfsfunktionen
  // ===========================================================================

  QuizQuestion _buildNumberQuestion(
    Random r, {
    required String question,
    required int correct,
    required List<int> distractors,
    required String explanation,
    String prefix = '',
  }) {
    final options = <int>{correct};
    for (final d in distractors) {
      if (options.length >= 4) break;
      options.add(d);
    }
    var extra = 2;
    while (options.length < 4) {
      options.add(correct + extra++);
    }
    return _shuffled(
      r,
      question,
      options.map((o) => '$prefix$o').toList(),
      explanation,
    );
  }

  /// Mischt die Antworten. Die erste Option in [options] ist die richtige.
  QuizQuestion _shuffled(
    Random r,
    String question,
    List<String> options,
    String explanation,
  ) {
    final correct = options.first;
    final shuffled = [...options]..shuffle(r);
    return QuizQuestion(
      question: question,
      options: shuffled,
      correctIndex: shuffled.indexOf(correct),
      explanation: explanation,
    );
  }

  static const _stopWords = {
    'aufgabe', 'welche', 'welcher', 'welches', 'werden', 'wurden', 'deiner',
    'deinen', 'seinen', 'ihrer', 'zwischen', 'folgende', 'folgenden', 'diesem',
    'dieser', 'dieses', 'beschreibe', 'erkläre', 'erläutere', 'begründe',
    'vergleiche', 'bewerte', 'analysiere', 'übersetze', 'berechne', 'bestimme',
    'nenne', 'skizziere', 'interpretiere', 'zusammen', 'außerdem', 'darüber',
    'können', 'sollen', 'müssen', 'wichtig', 'wichtige',
  };

  /// Einfache Schlüsselwort-Extraktion: lange, seltene Wörter.
  List<String> _keywords(String text, {required int max}) {
    final words = RegExp(r'[A-Za-zÄÖÜäöüß]{6,}')
        .allMatches(text)
        .map((m) => m[0]!)
        .where((w) => !_stopWords.contains(w.toLowerCase()));
    final seen = <String>{};
    final unique = <String>[];
    for (final w in words) {
      if (seen.add(w.toLowerCase())) unique.add(w);
    }
    unique.sort((a, b) => b.length.compareTo(a.length));
    return unique.take(max).toList();
  }
}
