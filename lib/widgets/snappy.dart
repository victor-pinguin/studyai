import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Stimmung des Maskottchens.
enum SnappyMood { happy, wow, sad }

/// Snappy – die Lern-Eule mit Brille, das Maskottchen der App.
///
/// Wird komplett gezeichnet (kein Bild, keine Zusatzpakete) und bewegt sich:
/// sie wippt, wiegt sich, schlägt mit den Flügeln, blinzelt und ihr Stern
/// funkelt. Beispiel: `const Snappy(size: 90, mood: SnappyMood.wow)`
class Snappy extends StatefulWidget {
  const Snappy({
    super.key,
    this.size = 72,
    this.mood = SnappyMood.happy,
    this.bounce = true,
  });

  final double size;
  final SnappyMood mood;

  /// Sanftes Auf und Ab. Blinzeln und Flügelschlag laufen auch ohne.
  final bool bounce;

  @override
  State<Snappy> createState() => _SnappyState();
}

class _SnappyState extends State<Snappy> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return CustomPaint(
      size: Size(widget.size, widget.size * 78 / 72),
      painter: _OwlPainter(
        mood: widget.mood,
        bounce: widget.bounce && !reduce,
        still: reduce,
        animation: _controller,
      ),
    );
  }
}

/// Zeichnet die Eule in einem 72 × 78 Raster und skaliert sie.
class _OwlPainter extends CustomPainter {
  _OwlPainter({
    required this.mood,
    required this.bounce,
    required this.still,
    required this.animation,
  }) : super(repaint: animation);

  final SnappyMood mood;
  final bool bounce;
  final bool still;
  final Animation<double> animation;

  static const _ink = Color(0xFF1B2559);
  static const _brow = Color(0xFF3B4890);
  static const _belly = Color(0xFFFFF4DE);
  static const _feather = Color(0xFFF0DCB6);
  static const _glasses = Color(0xFFFFA51F);
  static const _beakTop = Color(0xFFFFC24D);
  static const _beakBottom = Color(0xFFEF8A16);
  static const _beakLine = Color(0xFFE07B12);

