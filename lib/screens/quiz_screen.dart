import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_config.dart';
import '../core/app_theme.dart';
import '../core/sounds.dart';
import '../core/utils.dart';
import '../models/quiz.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../services/ai/ai_service.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/rewards.dart';
import '../widgets/snappy.dart';
import 'pro_screen.dart';

enum _Phase { setup, loading, playing, finished, limit, error }

/// Quiz: Anzahl wählen → Fragen beantworten → Ergebnis.
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.taskId});

  final String taskId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  _Phase _phase = _Phase.setup;
  int _count = 5;
  List<QuizQuestion> _questions = [];
  int _index = 0;
  int? _selected;
  int _correct = 0;
  Reward? _reward;
  int _wrongCount = 0;
  int _rightCount = 0;

  @override
  void initState() {
    super.initState();
    final max = context.read<AppState>().limits.maxQuizQuestions;
    if (_count > max) _count = max;
  }

  Future<void> _start() async {
    final app = context.read<AppState>();
    final ai = context.read<AiService>();
    final task = app.taskById(widget.taskId);
    if (task == null) {
      setState(() => _phase = _Phase.error);
      return;
    }
    if (!app.tryUseAiRequest()) {
      setState(() => _phase = _Phase.limit);
      return;
    }
    setState(() => _phase = _Phase.loading);
    try {
      final questions = await ai.createQuiz(task.text, count: _count);
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _index = 0;
        _selected = null;
        _correct = 0;
        _reward = null;
        _phase = questions.isEmpty ? _Phase.error : _Phase.playing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.error);
    }
  }

  void _answer(int i) {
    if (_selected != null) return;
    final right = i == _questions[_index].correctIndex;
    setState(() {
      _selected = i;
      if (right) {
        _correct++;
        _rightCount++;
      } else {
        _wrongCount++;
      }
    });
    right ? Sounds.instance.correct() : Sounds.instance.wrong();
  }

  Future<void> _next() async {
    if (_index + 1 < _questions.length) {
      setState(() {
        _index++;
        _selected = null;
      });
      return;
    }
    final app = context.read<AppState>();
    final task = app.taskById(widget.taskId);
    setState(() => _phase = _Phase.finished);
    final result = QuizResult(
      id: Utils.newId(),
      taskId: widget.taskId,
      taskTitle: task?.title ?? 'Quiz',
      subject: task?.subject ?? Subject.general,
      correct: _correct,
      total: _questions.length,
      date: DateTime.now(),
    );
    await app.addQuizResult(result);
    final reward = await app.grantReward(result.percent);
    if (result.percent >= 100) {
      Sounds.instance.perfect();
    } else if (result.percent >= 40) {
      Sounds.instance.win();
    }
    if (reward?.sticker != null) {
      Future.delayed(const Duration(milliseconds: 700), Sounds.instance.sticker);
    }
    if (!mounted) return;
    setState(() => _reward = reward);
  }

  void _openPro() => Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => const ProScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(_phase == _Phase.finished ? 'Ergebnis' : 'Quiz')),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: KeyedSubtree(
            key: ValueKey('$_phase-$_index'),
            child: switch (_phase) {
              _Phase.setup => _buildSetup(context),
              _Phase.loading =>
                const ThinkingIndicator(message: 'Ich baue dein Quiz!'),
              _Phase.playing => _buildQuestion(context),
              _Phase.finished => Stack(
                children: [
                  _buildResult(context),
                  if (_questions.isNotEmpty &&
                      _correct / _questions.length >= 0.4)
                    Positioned.fill(
                      child: Confetti(
                        pieces: _correct == _questions.length ? 70 : 34,
                      ),
                    ),
                ],
              ),
              _Phase.limit => LimitReachedView(onUpgrade: _openPro),
              _Phase.error => _buildError(),
            },
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) Einstellungen
  // ---------------------------------------------------------------------------

  Widget _buildSetup(BuildContext context) {
    final app = context.watch<AppState>();
    final task = app.taskById(widget.taskId);
    final theme = Theme.of(context);
    final max = app.limits.maxQuizQuestions;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 22),
          decoration: BoxDecoration(
            gradient: AppTheme.brandGradient,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppTheme.violet.withValues(alpha: 0.4),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            children: [
              const Snappy(size: 90, mood: SnappyMood.wow),
              const SizedBox(height: 12),
              Text('Bereit zum Üben?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(color: Colors.white)),
              const SizedBox(height: 6),
              Text(task?.title ?? '',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92), fontSize: 14)),
            ],
          ),
        ),
        SectionHeader('Wie viele Fragen?',
            hint: app.isPro ? 'Plus: bis 10' : 'Gratis: bis $max'),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var n = AppConfig.minQuizQuestions;
                n <= AppConfig.maxQuizQuestions;
                n++)
              _CountChip(
                number: n,
                locked: n > max,
                selected: _count == n,
                onTap: () {
                  if (n > max) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Mehr als $max Fragen gibt es mit Plus.'),
                      action: SnackBarAction(label: 'Plus', onPressed: _openPro),
                    ));
                    return;
                  }
                  setState(() => _count = n);
                },
              ),
          ],
        ),
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Los geht’s!'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2) Frage
  // ---------------------------------------------------------------------------

  Widget _buildQuestion(BuildContext context) {
    final q = _questions[_index];
    final theme = Theme.of(context);
    final answered = _selected != null;
    final isCorrect = _selected == q.correctIndex;
    final isLast = _index + 1 == _questions.length;
    final lines = q.question.split('\n');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        // Fortschrittspunkte
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _questions.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i <= _index ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  gradient: i <= _index ? AppTheme.brandGradient : null,
                  color: i <= _index ? null : AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Text('Frage ${_index + 1} von ${_questions.length}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Spacer(),
            const Icon(Icons.check_circle_rounded, size: 15, color: AppTheme.mint),
            const SizedBox(width: 5),
            Text('$_correct richtig',
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        const SizedBox(height: 14),
        AppCard(
          radius: 26,
          shadow: true,
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(lines.first, style: theme.textTheme.titleLarge),
              if (lines.length > 1) ...[
                const SizedBox(height: 8),
                Text(lines.skip(1).join('\n'),
                    style: AppTheme.mono(context, size: 19)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++)
          _OptionButton(
            letter: 'ABCD'[i.clamp(0, 3)],
            label: q.options[i],
            state: !answered
                ? _OptionState.idle
                : i == q.correctIndex
                    ? _OptionState.correct
                    : i == _selected
                        ? _OptionState.wrong
                        : _OptionState.disabled,
            onTap: () => _answer(i),
          ),
        if (answered) ...[
          const SizedBox(height: 6),
          FadeSlideIn(
            child: AppCard(
              radius: 22,
              color: (isCorrect ? AppTheme.mint : AppTheme.coral)
                  .withValues(alpha: 0.13),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: isCorrect ? AppTheme.mint : AppTheme.coral,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isCorrect ? 'Super gemacht!' : 'Fast!',
                            style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(q.explanation, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(isLast ? 'Ergebnis anzeigen' : 'Weiter'),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3) Ergebnis
  // ---------------------------------------------------------------------------

  Widget _buildResult(BuildContext context) {
    final theme = Theme.of(context);
    final total = _questions.length;
    final percent = total == 0 ? 0 : ((_correct / total) * 100).round();
    final stars = AppState.starsFor(percent);
    final (title, message) = switch (stars) {
      3 => ('Wow, fast alles richtig!', 'Du hast das Thema drauf.'),
      2 => ('Stark!', 'Nur noch ein bisschen üben – dann sitzt es.'),
      1 => ('Gut gemacht!', 'Schau dir die Erklärung nochmal an.'),
      _ => ('Weiter so!', 'Lass es dir noch einmal erklären – du schaffst das.'),
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
      children: [
        Center(child: Snappy(size: 120, mood: stars >= 1 ? SnappyMood.happy : SnappyMood.sad)),
        const SizedBox(height: 18),
        StarRow(filled: stars),
        const SizedBox(height: 22),
        Text(title, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text('$_correct von $total richtig',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (percent >= 100) ...[
          const SizedBox(height: 20),
          PerfectBanner(perfectCount: context.watch<AppState>().perfectCount),
        ],
        if (_reward != null) ...[
          const SizedBox(height: 20),
          RewardCard(reward: _reward!),
        ],
        const SizedBox(height: 28),
        FilledButton.icon(
          onPressed: () => setState(() => _phase = _Phase.setup),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Nochmal üben'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fertig'),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppTheme.coral),
            const SizedBox(height: 16),
            const Text('Das Quiz konnte nicht erstellt werden.',
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => setState(() => _phase = _Phase.setup),
              child: const Text('Zurück'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Auswahl der Fragenanzahl.
class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.number,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final int number;
  final bool locked;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? AppTheme.violet.withValues(alpha: 0.13) : Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 64,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.violet : AppTheme.borderColor(context),
              width: selected ? 2 : 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (locked) ...[
                Icon(Icons.lock_rounded,
                    size: 13, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
              ],
              Text('$number',
                  style: theme.textTheme.titleSmall?.copyWith(
                      color: selected
                          ? AppTheme.violet
                          : theme.colorScheme.onSurface)),
            ],
          ),
        ),
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, disabled }

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.letter,
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String letter;
  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color border, Color? fill, Color keyBg, Color keyFg, IconData? icon) =
        switch (state) {
      _OptionState.idle => (
          AppTheme.borderColor(context),
          null,
          AppTheme.violet.withValues(alpha: 0.13),
          AppTheme.violet,
          null
        ),
      _OptionState.disabled => (
          AppTheme.borderColor(context),
          null,
          AppTheme.violet.withValues(alpha: 0.13),
          AppTheme.violet,
          null
        ),
      _OptionState.correct => (
          AppTheme.mint,
          AppTheme.mint.withValues(alpha: 0.13),
          AppTheme.mint,
          Colors.white,
          Icons.check_circle_rounded
        ),
      _OptionState.wrong => (
          AppTheme.coral,
          AppTheme.coral.withValues(alpha: 0.13),
          AppTheme.coral,
          Colors.white,
          Icons.cancel_rounded
        ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: state == _OptionState.disabled ? 0.5 : 1,
        child: Material(
          color: fill ?? AppTheme.cardColor(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
                color: border, width: state == _OptionState.idle ? 1.5 : 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: state == _OptionState.idle ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: keyBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(letter,
                        style: AppTheme.mono(context, size: 13, color: keyFg)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Text(label,
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (icon != null) Icon(icon, color: border),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
