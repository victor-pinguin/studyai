import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/utils.dart';
import '../models/study_task.dart';
import 'common.dart';

/// Listeneintrag für „Meine letzten Aufgaben“ – mit farbigem Fach-Streifen.
class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task, required this.onTap});

  final StudyTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final color = task.subject.color;
    final radius = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.cardColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: AppTheme.borderColor(context)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(width: 4, height: 68, color: color),
              const SizedBox(width: 11),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: IconBubble(icon: task.subject.icon, color: color, size: 40),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${task.subject.label} · ${Utils.relativeDate(task.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (task.bestQuizPercent != null)
                SoftChip(
                  label: '${task.bestQuizPercent} %',
                  color: task.bestQuizPercent! >= 70 ? AppTheme.mint : AppTheme.amber,
                )
              else if (task.explained)
                const Icon(Icons.check_circle_rounded, color: AppTheme.mint)
              else
                Icon(Icons.arrow_forward_rounded, size: 20, color: muted),
              const SizedBox(width: 15),
            ],
          ),
        ),
      ),
    );
  }
}