  @override
  void paint(Canvas canvas, Size size) {
    final t = still ? 0.0 : animation.value;

    // Bewegungen: Wippen und Flügel doppelt so schnell wie das Wiegen
    final bob = bounce ? -5 * math.sin(2 * math.pi * t * 2) : 0.0;
    final sway = still ? 0.0 : 2.4 * math.pi / 180 * math.sin(2 * math.pi * t);
    final flap = still
        ? 0.0
        : 14 * math.pi / 180 * (0.5 - 0.5 * math.cos(4 * math.pi * t));
    final twinkle = still ? 1.0 : 1 + 0.3 * (0.5 - 0.5 * math.cos(4 * math.pi * t));
    final blink = _blink(t);

    canvas.save();
    canvas.scale(size.width / 72);
    canvas.translate(0, bob);
    canvas.translate(36, 66);
    canvas.rotate(sway);
    canvas.translate(-36, -66);

    final p = Paint()..isAntiAlias = true;

    // Federohren
    p.color = const Color(0xFF8E6BFF);
    canvas.drawPath(
        _path('M14.5 25.5c-1.4-7.4.6-14.4 5.6-20 3.6 4.8 5.8 10 6.6 15.6z'), p);
    p.color = const Color(0xFF5FA8FF);
    canvas.drawPath(
        _path('M57.5 25.5c1.4-7.4-.6-14.4-5.6-20-3.6 4.8-5.8 10-6.6 15.6z'), p);

    // Körper
    p.shader = const LinearGradient(
      colors: [Color(0xFF9B7CFF), Color(0xFF6C86FF), AppTheme.sky],
      stops: [0.0, .5, 1.0],
      begin: Alignment(-.8, -1),
      end: Alignment(.8, 1),
    ).createShader(const Rect.fromLTWH(8, 8.5, 56, 61.5));
    canvas.drawPath(
      _path('M36 8.5c17.6 0 28 14.4 28 32.2C64 58.6 51.6 70 36 70S8 58.6 8 40.7'
          'C8 22.9 18.4 8.5 36 8.5z'),
      p,
    );
    p.shader = null;

    // Lichtpunkt oben links
    p.color = Colors.white.withValues(alpha: .13);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(25, 24), width: 26, height: 18), p);

    // Bauch
    p.color = _belly;
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(36, 51), width: 37, height: 34), p);
    p
      ..color = _feather
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
        _path('M28 62.5c2.7-2.6 5.3-2.6 8 0 2.7-2.6 5.3-2.6 8 0'), p);
    p.style = PaintingStyle.fill;

    // Flügel – sie schlagen um die Schulter
    _wing(canvas, p,
        pivot: const Offset(15.5, 31.5),
        angle: -flap,
        color: const Color(0xFF5E3FE0),
        d: 'M15.5 31.5c-6.4 6.4-8 18-2 27.4 1-9.8 2.6-17.6 6-22.4z');
    _wing(canvas, p,
        pivot: const Offset(56.5, 31.5),
        angle: flap,
        color: const Color(0xFF1B90D6),
        d: 'M56.5 31.5c6.4 6.4 8 18 2 27.4-1-9.8-2.6-17.6-6-22.4z');

    // Wangen
    p.color = AppTheme.bubblegum.withValues(alpha: .45);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(18.5, 47.5), width: 9.2, height: 6),
        p);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(53.5, 47.5), width: 9.2, height: 6),
        p);

    // Augen
    const leftEye = Offset(25, 36);
    const rightEye = Offset(47, 36);
    final pupilY = mood == SnappyMood.sad ? 38.5 : 36.0;
    final pupilR = mood == SnappyMood.wow ? 6.2 : 5.0;

    p.color = Colors.white;
    canvas.drawCircle(leftEye, 11, p);
    canvas.drawCircle(rightEye, 11, p);

    p.color = AppTheme.sun.withValues(alpha: .45);
    canvas.drawCircle(Offset(leftEye.dx, pupilY), pupilR + 2.6, p);
    canvas.drawCircle(Offset(rightEye.dx, pupilY), pupilR + 2.6, p);

    p.color = _ink;
    canvas.drawCircle(Offset(leftEye.dx, pupilY), pupilR, p);
    canvas.drawCircle(Offset(rightEye.dx, pupilY), pupilR, p);

    p.color = Colors.white;
    canvas.drawCircle(Offset(leftEye.dx + 2, pupilY - 2), 1.9, p);
    canvas.drawCircle(Offset(rightEye.dx + 2, pupilY - 2), 1.9, p);
    p.color = Colors.white.withValues(alpha: .7);
    canvas.drawCircle(Offset(leftEye.dx - 1.7, pupilY + 2.4), .9, p);
    canvas.drawCircle(Offset(rightEye.dx - 1.7, pupilY + 2.4), .9, p);

    // Lider – Snappy blinzelt
    if (blink > 0) {
      _lid(canvas, p, leftEye, blink, const Color(0xFF7E8CFF));
      _lid(canvas, p, rightEye, blink, const Color(0xFF6E9BFF));
    }

    // Brauen
    p
      ..color = _brow.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_path(_brows), p);

    // Brille
    p
      ..color = _glasses
      ..strokeWidth = 2.8;
    canvas.drawCircle(leftEye, 12, p);
    canvas.drawCircle(rightEye, 12, p);
    canvas.drawPath(_path('M37 36h-2M13 33.5 8.5 31.5M59 33.5l4.5-2'), p);
    p
      ..color = Colors.white.withValues(alpha: .5)
      ..strokeWidth = 2;
    canvas.drawPath(
        _path('M18.6 29.6c1.7-1.8 3.6-2.8 5.4-3.2'
            'M40.6 29.6c1.7-1.8 3.6-2.8 5.4-3.2'),
        p);
    p.style = PaintingStyle.fill;

    // Schnabel
    _beak(canvas, p);

    // Füße
    p
      ..color = _glasses
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6;
    canvas.drawPath(
        _path('M28 69.5v3.4M28 72.9c-1.5 1-2.9 1.6-4.3 1.9'
            'M28 72.9c1.5 1 2.9 1.6 4.3 1.9'),
        p);
    canvas.drawPath(
        _path('M44 69.5v3.4M44 72.9c-1.5 1-2.9 1.6-4.3 1.9'
            'M44 72.9c1.5 1 2.9 1.6 4.3 1.9'),
        p);
    p.style = PaintingStyle.fill;

    // Stern am Federohr – er funkelt
    canvas.save();
    canvas.translate(21, 6);
    canvas.scale(twinkle);
    canvas.translate(-21, -6);
    p.shader = const LinearGradient(colors: [Color(0xFFFFE071), Color(0xFFFF9A3D)])
        .createShader(const Rect.fromLTWH(15, 0, 12, 12));
    canvas.drawPath(_star(const Offset(21, 6), 5.6, 2.6), p);
    p.shader = null;
    canvas.restore();

    canvas.restore();
  }

  // ---------------------------------------------------------------------------
  // Bausteine
  // ---------------------------------------------------------------------------

  String get _brows => switch (mood) {
        SnappyMood.sad =>
          'M15.5 21c3.8 1 7.4 2.4 10 4.2M56.5 21c-3.8 1-7.4 2.4-10 4.2',
        SnappyMood.wow =>
          'M15.5 21.5c3.8-2.8 7.6-3.6 10.6-2.6M56.5 21.5c-3.8-2.8-7.6-3.6-10.6-2.6',
        SnappyMood.happy =>
          'M16.5 24c3.4-2.8 7-3.6 10-2.8M55.5 24c-3.4-2.8-7-3.6-10-2.8',
      };

  void _wing(
    Canvas canvas,
    Paint p, {
    required Offset pivot,
    required double angle,
    required Color color,
    required String d,
  }) {
    canvas.save();
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(angle);
    canvas.translate(-pivot.dx, -pivot.dy);
    p
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(_path(d), p);
    canvas.restore();
  }

  void _lid(Canvas canvas, Paint p, Offset eye, double amount, Color color) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: eye, radius: 11)));
    p
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(eye.dx, 13 + 24 * amount), 11.6, p);
    canvas.restore();
  }

  void _beak(Canvas canvas, Paint p) {
    p.shader = const LinearGradient(
      colors: [_beakTop, _beakBottom],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(const Rect.fromLTWH(30, 46, 12, 12));

    switch (mood) {
      case SnappyMood.wow:
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(36, 52.5), width: 10, height: 13.2),
            p);
        p.shader = null;
        p.color = const Color(0xFFC96A0C).withValues(alpha: .45);
        canvas.drawOval(
            Rect.fromCenter(center: const Offset(36, 54.6), width: 5.2, height: 6),
            p);
      case SnappyMood.sad:
        canvas.drawPath(
            _path('M36 47.5c1.2 0 5.5 5 5.5 6.2 0 .9-11 .9-11 0 0-1.2 4.3-6.2 5.5-6.2z'),
            p);
        p.shader = null;
        _mouth(canvas, p, 'M31.5 57.4c2.6-2.2 6.4-2.2 9 0');
      case SnappyMood.happy:
        canvas.drawPath(
            _path('M36 46.4c1.3 0 6 5.4 6 6.7 0 1-12 1-12 0 0-1.3 4.7-6.7 6-6.7z'),
            p);
        p.shader = null;
        _mouth(canvas, p, 'M31 56.2c2.9 2.6 6.1 2.6 9 0');
    }
    p.shader = null;
    p.style = PaintingStyle.fill;
  }

  void _mouth(Canvas canvas, Paint p, String d) {
    p
      ..color = _beakLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(_path(d), p);
    p.style = PaintingStyle.fill;
  }

  /// Blinzeln kurz vor Ende jeder Runde: 0 = offen, 1 = zu.
  double _blink(double t) {
    const start = .92, mid = .941, end = .964;
    if (t < start || t > end) return 0;
    return t < mid
        ? (t - start) / (mid - start)
        : 1 - (t - mid) / (end - mid);
  }

  Path _star(Offset center, double outer, double inner) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point =
          Offset(center.dx + r * math.cos(angle), center.dy + r * math.sin(angle));
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_OwlPainter old) =>
      old.mood != mood || old.bounce != bounce || old.still != still;
}

