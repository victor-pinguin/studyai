import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/utils.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/rewards.dart';
import '../widgets/snappy.dart';
import 'pro_screen.dart';

/// Fortschritt: Level, Kennzahlen, Wochenaktivität, Quiz-Ergebnisse.
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    void openPro() => Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const ProScreen()));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
          children: [
            Text('Deine Sterne', style: text.headlineMedium),
            const SizedBox(height: 16),

            // Level-Karte
            FadeSlideIn(
              child: AppCard(
                gradient: AppTheme.brandGradient,
                radius: 28,
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Snappy(size: 64),
                        const SizedBox(width: 12),
                        Text('Level ${app.starLevel}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800)),
                        const Spacer(),
                        Text('${app.starCount} ⭐',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: app.starsInLevel / 5),
                        duration: const Duration(milliseconds: 900),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          color: Colors.white,
                          backgroundColor: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Noch ${5 - app.starsInLevel} ${5 - app.starsInLevel == 1 ? 'Stern' : 'Sterne'} bis Level ${app.starLevel + 1}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Übungs-Flamme
            const FadeSlideIn(child: StreakCard()),
            const SizedBox(height: 16),

            // Kennzahlen
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.task_alt_rounded,
                    label: 'Aufgaben verstanden',
                    value: '${app.solvedCount}',
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.quiz_rounded,
                    label: 'Quizze gemacht',
                    value: '${app.quizCount}',
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    icon: Icons.percent_rounded,
                    label: 'Ø richtig',
                    value: app.quizCount == 0 ? '–' : '${app.averageQuizPercent} %',
                    color: AppTheme.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StatCard(
                    icon: Icons.local_fire_department_rounded,
                    label: 'Tage in Folge',
                    value: '${app.streakDays}',
                    color: AppTheme.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Wochenaktivität
            const SectionHeader('Deine Woche'),
            AppCard(child: _WeekChart(data: app.activityLast7Days)),
            const SizedBox(height: 20),

            // Letzte Quiz-Ergebnisse
            SectionHeader('Deine Sticker',
                hint: '${app.rewards.length} von ${Sticker.all.length}'),
            const StickerCollection(),
            const SectionHeader('Letzte Quizze'),
            if (app.quizResults.isEmpty)
              AppCard(
                child: Text('Noch kein Quiz gemacht. Starte eins bei einer Aufgabe!',
                    style: TextStyle(color: muted)),
              )
            else
              for (final r in app.quizResults.take(5))
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconBubble(icon: r.subject.icon, color: r.subject.color, size: 40),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.taskTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.titleSmall),
                              Text('${r.correct}/${r.total} richtig · ${Utils.relativeDate(r.date)}',
                                  style: text.bodySmall?.copyWith(color: muted)),
                            ],
                          ),
                        ),
                        Text('${r.percent} %',
                            style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: r.percent >= 70
                                    ? AppTheme.success
                                    : AppTheme.warning)),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 20),

            // Pro: Statistik nach Fach
            const SectionHeader('Das kannst du schon'),
            if (app.limits.advancedStats)
              _SubjectStats(data: app.averagePercentBySubject)
            else
              ProLockedCard(
                title: 'Wo bist du stark?',
                description: 'Snappy zeigt dir, welche Fächer schon gut klappen.',
                onUpgrade: openPro,
              ),
            const SizedBox(height: 20),

            // Pro: Lernplan
            const SectionHeader('Dein Lernplan'),
            if (app.limits.learningPlans)
              AppCard(
                child: Column(
                  children: [
                    for (final item in app.learningPlan)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.event_available_rounded,
                                color: AppTheme.primary, size: 20),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                  ],
                ),
              )
            else
              ProLockedCard(
                title: 'Dein Lernplan',
                description: 'Snappy plant deine Woche – passend zu deinen Sternen.',
                onUpgrade: openPro,
              ),
          ],
        ),
      ),
    );
  }
}

/// Einfaches Balkendiagramm ohne Zusatzpaket.
class _WeekChart extends StatelessWidget {
  const _WeekChart({required this.data});

  final List<(DateTime, int)> data;

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(1, (m, e) => e.$2 > m ? e.$2 : m);
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    const barMaxHeight = 110.0;

    return SizedBox(
      height: barMaxHeight + 48,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final (day, count) in data)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(count > 0 ? '$count' : '',
                      style: TextStyle(fontSize: 12, color: muted)),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: count / maxValue),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => Container(
                      width: 22,
                      height: 6 + (barMaxHeight - 6) * value,
                      decoration: BoxDecoration(
                        gradient: count > 0 ? AppTheme.brandGradient : null,
                        color: count > 0 ? null : muted.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(Utils.weekdayShort(day),
                      style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Durchschnitt pro Fach als Balken (Pro).
class _SubjectStats extends StatelessWidget {
  const _SubjectStats({required this.data});

  final Map<Subject, int> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const AppCard(
        child: Text('Mach ein paar Quizze – dann siehst du hier deine Stärken.'),
      );
    }
    return AppCard(
      child: Column(
        children: [
          for (final entry in data.entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(entry.key.icon, color: entry.key.color),
                  const SizedBox(width: 10),
                  SizedBox(width: 110, child: Text(entry.key.label)),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: entry.value / 100,
                        minHeight: 10,
                        color: entry.key.color,
                        backgroundColor:
                            entry.key.color.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('${entry.value} %'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
