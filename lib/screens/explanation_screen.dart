import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/explanation.dart';
import '../services/ai/ai_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/snappy.dart';
import 'pro_screen.dart';
import 'quiz_screen.dart';

/// KI-Erklärung: Schritte werden nacheinander aufgedeckt,
/// die Lösung erst ganz am Ende auf Wunsch.
class ExplanationScreen extends StatefulWidget {
  const ExplanationScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<ExplanationScreen> createState() => _ExplanationScreenState();
}

class _ExplanationScreenState extends State<ExplanationScreen> {
  Explanation? _explanation;
  String? _error;
  bool _limitReached = false;
  int _visibleSteps = 1;
  bool _showSolution = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final app = context.read<AppState>();
    final ai = context.read<AiService>();
    final task = app.taskById(widget.taskId);

    if (task == null) {
      setState(() => _error = 'Aufgabe nicht gefunden.');
      return;
    }
    if (!app.tryUseAiRequest()) {
      setState(() => _limitReached = true);
      return;
    }
    setState(() {
      _error = null;
      _explanation = null;
      _visibleSteps = 1;
      _showSolution = false;
    });

    try {
      final result =
          await ai.explain(task.text, detailed: app.limits.detailedExplanations);
      if (!mounted) return;
      setState(() => _explanation = result);
      await app.markExplained(task.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'Die Erklärung konnte nicht geladen werden. Prüfe deine Internetverbindung.');
    }
  }

  void _openPro() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ProScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Schritt für Schritt')),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_limitReached) return LimitReachedView(onUpgrade: _openPro);

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.coral),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              FilledButton(onPressed: _load, child: const Text('Erneut versuchen')),
            ],
          ),
        ),
      );
    }

    final exp = _explanation;
    if (exp == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Snappy(size: 120, mood: SnappyMood.wow),
            const SizedBox(height: 18),
            Text('Ich schau mir das an!',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text('Ich denke kurz nach …',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 20),
            const SizedBox(
                width: 46,
                height: 46,
                child: CircularProgressIndicator(strokeWidth: 5)),
          ],
        ),
      );
    }

    final app = context.watch<AppState>();
    final theme = Theme.of(context);
    final visible = _visibleSteps.clamp(1, exp.steps.length);
    final allShown = visible >= exp.steps.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
      children: [
        // Worum geht es?
        FadeSlideIn(
          child: AppCard(
            radius: 26,
            color: AppTheme.violet.withValues(alpha: 0.07),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconBubble(icon: exp.subject.icon, color: exp.subject.color),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(exp.subject.label.toUpperCase(),
                              style: TextStyle(
                                  color: exp.subject.color,
                                  fontSize: 12,
                                  letterSpacing: .8,
                                  fontWeight: FontWeight.w800)),
                          if (exp.isDemo) ...[
                            const SizedBox(width: 8),
                            Text('· Demo-KI',
                                style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant)),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(exp.summary, style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SectionHeader('So geht’s',
            hint: 'Schritt $visible von ${exp.steps.length}'),

        for (var i = 0; i < visible; i++)
          _StepItem(
            key: ValueKey('step$i'),
            number: i + 1,
            step: exp.steps[i],
            isLast: i == visible - 1,
          ),

        const SizedBox(height: 6),
        if (!allShown) ...[
          FilledButton.icon(
            onPressed: () => setState(() => _visibleSteps++),
            icon: const Icon(Icons.arrow_downward_rounded),
            label: const Text('Nächster Schritt'),
          ),
          TextButton(
            onPressed: () => setState(() => _visibleSteps = exp.steps.length),
            child: const Text('Alle Schritte zeigen'),
          ),
        ] else ...[
          if (exp.solution != null)
            _showSolution
                ? FadeSlideIn(child: _SolutionCard(text: exp.solution!))
                : Column(
                    children: [
                      Text('Probier es erst selbst – dann schauen wir zusammen!',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => _showSolution = true),
                        icon: const Icon(Icons.visibility_rounded),
                        label: const Text('Lösung zeigen'),
                      ),
                    ],
                  ),
          const SizedBox(height: 16),

          AppCard(
            dashedLook: true,
            radius: 22,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: AppTheme.violet),
                const SizedBox(width: 12),
                Expanded(child: Text(exp.tip, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (!app.limits.detailedExplanations) ...[
            ProLockedCard(
              title: 'Noch mehr erklären',
              description: 'Snappy verrät dir bei jedem Schritt das „Warum“.',
              onUpgrade: _openPro,
            ),
            const SizedBox(height: 16),
          ],

          FilledButton.icon(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => QuizScreen(taskId: widget.taskId)),
            ),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Üben und Sterne holen'),
          ),
        ],
      ],
    );
  }
}

/// Ein Schritt als Punkt auf einer Zeitleiste.
class _StepItem extends StatefulWidget {
  const _StepItem({
    super.key,
    required this.number,
    required this.step,
    required this.isLast,
  });

  final int number;
  final ExplanationStep step;
  final bool isLast;

  @override
  State<_StepItem> createState() => _StepItemState();
}

class _StepItemState extends State<_StepItem> {
  bool _showDetail = false;

  /// Sieht die Zeile nach Formel aus? Dann Monospace.
  bool _isMath(String line) =>
      RegExp(r'[0-9]\s*[+\-−·:=*/]|^x\s|=').hasMatch(line);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detail = widget.step.detail;
    final lines = widget.step.content.split('\n');

    return FadeSlideIn(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: AppTheme.brandGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${widget.number}',
                      style: AppTheme.mono(context, size: 14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
                if (!widget.isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.borderColor(context),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: AppCard(
                  radius: 20,
                  padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.step.title, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      for (final line in lines)
                        if (_isMath(line))
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 11, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppTheme.subtleColor(context),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(line, style: AppTheme.mono(context)),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(line,
                                style: theme.textTheme.bodyLarge
                                    ?.copyWith(height: 1.45)),
                          ),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () =>
                              setState(() => _showDetail = !_showDetail),
                          icon: Icon(_showDetail
                              ? Icons.expand_less_rounded
                              : Icons.psychology_rounded),
                          label: Text(_showDetail ? 'Weniger' : 'Warum?'),
                        ),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 250),
                          crossFadeState: _showDetail
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          firstChild: const SizedBox(width: double.infinity),
                          secondChild: Text(detail,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.45)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  const _SolutionCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.successGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.mint.withValues(alpha: 0.4),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Lösung',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text,
                    style: AppTheme.mono(context, size: 24, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
