import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/reward.dart';
import '../state/app_state.dart';

/// Farben der beiden Belohnungsstufen.
class _TierStyle {
  const _TierStyle(this.gradient, this.ink);
  final LinearGradient gradient;
  final Color ink;

  static const gold = _TierStyle(AppTheme.sunGradient, Color(0xFF3A2200));
  static const silver = _TierStyle(
    LinearGradient(
      colors: [Color(0xFFEDF1FB), Color(0xFFB9C5E2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    Color(0xFF1B2559),
  );

  static _TierStyle of(RewardTier tier) =>
      tier == RewardTier.gold ? gold : silver;
}

/// Die große Karte direkt nach einem sehr guten Quiz.
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward});

  final Reward reward;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _TierStyle.of(reward.tier);
    final sticker = reward.sticker;
    final stars =
        '${reward.bonusStars} ${reward.bonusStars == 1 ? 'Stern' : 'Sterne'}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.7, end: 1),
      duration: const Duration(milliseconds: 550),
      curve: Curves.elasticOut,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
        decoration: BoxDecoration(
          gradient: style.gradient,
          borderRadius: BorderRadius.circular(28),
          boxShadow: AppTheme.softShadow(context),
        ),
        child: Column(
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                sticker?.icon ?? Icons.workspace_premium_rounded,
                size: 42,
                color: style.ink,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              reward.tier == RewardTier.gold
                  ? 'Alles richtig – Gold-Sticker!'
                  : 'Stark – Silber-Sticker!',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(color: style.ink),
            ),
            const SizedBox(height: 6),
            Text(
              sticker != null
                  ? 'Neu in deiner Sammlung: ${sticker.name} · +$stars'
                  : 'Du hast schon alle Sticker! +$stars',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: style.ink, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Die Übungs-Flamme: Tage in Folge, Wochenpunkte und nächster Meilenstein.
class StreakCard extends StatelessWidget {
  const StreakCard({super.key});

  static const _weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final days = app.streakDays;
    final next = app.nextStreakMilestone;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A3D), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.local_fire_department_rounded,
                    size: 36, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$days ${days == 1 ? 'Tag' : 'Tage'} in Folge',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(color: Colors.white),
                    ),
                    Text(
                      'Deine Flamme: ${app.streakLabel}'
                      '${app.bestStreakDays > days ? ' · Rekord: ${app.bestStreakDays}' : ''}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .95),
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 6; i >= 0; i--)
                _DayDot(
                  label: _weekdays[
                      today.subtract(Duration(days: i)).weekday - 1],
                  active: app.wasActiveOn(today.subtract(Duration(days: i))),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            next == null
                ? 'Alle Meilensteine geschafft – du bist eine Lern-Legende!'
                : 'Noch ${next - days} ${next - days == 1 ? 'Tag' : 'Tage'} bis zum $next-Tage-Meilenstein. Jeden Tag üben hält die Flamme am Leben!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .95),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  const _DayDot({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: .22),
            shape: BoxShape.circle,
          ),
          child: Icon(
            active
                ? Icons.local_fire_department_rounded
                : Icons.circle_outlined,
            size: 17,
            color: active ? const Color(0xFFFF6B3D) : Colors.white70,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: active ? 1 : .8),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Die Sammlung aller Sticker – freigeschaltete sind bunt, die anderen grau.
class StickerCollection extends StatelessWidget {
  const StickerCollection({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.rCard),
        border: Border.all(color: AppTheme.borderColor(context), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              for (final s in Sticker.all)
                _StickerTile(sticker: s, earned: app.earnedSticker(s.id)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Alle Fragen richtig → Gold-Sticker und 2 Extra-Sterne. '
            'Ab 80 % richtig → Silber-Sticker und 1 Extra-Stern.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  const _StickerTile({required this.sticker, required this.earned});

  final Sticker sticker;
  final EarnedSticker? earned;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tier = earned?.tier;
    final style = tier == null ? null : _TierStyle.of(tier);
    final ink = style?.ink ?? theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: style?.gradient,
        color: style == null ? AppTheme.subtleColor(context) : null,
        borderRadius: BorderRadius.circular(22),
        border: style == null
            ? Border.all(color: AppTheme.borderColor(context), width: 2)
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(sticker.icon, size: 26, color: ink),
          const SizedBox(height: 4),
          Text(
            earned != null ? sticker.name : '?',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: ink, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

/// Der große Moment: alles richtig.
///
/// Erscheint nur bei 100 % – mit Krone, Glanz und Zähler der perfekten Runden.
class PerfectBanner extends StatelessWidget {
  const PerfectBanner({super.key, required this.perfectCount});

  /// Die wievielte perfekte Runde das ist.
  final int perfectCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: 0.6 + 0.4 * value,
        child: Transform.rotate(angle: (1 - value) * -0.12, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD84D), Color(0xFFFF9A3D), Color(0xFFFF7AB6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sun.withValues(alpha: .45),
              blurRadius: 34,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            _Crown(),
            const SizedBox(height: 12),
            Text(
              'PERFEKT!',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF3A2200),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Alles richtig – kein einziger Fehler!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF3A2200),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                perfectCount == 1
                    ? 'Deine erste perfekte Runde'
                    : '$perfectCount× alles richtig geschafft',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF3A2200),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Krone, die leicht schwebt.
class _Crown extends StatefulWidget {
  @override
  State<_Crown> createState() => _CrownState();
}

class _CrownState extends State<_Crown> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, -4 * Curves.easeInOut.transform(_c.value)),
        child: child,
      ),
      child: Container(
        width: 84,
        height: 84,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .6),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.emoji_events_rounded,
            size: 48, color: Color(0xFF3A2200)),
      ),
    );
  }
}
