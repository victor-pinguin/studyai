import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/sounds.dart';
import '../core/utils.dart';
import '../models/quiz.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/rewards.dart';
import '../widgets/snappy.dart';

/// Einmaleins-Trainer: die Reihen 1 bis 9 üben.
///
/// Braucht KEINE KI – die Aufgaben werden im Gerät gerechnet.
/// Deshalb zählt dieser Trainer auch nicht gegen das Tageslimit.
class TimesTableScreen extends StatefulWidget {
  const TimesTableScreen({super.key});

  @override
  State<TimesTableScreen> createState() => _TimesTableScreenState();
}

enum _Phase { pick, play, done }

/// Eine Einmaleins-Frage.
class TimesQuestion {
  const TimesQuestion({
    required this.a,
    required this.b,
    required this.options,
    required this.correctIndex,
  });

  final int a;
  final int b;
  final List<int> options;
  final int correctIndex;

  int get result => a * b;
  String get text => '$a · $b = ?';
  String get explanation =>
      '$a · $b heißt: $b mal die $a zusammenzählen. Das sind ${a * b}.';
}

/// Erzeugt [count] Aufgaben. [row] = 0 bedeutet „gemischt (1–9)“.
List<TimesQuestion> buildTimesQuestions(int row, int count, {Random? random}) {
  final rnd = random ?? Random();
  final questions = <TimesQuestion>[];
  final used = <String>{};
  final maxUnique = row == 0 ? 81 : 9;

  while (questions.length < count) {
    final a = row == 0 ? rnd.nextInt(9) + 1 : row;
    final b = rnd.nextInt(9) + 1;
    final key = '${a}x$b';
    if (used.contains(key) && used.length < maxUnique) continue;
    used.add(key);

    final correct = a * b;
    final options = <int>{correct};
    for (final candidate in [
      correct + a,
      correct - a,
      correct + b,
      correct - b,
      correct + 1,
      correct - 1,
      a * (b + 1),
    ]) {
      if (options.length >= 4) break;
      if (candidate > 0 && candidate != correct) options.add(candidate);
    }
    var extra = 2;
    while (options.length < 4) {
      options.add(correct + extra++);
    }
    final list = options.toList()..shuffle(rnd);
    questions.add(TimesQuestion(
      a: a,
      b: b,
      options: list,
      correctIndex: list.indexOf(correct),
    ));
  }
  return questions;
}

class _TimesTableScreenState extends State<TimesTableScreen> {
  static const _questionCount = 10;

  _Phase _phase = _Phase.pick;
  int _row = 0;
  List<TimesQuestion> _questions = [];
  int _index = 0;
  int? _selected;
  int _correct = 0;
  Reward? _reward;
  int _wrongCount = 0;
  int _rightCount = 0;

  void _startRow(int row) {
    setState(() {
      _row = row;
      _questions = buildTimesQuestions(row, _questionCount);
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
      taskTitle:
          _row == 0 ? 'Einmaleins gemischt' : 'Einmaleins: ${_row}er-Reihe',
      subject: Subject.math,
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
          _Phase.pick => 'Einmaleins',
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
  // 1) Reihe wählen
  // ---------------------------------------------------------------------------

  Widget _buildPick(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        const SnappyBubble(
          text: 'Welche Reihe möchtest du üben? Hier gibt es kein Limit – '
              'du kannst so oft üben, wie du willst!',
          size: 70,
        ),
        const SectionHeader('Wähle eine Reihe'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
          children: [
            for (var n = 1; n <= 9; n++)
              _RowTile(number: n, onTap: () => _startRow(n)),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _startRow(0),
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Alles gemischt (1–9)'),
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
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Center(
            child: Text(q.text, style: AppTheme.mono(context, size: 34)),
          ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.1,
          children: [
            for (var i = 0; i < q.options.length; i++)
              _AnswerTile(
                value: q.options[i],
                correct: answered && i == q.correctIndex,
                wrong: answered && i == _selected && !isCorrect,
                dim: answered && i != q.correctIndex && i != _selected,
                onTap: answered ? null : () => _answer(i),
              ),
          ],
        ),
        if (answered) ...[
          const SizedBox(height: 18),
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
      3 => 'Einmaleins-Profi!',
      2 => 'Stark!',
      1 => 'Gut gemacht!',
      _ => 'Weiter üben!',
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      children: [
        Center(
          child: Snappy(
              size: 120,
              mood: stars >= 1 ? SnappyMood.happy : SnappyMood.sad),
        ),
        const SizedBox(height: 18),
        StarRow(filled: stars),
        const SizedBox(height: 22),
        Text(title,
            textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '$_correct von $total richtig'
          '${_row == 0 ? '' : ' in der ${_row}er-Reihe'}',
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
          onPressed: () => _startRow(_row),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Nochmal üben'),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => setState(() => _phase = _Phase.pick),
          child: const Text('Andere Reihe'),
        ),
      ],
    );
  }
}

/// Kachel für eine Reihe (1 bis 9).
class _RowTile extends StatelessWidget {
  const _RowTile({required this.number, required this.onTap});

  final int number;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              gradient: AppTheme.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Text('$number',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.white)),
          ),
          const SizedBox(height: 8),
          Text('${number}er-Reihe',
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Antwort-Kachel mit großer Zahl.
class _AnswerTile extends StatelessWidget {
  const _AnswerTile({
    required this.value,
    required this.correct,
    required this.wrong,
    required this.dim,
    required this.onTap,
  });

  final int value;
  final bool correct;
  final bool wrong;
  final bool dim;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = correct
        ? AppTheme.leaf
        : wrong
            ? AppTheme.coral
            : AppTheme.borderColor(context);
    final fill = correct
        ? AppTheme.leaf.withValues(alpha: 0.14)
        : wrong
            ? AppTheme.coral.withValues(alpha: 0.14)
            : AppTheme.cardColor(context);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: dim ? 0.45 : 1,
      child: Material(
        color: fill,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: border, width: correct || wrong ? 2.5 : 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text('$value', style: AppTheme.mono(context, size: 26)),
          ),
        ),
      ),
    );
  }
}
