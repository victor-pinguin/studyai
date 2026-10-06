import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../core/sounds.dart';
import '../core/utils.dart';
import '../models/quiz.dart';
import '../models/reward.dart';
import '../models/subject.dart';
import '../models/vocab.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import '../widgets/effects.dart';
import '../widgets/rewards.dart';
import '../widgets/snappy.dart';

/// Italienisch-Trainer: Vokabeln nach Themen üben.
///
/// Braucht KEINE KI – die Wörter stecken in der App.
/// Deshalb zählt dieser Trainer auch nicht gegen das Tageslimit.
class VocabScreen extends StatefulWidget {
  const VocabScreen({super.key});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

enum _Phase { pick, play, done }

class _VocabScreenState extends State<VocabScreen> {
  static const _questionCount = 10;

  LearnLanguage get _language => context.read<AppState>().learnLanguage;

  _Phase _phase = _Phase.pick;
  VocabTopic? _topic;
  List<VocabQuestion> _questions = [];
  int _index = 0;
  int? _selected;
  int _correct = 0;
  Reward? _reward;
  int _wrongCount = 0;
  int _rightCount = 0;

  void _startTopic(VocabTopic? topic) {
    setState(() {
      _topic = topic;
      _questions =
          buildVocabQuestions(topic, _questionCount, language: _language);
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
      taskTitle: '${_language.label}: ${_topic?.label ?? 'alles gemischt'}',
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
          _Phase.pick => context.watch<AppState>().learnLanguage.label,
          _Phase.play => 'Wort ${_index + 1} von ${_questions.length}',
          _Phase.done => 'Dein Ergebnis',
        }),
      ),
      body: Stack(
        children: [
          // Hintergrundband in den Farben des Landes, dessen Sprache geübt wird
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: IgnorePointer(child: _FlagBackdrop()),
          ),
          SafeArea(
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1) Thema wählen
  // ---------------------------------------------------------------------------

  Widget _buildPick(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        SnappyBubble(
          text: '${context.watch<AppState>().learnLanguage.greeting} '
              'Welche Wörter möchtest du üben? '
              'Hier gibt es kein Limit – üben, so oft du willst!',
          size: 70,
        ),
        SectionHeader(
          'Wähle ein Thema',
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FlagStripes(language: context.watch<AppState>().learnLanguage),
              const SizedBox(width: 6),
              Text(context.watch<AppState>().learnLanguage.country,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w800)),
            ],
          ),
        ),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            for (final topic in VocabTopic.values)
              _TopicTile(topic: topic, onTap: () => _startTopic(topic)),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () => _startTopic(null),
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Alles gemischt'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 2) Wort
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FlagStripes(language: q.toForeign ? null : q.language),
                  const SizedBox(width: 6),
                  Text(q.toForeign ? 'Deutsch' : q.language.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded,
                      size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  FlagStripes(language: q.toForeign ? q.language : null),
                  const SizedBox(width: 6),
                  Text(q.toForeign ? q.language.label : 'Deutsch',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w800)),
                ],
              ),
              const SizedBox(height: 10),
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
                      Text(isCorrect ? 'Bravo!' : 'Fast!',
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
      3 => _language == LearnLanguage.italian ? 'Bravissimo!' : 'Perfekt!',
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
          '$_correct von $total richtig · ${_topic?.label ?? 'alles gemischt'}',
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
          child: const Text('Anderes Thema'),
        ),
      ],
    );
  }
}

/// Kleine Flagge aus drei Streifen. [language] = null bedeutet Deutschland.
class FlagStripes extends StatelessWidget {
  const FlagStripes({super.key, required this.language, this.width = 22});

  final LearnLanguage? language;
  final double width;

  static const _germanColors = [
    Color(0xFF000000),
    Color(0xFFDD0000),
    Color(0xFFFFCE00),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = language?.flagColors ?? _germanColors;
    final horizontal = language?.horizontal ?? true;
    final stripes = [for (final c in colors) Expanded(child: ColoredBox(color: c))];
    return Container(
      width: width,
      height: width * 2 / 3,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: language == LearnLanguage.english
          // Großbritannien hat Streifen wie Frankreich – also richtig zeichnen
          ? CustomPaint(painter: _UnionJackPainter())
          : horizontal
              ? Column(children: stripes)
              : Row(children: stripes),
    );
  }
}

/// Der Union Jack – gezeichnet, damit er nicht wie die Trikolore aussieht.
class _UnionJackPainter extends CustomPainter {
  static const _blue = Color(0xFF012169);
  static const _red = Color(0xFFC8102E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = _blue);

    void diagonals(Color color, double strokeWidth) {
      final p = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset.zero, Offset(w, h), p);
      canvas.drawLine(Offset(w, 0), Offset(0, h), p);
    }

    void cross(Color color, double strokeWidth) {
      final p = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(w / 2, 0), Offset(w / 2, h), p);
      canvas.drawLine(Offset(0, h / 2), Offset(w, h / 2), p);
    }

    diagonals(Colors.white, h * 0.22);
    diagonals(_red, h * 0.10);
    cross(Colors.white, h * 0.35);
    cross(_red, h * 0.20);
  }

  @override
  bool shouldRepaint(_UnionJackPainter oldDelegate) => false;
}

/// Das Farbband im Hintergrund – in den Farben des gewählten Landes.
class _FlagBackdrop extends StatelessWidget {
  const _FlagBackdrop();

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).scaffoldBackgroundColor;
    final language = context.watch<AppState>().learnLanguage;
    final c = language.flagColors;
    final band = language.horizontal
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, .33, .33, .66, .66, 1],
            colors: [
              c[0].withValues(alpha: .30),
              c[0].withValues(alpha: .30),
              c[1].withValues(alpha: .30),
              c[1].withValues(alpha: .30),
              c[2].withValues(alpha: .30),
              c[2].withValues(alpha: .30),
            ],
          )
        : LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            stops: const [0, .30, .30, .70, .70, 1],
            colors: [
              c[0].withValues(alpha: .30),
              c[0].withValues(alpha: .30),
              c[1].withValues(alpha: .18),
              c[1].withValues(alpha: .18),
              c[2].withValues(alpha: .30),
              c[2].withValues(alpha: .30),
            ],
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(decoration: BoxDecoration(gradient: band)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [bg.withValues(alpha: 0), bg],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kachel für ein Thema.
class _TopicTile extends StatelessWidget {
  const _TopicTile({required this.topic, required this.onTap});

  final VocabTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      radius: 24,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF35C77A), Color(0xFFFF7A59)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(topic.icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(topic.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
