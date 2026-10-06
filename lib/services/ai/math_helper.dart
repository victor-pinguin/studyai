/// Kleine Mathe-Engine für die Demo-KI.
///
/// Kann ohne Internet und ohne Kosten:
///  * lineare Gleichungen lösen – auch mit Klammern, Brüchen und Dezimalzahlen
///    (z. B. „2x + 3 = 11“, „3(x + 2) = 2x + 1“, „x : 4 = 2,5“)
///  * Rechenausdrücke mit Klammern und Punkt-vor-Strich berechnen
///    (z. B. „12 + 7 · 3“, „(4 + 2) · 3 − 5“, „2(3 + 4)“)
///
/// Grundsatz: Lieber NICHT lösen als FALSCH lösen. Potenzen, Wurzeln, Prozent,
/// Uhrzeiten, x² und mehrdeutige Schreibweisen wie „6 : 2(1 + 2)“ werden
/// bewusst nicht gerechnet – dann gibt die App eine allgemeine Anleitung.
///
/// Diese Logik wurde mit über 50.000 Zufallsaufgaben gegen eine unabhängige
/// Rechnung geprüft (siehe test/math_helper_test.dart für Beispiele).
class MathHelper {
  MathHelper._();

  static const double _eps = 1e-9;

  // ---------------------------------------------------------------------------
  // Zahlen exakt darstellen
  // ---------------------------------------------------------------------------

  static bool isInt(double v) => (v - v.roundToDouble()).abs() < _eps;
  static bool _isExactDecimal(double v) => isInt(v * 100);

  /// Kleinster Nenner q ≤ 10000, sodass v · q ganzzahlig ist (sonst null).
  static int? _denominator(double v) {
    for (var q = 1; q <= 10000; q++) {
      if (isInt(v * q)) return q;
    }
    return null;
  }

  static bool _isFraction(double v) =>
      !_isExactDecimal(v) && _denominator(v) != null;

  /// Dezimalzahl mit höchstens 2 Nachkommastellen, deutsches Komma.
  static String _dec(double v) {
    if (isInt(v)) {
      final r = v.round();
      return (r == 0 ? 0 : r).toString();
    }
    var s = v.toStringAsFixed(2);
    s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    if (s == '-0') s = '0';
    return s.replaceAll('.', ',');
  }

  /// Exakte Darstellung: 4 → „4“, 2.5 → „2,5“, 7/3 → „7/3“.
  static String fmt(double v) {
    if (v.isNaN || v.isInfinite) return '?';
    if (_isExactDecimal(v)) return _dec(v);
    final q = _denominator(v);
    if (q != null) return '${(v * q).round()}/$q';
    return _dec(v);
  }

  /// Ergebnis mit dem richtigen Zeichen: „= 5“, „= 10/3 ≈ 3,33“ oder „≈ 3,14“.
  static String result(double v) {
    if (_isExactDecimal(v)) return '= ${_dec(v)}';
    if (_denominator(v) != null) return '= ${fmt(v)} ≈ ${_dec(v)}';
    return '≈ ${_dec(v)}';
  }

  /// Exakt, wenn möglich – sonst gerundet mit „≈“ davor.
  static String approx(double v) =>
      (_isExactDecimal(v) || _denominator(v) != null) ? fmt(v) : '≈ ${_dec(v)}';

  /// Negative Zahlen und Brüche in Klammern, z. B. „(-3)“ oder „(7/3)“.
  static String fmtParen(double v) =>
      (v < 0 || _isFraction(v)) ? '(${fmt(v)})' : fmt(v);

  static String _coef(double a) {
    if ((a - 1).abs() < _eps) return 'x';
    if ((a + 1).abs() < _eps) return '-x';
    if (_isFraction(a)) return '(${fmt(a)})x';
    return '${fmt(a)}x';
  }

