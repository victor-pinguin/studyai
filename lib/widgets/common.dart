import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// Karte im App-Stil – optional mit Farbverlauf, Schatten und Tap.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.onTap,
    this.color,
    this.gradient,
    this.radius = AppTheme.rCard,
    this.shadow = false,
    this.dashedLook = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Gradient? gradient;
  final double radius;
  final bool shadow;

  /// Leicht abgesetzter Hintergrund für Hinweise/Tipps.
  final bool dashedLook;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(radius);
    final background = gradient == null
        ? (color ??
            (dashedLook ? AppTheme.subtleColor(context) : AppTheme.cardColor(context)))
        : null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        boxShadow: shadow ? AppTheme.softShadow(context) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            gradient: gradient,
            borderRadius: r,
            border: Border.all(color: AppTheme.borderColor(context)),
          ),
          child: InkWell(
            borderRadius: r,
            onTap: onTap,
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}

/// Dezente Einblend-Animation (von unten einblenden).
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + index * 70),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// Abschnitts-Überschrift mit optionaler Aktion rechts.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.hint});

  final String title;
  final Widget? action;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleSmall)),
          if (hint != null)
            Text(hint!,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700)),
          if (action != null) action!,
        ],
      ),
    );
  }
}

/// Symbol in farbigem, abgerundetem Quadrat.
class IconBubble extends StatelessWidget {
  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(size * 0.33),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Symbol auf Farbverlauf (für hervorgehobene Aktionen).
class GradientBubble extends StatelessWidget {
  const GradientBubble({super.key, required this.icon, this.size = 56});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.brandGradient,
        borderRadius: BorderRadius.circular(size * 0.34),
        boxShadow: [
          BoxShadow(
            color: AppTheme.violet.withValues(alpha: 0.4),
            blurRadius: size * 0.4,
            offset: Offset(0, size * 0.16),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.46),
    );
  }
}

/// Schmaler Fortschrittsbalken im Markenverlauf.
class GradientMeter extends StatelessWidget {
  const GradientMeter({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
    this.background,
  });

  final double value;
  final double height;
  final Color? color;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: background ?? AppTheme.violet.withValues(alpha: 0.12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 750),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v == 0 ? 0.001 : v,
              child: Container(
                decoration: BoxDecoration(
                  gradient: color == null ? AppTheme.brandGradient : null,
                  color: color,
                  borderRadius: BorderRadius.circular(height),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Kennzahl-Karte für die Statistik.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBubble(icon: icon, color: color, size: 38),
          const SizedBox(height: 12),
          Text(value, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Gesperrte Pro-Funktion.
class ProLockedCard extends StatelessWidget {
  const ProLockedCard({
    super.key,
    required this.title,
    required this.description,
    required this.onUpgrade,
  });

  final String title;
  final String description;
  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onUpgrade,
      dashedLook: true,
      child: Row(
        children: [
          const IconBubble(icon: Icons.lock_rounded, color: AppTheme.amber),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(child: Text(title, style: theme.textTheme.titleSmall)),
                    const SizedBox(width: 8),
                    const ProBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(description,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class ProBadge extends StatelessWidget {
  const ProBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppTheme.sunGradient,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'PLUS',
        style: TextStyle(
          color: Color(0xFF3A2200),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Kleiner farbiger Chip (Fach, Ergebnis, …).
class SoftChip extends StatelessWidget {
  const SoftChip({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
          ],
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
        ],
      ),
    );
  }
}

/// Ladeanzeige „KI denkt nach …“
class ThinkingIndicator extends StatelessWidget {
  const ThinkingIndicator({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 54,
            height: 54,
            child: CircularProgressIndicator(strokeWidth: 5, strokeCap: StrokeCap.round),
          ),
          const SizedBox(height: 22),
          Text(message, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Demo-KI rechnet …',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

/// Wird angezeigt, wenn das Tageslimit erreicht ist.
class LimitReachedView extends StatelessWidget {
  const LimitReachedView({super.key, required this.onUpgrade});

  final VoidCallback onUpgrade;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBubble(
                icon: Icons.hourglass_bottom_rounded,
                color: AppTheme.amber,
                size: 84),
            const SizedBox(height: 22),
            Text('Für heute ist Schluss', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Du hast alle Hilfen von heute benutzt. Morgen bin ich wieder '
              'da – oder du holst dir Plus.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 26),
            FilledButton.icon(
              onPressed: onUpgrade,
              icon: const Icon(Icons.workspace_premium_rounded),
              label: const Text('Plus ansehen'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Antwort-Kachel mit Buchstabe und Wort.
class AnswerTile extends StatelessWidget {
  const AnswerTile({
    super.key,
    required this.label,
    required this.letter,
    required this.correct,
    required this.wrong,
    required this.dim,
    required this.onTap,
  });

  final String label;
  final String letter;
  final bool correct;
  final bool wrong;
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = correct
        ? AppTheme.leaf
        : wrong
            ? AppTheme.coral
            : null;
    final border = accent ?? AppTheme.borderColor(context);
    final fill = accent == null
        ? AppTheme.cardColor(context)
        : accent.withValues(alpha: 0.14);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dim ? 0.45 : 1,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border, width: accent == null ? 2 : 2.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 15, 16, 15),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent ?? AppTheme.violet.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    letter,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: accent == null ? AppTheme.violet : Colors.white),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(label, style: theme.textTheme.bodyLarge),
                ),
                if (correct)
                  const Icon(Icons.check_circle_rounded, color: AppTheme.leaf),
                if (wrong)
                  const Icon(Icons.cancel_rounded, color: AppTheme.coral),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
