import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/snappy.dart';

/// Pro-Seite. In der Demo wird Pro ohne Bezahlung freigeschaltet.
/// Später: In-App-Kauf über App Store / Google Play (z. B. mit RevenueCat).
class ProScreen extends StatelessWidget {
  const ProScreen({super.key});

  static const _features = [
    (Icons.bolt_rounded, 'Mehr Hilfen', 'Bis zu 200 Erklärungen und Quizze am Tag'),
    (Icons.high_quality_rounded, 'Größere Bilder & Dokumente', 'Schärfere Fotos für bessere Erkennung – PDFs folgen'),
    (Icons.format_list_numbered_rounded, 'Mehr Quizfragen', 'Bis zu 10 Fragen pro Quiz'),
    (Icons.psychology_rounded, 'Snappy erklärt mehr', 'Bei jedem Schritt das „Warum“'),
    (Icons.star_rounded, 'Sternen-Überblick', 'Was klappt gut, was noch nicht'),
    (Icons.event_note_rounded, 'Dein Lernplan', 'Ein Plan für die ganze Woche'),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final text = Theme.of(context).textTheme;
    const free = PlanLimits.free;
    const pro = PlanLimits.pro;

    return Scaffold(
      appBar: AppBar(title: const Text('StudySnap Plus')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            // Kopfbereich
            FadeSlideIn(
              child: AppCard(
                gradient: AppTheme.proGradient,
                radius: 30,
                padding: const EdgeInsets.all(26),
                child: Column(
                  children: [
                    const Snappy(size: 92, mood: SnappyMood.wow),
                    const SizedBox(height: 12),
                    Text(
                      app.isPro ? 'Plus ist an!' : 'Noch mehr mit Plus',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mehr Hilfen, mehr Übung, eigener Lernplan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Funktionen
            for (var i = 0; i < _features.length; i++)
              FadeSlideIn(
                index: i,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        IconBubble(icon: _features[i].$1, color: AppTheme.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_features[i].$2,
                                  style: text.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              Text(_features[i].$3, style: text.bodySmall),
                            ],
                          ),
                        ),
                        if (app.isPro)
                          const Icon(Icons.check_circle_rounded,
                              color: AppTheme.success),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

            // Vergleich Free vs. Pro
            const SectionHeader('Gratis oder Plus?'),
            AppCard(
              child: Column(
                children: [
                  const _CompareRow('', 'Gratis', 'Plus', header: true),
                  _CompareRow('Hilfen am Tag', '${free.dailyAiRequests}',
                      '${pro.dailyAiRequests}'),
                  _CompareRow('Quizfragen', 'bis ${free.maxQuizQuestions}',
                      'bis ${pro.maxQuizQuestions}'),
                  _CompareRow('Bildgröße', '${free.maxImageDimension.round()} px',
                      '${pro.maxImageDimension.round()} px'),
                  const _CompareRow('Erklärungen', 'normal', 'ausführlich'),
                  const _CompareRow('Sternen-Überblick', '–', '✓'),
                  const _CompareRow('Lernpläne', '–', '✓'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (!app.isPro) ...[
              FilledButton.icon(
                onPressed: () {
                  app.setPro(true);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Demo: Plus ist an – es kostet nichts.'),
                  ));
                },
                icon: const Icon(Icons.workspace_premium_rounded),
                label: const Text('Plus testen (Demo, kostenlos)'),
              ),
              const SizedBox(height: 10),
              Text(
                'Hier wird nichts bezahlt. Später läuft der Kauf über App Store '
                'oder Google Play – und Eltern müssen zustimmen.',
                textAlign: TextAlign.center,
                style: text.bodySmall,
              ),
            ] else
              OutlinedButton(
                onPressed: () => app.setPro(false),
                child: const Text('Zurück zu Gratis'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow(this.label, this.free, this.pro, {this.header = false});

  final String label;
  final String free;
  final String pro;
  final bool header;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: header ? FontWeight.w800 : FontWeight.w500,
      fontSize: header ? 15 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text(label, style: style)),
          Expanded(
            flex: 3,
            child: Text(free, textAlign: TextAlign.center, style: style),
          ),
          Expanded(
            flex: 3,
            child: Text(
              pro,
              textAlign: TextAlign.center,
              style: style.copyWith(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}