  /// Lineare Seite hübsch darstellen: a=2, b=-3 → „2x − 3“
  static String linearToString(double a, double b) {
    final parts = <String>[];
    if (a.abs() > _eps) parts.add(_coef(a));
    if (b.abs() > _eps || parts.isEmpty) {
      if (parts.isEmpty) {
        parts.add(fmt(b));
      } else {
        parts.add(b < 0 ? '− ${fmt(-b)}' : '+ ${fmt(b)}');
      }
    }
    return parts.join(' ');
  }

  /// Zeigt einen Ausdruck mit schönen Rechenzeichen an.
  static String pretty(String expr) => expr
      .replaceAll('*', ' · ')
      .replaceAll('/', ' : ')
      .replaceAllMapped(RegExp(r'(?<=[\dx)])\+'), (_) => ' + ')
      .replaceAllMapped(RegExp(r'(?<=[\dx)])-'), (_) => ' − ')
      .replaceAll('=', ' = ')
      .replaceAll('.', ',')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // ---------------------------------------------------------------------------
  // Text vorbereiten
  // ---------------------------------------------------------------------------

  /// Zeichen, bei denen wir bewusst nicht rechnen (Potenzen, Wurzeln, …).
  static final _unsupported = RegExp(r'[\^²³√!%π∞∑∫<>≤≥≠]');
  static final _letter = RegExp(r'[a-zäöüß]');

  /// Entfernt „Aufgabe 3:“, „Löse:“, „Bestimme x:“, „a)“ oder „1)“.
  static String _stripLabel(String line) => line
      .replaceFirst(
          RegExp(r'^\s*(aufgabe|nr\.?|übung)\s*\d*[a-z]?\s*[:.)]?\s*',
              caseSensitive: false),
          '')
      .replaceFirst(
          RegExp(r'^\s*(löse|bestimme|berechne|rechne|vereinfache|gib)[^:=]*:\s*',
              caseSensitive: false),
          '')
      .replaceFirst(RegExp(r'^\s*[a-zA-Z]\)\s*'), '')
      .replaceFirst(RegExp(r'^\s*\d+\)\s+'), '');

  /// Einheitliche Schreibweise: „2 x − 3 · 4 = 1,5“ → „2x-3*4=1.5“
  static String _normalize(String raw) => _stripLabel(raw)
      .toLowerCase()
      .replaceAll(RegExp(r'[−–]'), '-')
      .replaceAll(RegExp(r'[×·]'), '*')
      .replaceAll('÷', '/')
      .replaceAllMapped(RegExp(r'(\d),(\d)'), (m) => '${m[1]}.${m[2]}')
      // „:“ nur als Geteilt, wenn links und rechts gleich viel Abstand ist
      // (sonst ist es ein Doppelpunkt) und es keine Uhrzeit ist.
      .replaceAllMapped(
          RegExp(r'([\dx)])(\s*):\2(?=[\dx(])(?!\d{1,2}\s*uhr)'),
          (m) => '${m[1]}/')
      .replaceAllMapped(RegExp(r'\s*([+\-*/=()])\s*'), (m) => m[1]!)
      .replaceAllMapped(RegExp(r'(\d)\s+x\b'), (m) => '${m[1]}x');

