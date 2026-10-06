import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/sounds.dart';
import '../core/utils.dart';
import '../models/german.dart';
import '../models/quiz.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/rewards.dart';
import '../widgets/snappy.dart';

/// Deutsch-Trainer: Artikel (der/die/das) und richtige Schreibweise.
///
/// Braucht KEINE KI – zählt deshalb nicht gegen das Tageslimit.
class GermanScreen extends StatefulWidget {
  const GermanScreen({super.key});

  @override
  State<GermanScreen> createState() => _GermanScreenState();
}

enum _Phase { pick, play, done }

class _GermanScreenState extends State<GermanScreen> {
  static const _questionCount = 10;

  _Phase _phase = _Phase.pick;
  GermanTopic? _topic;
  List<GermanQuestion> _questions = [];
  int _index = 0;
  int? _selected;
  int _correct = 0;
  Reward? _reward;
  int _wrongCount = 0;
  int _rightCount = 0;

  void _startTopic(GermanTopic? topic) {
    setState(() {
      _topic = topic;
      _questions = buildGermanQuestions(topic, _questionCount);
      _index = 0;
      _selected = null;
      _correct = 0;
      _reward = null;
      _phase = _Phase.play;
    });
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
    setState(() => _phase = _Phase.done);
    final app = context.read<AppState>();
    final result = QuizResult(
      id: Utils.newId(),
      taskId: null,
      taskTitle: 'Deutsch: ${_topic?.label ?? 'gemischt'}',
      subject: Subject.language,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (_phase) {
          _Phase.pick => 'Deutsch',
          _Phase.play => 'Aufgabe ${_index + 1} von ${_questions.length}',
          _Phase.done => 'Dein Ergebnis',
        }),
      ),
      body: SafeArea(
        child: switch (_phase) {
          _Phase.pick => _buildPick(context),
          _Phase.play => _buildQuestion(context),
          _Phase.done => Stack(
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
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) Übung wählen
  // ---------------------------------------------------------------------------

  Widget _buildPick(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const SnappyBubble(
          text: 'Was üben wir? Artikel oder Rechtschreibung – '
              'beides geht so oft du willst, ganz ohne Limit.',
          size: 70,
        ),
        const SectionHeader('Wähle eine Übung'),
        for (final topic in GermanTopic.values) ...[
          _TopicCard(topic: topic, onTap: () => _startTopic(topic)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => _startTopic(null),
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Gemischt üben'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2) Aufgabe
  // ---------------------------------------------------------------------------

  Widget _buildQuestion(BuildContext context) {
    final theme = Theme.of(context);
    final q = _questions[_index];
    final answered = _selected != null;
    final isCorrect = _selected == q.correctIndex;
    final isLast = _index + 1 == _questions.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _questions.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i <= _index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  gradient: i <= _index ? AppTheme.brandGradient : null,
                  color: i <= _index ? null : AppTheme.borderColor(context),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
          ],
        ),
        const SizedBox(height: 18),
        Shake(
          trigger: _wrongCount,
          child: Pop(
            trigger: _rightCount,
            child: AppCard(
          radius: 30,
          shadow: true,
          padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
          child: Column(
            children: [
              Text(q.prompt,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(q.hint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < q.options.length; i++) ...[
          AnswerTile(
            label: q.options[i],
            letter: 'ABCD'[i],
            correct: answered && i == q.correctIndex,
            wrong: answered && i == _selected && !isCorrect,
            dim: answered && i != q.correctIndex && i != _selected,
            onTap: answered ? null : () => _answer(i),
          ),
          const SizedBox(height: 10),
        ],
        if (answered) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Snappy(
                  size: 58,
                  bounce: false,
                  mood: isCorrect ? SnappyMood.happy : SnappyMood.sad),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  radius: 22,
                  color: (isCorrect ? AppTheme.leaf : AppTheme.coral)
                      .withValues(alpha: 0.14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isCorrect ? 'Richtig!' : 'Fast!',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(q.explanation, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _next,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: Text(isLast ? 'Ergebnis ansehen' : 'Weiter'),
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
    final title = switch (stars) {
      3 => 'Deutsch-Profi!',
      2 => 'Stark!',
      1 => 'Gut gemacht!',
      _ => 'Weiter üben!',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        Center(
          child: Snappy(
              size: 120, mood: stars >= 1 ? SnappyMood.happy : SnappyMood.sad),
        ),
        const SizedBox(height: 18),
        StarRow(filled: stars),
        const SizedBox(height: 22),
        Text(title,
            textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '$_correct von $total richtig · ${_topic?.label ?? 'gemischt'}',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
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
          onPressed: () => _startTopic(_topic),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Nochmal üben'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() => _phase = _Phase.pick),
          child: const Text('Andere Übung'),
        ),
      ],
    );
  }
}

/// Große Karte für eine Übung.
class _TopicCard extends StatelessWidget {
  const _TopicCard({required this.topic, required this.onTap});

  final GermanTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      radius: 26,
      shadow: true,
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppTheme.brandGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(topic.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(topic.label, style: theme.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  topic == GermanTopic.articles
                      ? 'Welcher Artikel gehört zum Wort?'
                      : 'Finde die richtige Schreibweise',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_rounded,
              color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