// -----------------------------------------------------------------------------
// Kleiner SVG-Pfad-Leser: damit die Zeichnung exakt der Web-Vorschau entspricht.
// Unterstützt M, L, H, V, C, S, Q, Z (groß = absolut, klein = relativ).
// -----------------------------------------------------------------------------

final RegExp _tokenPattern = RegExp(r'[MmLlHhVvCcSsQqZz]|-?\d*\.?\d+');
final Map<String, Path> _pathCache = {};

Path _path(String d) => _pathCache.putIfAbsent(d, () => _parsePath(d));

Path _parsePath(String d) {
  final path = Path();
  final tokens = _tokenPattern.allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  var cmd = '';
  var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0;
  var lastCx = 0.0, lastCy = 0.0;
  var lastWasCurve = false;

  double n() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final token = tokens[i];
    if (double.tryParse(token) == null) {
      cmd = token;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cx = sx;
        cy = sy;
        lastWasCurve = false;
        continue;
      }
    }
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        var x = n(), y = n();
        if (rel) {
          x += cx;
          y += cy;
        }
        path.moveTo(x, y);
        cx = sx = x;
        cy = sy = y;
        cmd = rel ? 'l' : 'L';
        lastWasCurve = false;
      case 'L':
        var x = n(), y = n();
        if (rel) {
          x += cx;
          y += cy;
        }
        path.lineTo(x, y);
        cx = x;
        cy = y;
        lastWasCurve = false;
      case 'H':
        var x = n();
        if (rel) x += cx;
        path.lineTo(x, cy);
        cx = x;
        lastWasCurve = false;
      case 'V':
        var y = n();
        if (rel) y += cy;
        path.lineTo(cx, y);
        cy = y;
        lastWasCurve = false;
      case 'C':
        var x1 = n(), y1 = n(), x2 = n(), y2 = n(), x = n(), y = n();
        if (rel) {
          x1 += cx;
          y1 += cy;
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCx = x2;
        lastCy = y2;
        cx = x;
        cy = y;
        lastWasCurve = true;
      case 'S':
        var x2 = n(), y2 = n(), x = n(), y = n();
        if (rel) {
          x2 += cx;
          y2 += cy;
          x += cx;
          y += cy;
        }
        final x1 = lastWasCurve ? 2 * cx - lastCx : cx;
        final y1 = lastWasCurve ? 2 * cy - lastCy : cy;
        path.cubicTo(x1, y1, x2, y2, x, y);
        lastCx = x2;
        lastCy = y2;
        cx = x;
        cy = y;
        lastWasCurve = true;
      case 'Q':
        var x1 = n(), y1 = n(), x = n(), y = n();
        if (rel) {
          x1 += cx;
          y1 += cy;
          x += cx;
          y += cy;
        }
        path.quadraticBezierTo(x1, y1, x, y);
        cx = x;
        cy = y;
        lastWasCurve = false;
      default:
        i++; // unbekannt: überspringen statt abstürzen
    }
  }
  return path;
}

/// Sprechblase neben Snappy.
class SnappyBubble extends StatelessWidget {
  const SnappyBubble({
    super.key,
    required this.text,
    this.mood = SnappyMood.happy,
    this.size = 62,
    this.rich,
  });

  final String text;
  final SnappyMood mood;
  final double size;

  /// Optional: eigener Inhalt statt einfachem Text.
  final Widget? rich;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Snappy(size: size, mood: mood, bounce: false),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppTheme.borderColor(context), width: 2),
            ),
            child: rich ??
                Text(text,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(fontWeight: FontWeight.w700, height: 1.45)),
          ),
        ),
      ],
    );
  }
}

/// Drei Sterne für das Quiz-Ergebnis.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.filled, this.size = 52});

  final int filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: i < filled ? 1.15 : 0.9),
            duration: Duration(milliseconds: 500 + i * 180),
            curve: Curves.elasticOut,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                i < filled ? Icons.star_rounded : Icons.star_outline_rounded,
                size: size,
                color: i < filled
                    ? AppTheme.sun
                    : Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: .35),
              ),
            ),
          ),
      ],
    );
  }
}