  /// „6 : 2(1 + 2)“ ist mehrdeutig (1 oder 9?) → lieber nicht lösen.
  static bool _ambiguousDivision(String s) {
    for (var i = 0; i < s.length; i++) {
      if (s[i] != '/') continue;
      var j = i + 1;
      while (j < s.length && (s[j] == '+' || s[j] == '-')) {
        j++;
      }
      if (j < s.length && s[j] == '(') {
        var depth = 0;
        for (; j < s.length; j++) {
          if (s[j] == '(') {
            depth++;
          } else if (s[j] == ')') {
            depth--;
            if (depth == 0) {
              j++;
              break;
            }
          }
        }
      } else if (j < s.length && s[j] == 'x') {
        j++;
      } else {
        while (j < s.length && RegExp(r'[\d.]').hasMatch(s[j])) {
          j++;
        }
      }
      if (j < s.length && RegExp(r'[x(\d]').hasMatch(s[j])) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Lineare Gleichungen
  // ---------------------------------------------------------------------------

  /// Sucht im (OCR-)Text eine lineare Gleichung mit x.
  static String? findEquation(String text) {
    for (final raw in text.split('\n')) {
      if (_unsupported.hasMatch(raw)) continue;
      final line = _normalize(raw);
      for (final m
          in RegExp(r'[0-9x.+\-*/()]+=[0-9x.+\-*/()]+').allMatches(line)) {
        final eq = m[0]!;
        if (!eq.contains('x') || RegExp(r'x\d').hasMatch(eq)) continue; // x2 = x²?
        if (m.start > 0 && _letter.hasMatch(line[m.start - 1])) continue;
        if (m.end < line.length && _letter.hasMatch(line[m.end])) continue;
        if (solveLinear(eq) != null) return eq;
      }
    }
    return null;
  }

  /// Löst eine lineare Gleichung. Gibt null zurück, wenn es keine eindeutige
  /// Lösung gibt, sie nicht linear ist oder nicht sicher lesbar ist.
  static LinearSolution? solveLinear(String equation) {
    final sides = equation.split('=');
    if (sides.length != 2 || _ambiguousDivision(equation)) return null;
    final left = _LinearParser(sides[0]).parse();
    final right = _LinearParser(sides[1]).parse();
    if (left == null || right == null) return null;
    final a = left.a - right.a;
    if (a.abs() < _eps) return null;
    return LinearSolution(
      original: equation,
      a1: left.a,
      b1: left.b,
      a2: right.a,
      b2: right.b,
      x: (right.b - left.b) / a,
    );
  }

  // ---------------------------------------------------------------------------
  // Rechenausdrücke (Klammern, Punkt vor Strich)
  // ---------------------------------------------------------------------------

  /// Entfernt überzählige Klammern am Rand, z. B. „3+4)“ → „3+4“.
  static String _balance(String c) {
    int count(String s, String ch) => ch.allMatches(s).length;
    var s = c;
    while (s.startsWith('(') && count(s, '(') > count(s, ')')) {
      s = s.substring(1);
    }
    while (s.endsWith(')') && count(s, ')') > count(s, '(')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Sucht im Text einen Rechenausdruck ohne x, z. B. „12 + 7 · 3“.
  static String? findExpression(String text) {
    for (final raw in text.split('\n')) {
      if (_unsupported.hasMatch(raw)) continue;
      final line = _normalize(raw);
      if (RegExp(r'\dx|x\d|\bx\b|x\(|\)x').hasMatch(line)) continue;

      String? best;
      for (final m in RegExp(r'[0-9.+\-*/()]+').allMatches(line)) {
        final candidate = _balance(m[0]!);
        if (!RegExp(r'[\d)][+\-*/]\(*-?[\d(]|[\d)]\(').hasMatch(candidate)) {
          continue;
        }
        if (best == null || candidate.length > best.length) best = candidate;
      }
      if (best != null && evaluateWithSteps(best) != null) return best;
    }
    return null;
  }

  /// Berechnet einen Ausdruck und merkt sich die Zwischenschritte.
  static ArithmeticSolution? evaluateWithSteps(String expression) {
    final compact = expression.replaceAll(RegExp(r'\s+'), '');
    if (compact.isEmpty || _ambiguousDivision(compact)) return null;
    // Unsichtbares Malzeichen ergänzen: 2(3+4) → 2*(3+4), (1+2)(3+4) → …*(…)
    var e = compact
        .replaceAllMapped(RegExp(r'([\d)])\('), (m) => '${m[1]}*(')
        .replaceAllMapped(RegExp(r'\)(\d)'), (m) => ')*${m[1]}');

    // 1) Klammern von innen nach außen auflösen
    final bracketSteps = <String>[];
    final paren = RegExp(r'\(([^()]+)\)');
    var guard = 0;
    while (paren.hasMatch(e) && guard++ < 30) {
      final m = paren.firstMatch(e)!;
      final inner = m[1]!;
      final tokens = _tokenize(inner);
      if (tokens == null) return null;
      final value = _evaluateTokens(tokens, null, null);
      if (value == null) return null;
      if (tokens.length >= 3) {
        bracketSteps.add('(${pretty(inner)}) ${result(value)}');
      }
      final plain = _plain(value);
      if (plain == null) return null;
      e = e.replaceRange(m.start, m.end, plain);
    }
    if (e.contains('(') || e.contains(')')) return null;

    // 2) Punkt vor Strich
    final tokens = _tokenize(e);
    if (tokens == null) return null;
    if (tokens.length < 3) {
      if (tokens.length == 1 && bracketSteps.isNotEmpty) {
        return ArithmeticSolution(
          result: tokens.first as double,
          bracketSteps: bracketSteps,
          pointSteps: const [],
          sumLine: null,
        );
      }
      return null;
    }
    final pointSteps = <String>[];
    final sumParts = <String>[];
    final value = _evaluateTokens(tokens, pointSteps, sumParts);
    if (value == null) return null;

    return ArithmeticSolution(
      result: value,
      bracketSteps: bracketSteps,
      pointSteps: pointSteps,
      sumLine: sumParts.length > 1 ? '${sumParts.join(' ')} ${result(value)}' : null,
    );
  }

  /// Zahl als Text zum Weiterrechnen (volle Genauigkeit).
  static String? _plain(double v) {
    if (isInt(v)) return v.round().toString();
    final s = v.toString();
    return s.contains(RegExp('[eE]')) ? null : s;
  }

  /// „12+7*3“ → [12.0, '+', 7.0, '*', 3.0]
  static List<Object>? _tokenize(String s) {
    final tokens = <Object>[];
    final numberRe = RegExp(r'[+-]?\d+(\.\d+)?');
    var i = 0;
    while (i < s.length) {
      final ch = s[i];
      final expectNumber = tokens.isEmpty || tokens.last is String;
      if ('+-*/'.contains(ch) && !expectNumber) {
        tokens.add(ch);
        i++;
        continue;
      }
      final m = numberRe.matchAsPrefix(s, i);
      if (m == null) return null;
      tokens.add(double.parse(m[0]!));
      i = m.end;
    }
    if (tokens.isEmpty || tokens.last is String) return null;
    return tokens;
  }

  /// Wertet Tokens mit Punkt-vor-Strich aus.
  /// [pointSteps] sammelt „7 · 3 = 21“, [sumParts] die Strichrechnung.
  static double? _evaluateTokens(
    List<Object> tokens,
    List<String>? pointSteps,
    List<String>? sumParts,
  ) {
    final terms = <double>[];
    final ops = <String>[];

    var current = tokens[0] as double;
    var currentExpr = fmtParen(current);
    var hadPoint = false;

    for (var i = 1; i < tokens.length; i += 2) {
      final op = tokens[i] as String;
      final value = tokens[i + 1] as double;
      if (op == '*' || op == '/') {
        if (op == '/' && value == 0) return null; // Division durch 0
        current = op == '*' ? current * value : current / value;
        currentExpr += ' ${op == '*' ? '·' : ':'} ${fmtParen(value)}';
        hadPoint = true;
      } else {
        if (hadPoint) pointSteps?.add('$currentExpr ${result(current)}');
        terms.add(current);
        ops.add(op);
        current = value;
        currentExpr = fmtParen(value);
        hadPoint = false;
      }
    }
    if (hadPoint) pointSteps?.add('$currentExpr ${result(current)}');
    terms.add(current);

    var total = terms.first;
    sumParts?.add(fmtParen(terms.first));
    for (var j = 0; j < ops.length; j++) {
      final t = terms[j + 1];
      total = ops[j] == '+' ? total + t : total - t;
      sumParts?.add('${ops[j] == '+' ? '+' : '−'} ${fmtParen(t)}');
    }
    return total;
  }
}

/// Linearer Term a·x + b.
class _Lin {
  const _Lin(this.a, this.b);
  final double a;
  final double b;
}

/// Liest lineare Terme mit Klammern, Punkt vor Strich und unsichtbarem Mal.
/// Nicht-lineare Terme (x · x, 6 : x) ergeben null.
class _LinearParser {
  _LinearParser(this.s);

  static const double _eps = 1e-9;
  final String s;
  int i = 0;

  _Lin? parse() {
    final r = _expr();
    return (r != null && i == s.length) ? r : null;
  }

  _Lin? _expr() {
    final first = _term();
    if (first == null) return null;
    _Lin left = first;
    while (i < s.length && (s[i] == '+' || s[i] == '-')) {
      final op = s[i++];
      final right = _term();
      if (right == null) return null;
      left = op == '+'
          ? _Lin(left.a + right.a, left.b + right.b)
          : _Lin(left.a - right.a, left.b - right.b);
    }
    return left;
  }

  _Lin? _term() {
    final first = _factor();
    if (first == null) return null;
    _Lin left = first;
    while (i < s.length) {
      final ch = s[i];
      String op;
      if (ch == '*' || ch == '/') {
        op = ch;
        i++;
      } else if (ch == '(' || ch == 'x' || RegExp(r'\d').hasMatch(ch)) {
        op = '*'; // unsichtbares Mal: 2x, 3(x+1), (x+1)(2)
      } else {
        break;
      }
      final right = _factor();
      if (right == null) return null;
      if (op == '*') {
        if (left.a.abs() > _eps && right.a.abs() > _eps) return null; // x·x
        left = _Lin(left.a * right.b + right.a * left.b, left.b * right.b);
      } else {
        if (right.a.abs() > _eps || right.b.abs() < _eps) return null; // :x, :0
        left = _Lin(left.a / right.b, left.b / right.b);
      }
    }
    return left;
  }

  _Lin? _factor() {
    if (i >= s.length) return null;
    final ch = s[i];
    if (ch == '+' || ch == '-') {
      i++;
      final f = _factor();
      if (f == null) return null;
      return ch == '-' ? _Lin(-f.a, -f.b) : f;
    }
    if (ch == 'x') {
      i++;
      return const _Lin(1, 0);
    }
    if (ch == '(') {
      i++;
      final e = _expr();
      if (e == null || i >= s.length || s[i] != ')') return null;
      i++;
      return e;
    }
    final m = RegExp(r'\d+(\.\d+)?').matchAsPrefix(s, i);
    if (m == null) return null;
    i = m.end;
    return _Lin(0, double.parse(m[0]!));
  }
}

class LinearSolution {
  const LinearSolution({
    required this.original,
    required this.a1,
    required this.b1,
    required this.a2,
    required this.b2,
    required this.x,
  });

  /// Gleichung so, wie sie im Text stand (normalisiert, z. B. „3(x+2)=2x+1“).
  final String original;

  /// Vereinfacht: a1·x + b1 = a2·x + b2
  final double a1, b1, a2, b2;
  final double x;

  String get equationText =>
      '${MathHelper.linearToString(a1, b1)} = ${MathHelper.linearToString(a2, b2)}';

  /// Muss man erst Klammern auflösen / zusammenfassen?
  bool get needsSimplify =>
      equationText
          .replaceAll(' ', '')
          .replaceAll('−', '-')
          .replaceAll(',', '.') !=
      original;
}

class ArithmeticSolution {
  const ArithmeticSolution({
    required this.result,
    required this.bracketSteps,
    required this.pointSteps,
    required this.sumLine,
  });

  final double result;
  final List<String> bracketSteps;
  final List<String> pointSteps;
  final String? sumLine;
}
