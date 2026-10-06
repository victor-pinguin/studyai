import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_theme.dart';

/// Logo „StudySnap AI“ – Symbol + Schriftzug.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 40,
    this.showText = true,
    this.onDark = false,
  });

  final double size;
  final bool showText;

  /// true = steht auf farbigem Hintergrund (Hero-Karte).
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: onDark ? null : AppTheme.brandGradient,
        color: onDark ? Colors.white.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: onDark
            ? null
            : [
                BoxShadow(
                  color: AppTheme.violet.withValues(alpha: 0.38),
                  blurRadius: size * 0.45,
                  offset: Offset(0, size * 0.16),
                ),
              ],
      ),
      child: Icon(Icons.photo_camera_rounded,
          color: Colors.white, size: size * 0.52),
    );

    if (!showText) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.28),
        Text(
          'StudySnap AI',
          style: GoogleFonts.outfit(
            fontSize: size * 0.48,
            fontWeight: FontWeight.w800,
            letterSpacing: -.4,
            color: onDark ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
