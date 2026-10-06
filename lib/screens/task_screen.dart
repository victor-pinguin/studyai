import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_theme.dart';
import '../models/study_task.dart';
import '../models/subject.dart';
import '../state/app_state.dart';
import '../widgets/common.dart';
import 'explanation_screen.dart';
import 'quiz_screen.dart';

/// Zeigt die erkannte Aufgabe. Der Text kann korrigiert werden.
/// Von hier aus: „Erklären“ oder „Quiz erstellen“.
class TaskScreen extends StatefulWidget {
  const TaskScreen({
    super.key,
    required this.initialText,
    this.task,
    this.imageBytes,
    this.hint,
  });

  /// Bereits gespeicherte Aufgabe (aus dem Verlauf) – sonst null.
  final StudyTask? task;
  final String initialText;
  final Uint8List? imageBytes;

  /// Hinweis, z. B. wenn kein Text erkannt wurde.
  final String? hint;

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late final TextEditingController _controller;
  String? _taskId;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _taskId = widget.task?.id;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Speichert die Aufgabe beim ersten Erklären/Quiz im Verlauf.
  Future<String> _ensureSaved() async {
    final app = context.read<AppState>();
    final text = _controller.text.trim();
    final id = _taskId;
    if (id == null) {
      final task = await app.addTask(text);
      if (mounted) setState(() => _taskId = task.id);
      return task.id;
    }
    if (app.taskById(id)?.text != text) {
      await app.updateTaskText(id, text);
    }
    return id;
  }

  Future<void> _explain() async {
    FocusScope.of(context).unfocus();
    final id = await _ensureSaved();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ExplanationScreen(taskId: id),
    ));
  }

  Future<void> _quiz() async {
    FocusScope.of(context).unfocus();
    final id = await _ensureSaved();
    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => QuizScreen(taskId: id),
    ));
  }

  Future<void> _delete() async {
    final id = _taskId;
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aufgabe löschen?'),
        content: const Text('Die Aufgabe wird aus deinem Verlauf entfernt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppState>().deleteTask(id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deine Aufgabe'),
        actions: [
          if (_taskId != null)
            IconButton(
              tooltip: 'Löschen',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  if (widget.imageBytes != null)
                    FadeSlideIn(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.memory(
                          widget.imageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  if (widget.hint != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      color: AppTheme.warning.withValues(alpha: 0.12),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded,
                              color: AppTheme.warning),
                          const SizedBox(width: 12),
                          Expanded(child: Text(widget.hint!)),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // Überschrift + automatisch erkanntes Fach
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) {
                      final subject = Subject.detect(value.text);
                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.imageBytes != null
                                  ? 'Erkannte Aufgabe'
                                  : 'Aufgabe',
                              style: text.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          if (value.text.trim().isNotEmpty)
                            Chip(
                              avatar: Icon(subject.icon,
                                  size: 18, color: subject.color),
                              label: Text(subject.label),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _controller,
                    minLines: 4,
                    maxLines: 12,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText:
                          'Tippe hier deine Aufgabe ein, z. B. „2x + 3 = 11“',
                      filled: true,
                      fillColor: AppTheme.cardColor(context),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: AppTheme.borderColor(context)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tipp: Korrigiere Erkennungsfehler, bevor du auf „Erklären“ tippst.',
                    style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Aktionen unten
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, _) {
                final enabled = value.text.trim().isNotEmpty;
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    children: [
                      FilledButton.icon(
                        onPressed: enabled ? _explain : null,
                        icon: const Icon(Icons.lightbulb_rounded),
                        label: const Text('Erklären'),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: enabled ? _quiz : null,
                        icon: const Icon(Icons.quiz_rounded),
                        label: const Text('Quiz erstellen'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
