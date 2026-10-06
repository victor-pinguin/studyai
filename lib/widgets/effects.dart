import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Wackelt kurz, wenn [trigger] sich ändert – für falsche Antworten.
class Shake extends StatefulWidget {
  const Shake({super.key, required this.trigger, required this.child});

  /// Jede Änderung startet das Wackeln neu (z. B. der Index der Antwort).
  final Object? trigger;
  final Widget child;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        // drei abklingende Ausschläge
        final v = math.sin(_c.value * math.pi * 6) * (1 - _c.value) * 9;
        return Transform.translate(offset: Offset(v, 0), child: child);
      },
      child: widget.child,
    );
  }
}

/// Kurzer Hüpfer, wenn [trigger] sich ändert – für richtige Antworten.
class Pop extends StatefulWidget {
  const Pop({super.key, required this.trigger, required this.child});

  final Object? trigger;
  final Widget child;

  @override
  State<Pop> createState() => _PopState();
}

class _PopState extends State<Pop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didUpdateWidget(Pop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _c.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 1.06)
          .chain(CurveTween(curve: Curves.elasticOut))
          .animate(_c),
      child: widget.child,
    );
  }
}

/// Konfetti über dem Ergebnis – komplett gezeichnet, ohne Zusatzpaket.
class Confetti extends StatefulWidget {
  const Confetti({super.key, this.pieces = 34, this.play = true});

  final int pieces;
  final bool play;

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  static const _colors = [
    Color(0xFF7C5CFF),
    Color(0xFF38BDF8),
    Color(0xFFFFC53D),
    Color(0xFF35C77A),
    Color(0xFFFF7AB6),
  ];

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    _pieces = List.generate(
      widget.pieces,
      (i) => _Piece(
        x: rnd.nextDouble(),
        delay: rnd.nextDouble() * 0.35,
        speed: 0.75 + rnd.nextDouble() * 0.5,
        drift: (rnd.nextDouble() - 0.5) * 0.25,
        spin: (rnd.nextDouble() - 0.5) * 12,
        color: _colors[i % _colors.length],
      ),
    );
    if (widget.play) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ConfettiPainter(_pieces, _c),
        size: Size.infinite,
      ),
    );
  }
}

class _Piece {
  _Piece({
    required this.x,
    required this.delay,
    required this.speed,
    required this.drift,
    required this.spin,
    required this.color,
  });

  final double x, delay, speed, drift, spin;
  final Color color;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.animation) : super(repaint: animation);

  final List<_Piece> pieces;
  final Animation<double> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final paint = Paint();
    for (final p in pieces) {
      final local = ((t - p.delay) * p.speed).clamp(0.0, 1.0);
      if (local <= 0 || local >= 1) continue;
      final x = (p.x + p.drift * local) * size.width;
      final y = local * (size.height + 60) - 40;
      paint.color = p.color.withValues(alpha: 1 - local * local);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * local);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-5, -7, 10, 15),
          const Radius.circular(3),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter oldDelegate) => false;
}
