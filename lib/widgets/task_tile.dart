import 'package:flutter/material.dart';

import '../models/cleaning_task.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    required this.task,
    required this.onToggle,
    required this.onDelete,
    this.onPostpone,
    this.onRestore,
    super.key,
  });

  final CleaningTask task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback? onPostpone;
  final VoidCallback? onRestore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: task.isPostponed ? onRestore : onToggle,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: task.isPostponed
                ? Theme.of(context).colorScheme.surfaceContainerHigh
                : task.isDone
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.surfaceContainerLow,
            shape: BoxShape.circle,
          ),
          child: Icon(
            task.isPostponed
                ? Icons.schedule_rounded
                : task.isDone
                    ? Icons.check_rounded
                    : Icons.cleaning_services_outlined,
            color: task.isPostponed
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : task.isDone
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          task.isPostponed
              ? '${task.zoneName} · ${task.postponedLabel}'
              : '${task.zoneName} · ${task.estimatedMinutes}분'
                  '${task.isRecurring ? ' · 주기 청소' : ''}',
        ),
        trailing: task.isPostponed
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: onRestore,
                    child: const Text('되돌리기'),
                  ),
                  _TaskIconButton(
                    tooltip: '삭제',
                    onPressed: onDelete,
                    icon: Icons.delete_outline,
                  ),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (task.isRecurring && !task.isDone)
                    _TaskIconButton(
                      onPressed: onPostpone,
                      tooltip: '미루기',
                      icon: Icons.schedule_send_outlined,
                    ),
                  _TaskIconButton(
                    tooltip: '삭제',
                    onPressed: onDelete,
                    icon: Icons.delete_outline,
                  ),
                  Checkbox(
                    value: task.isDone,
                    onChanged: (_) => onToggle(),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
      ),
    );
  }
}

class _TaskIconButton extends StatelessWidget {
  const _TaskIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}
