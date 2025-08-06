import 'package:flutter/material.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/task_provider.dart';

class TaskItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onReschedule;

  const TaskItem({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    this.onReschedule,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = TaskProvider.getStatusColor(task.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: task.isCompleted,
          onChanged: (_) => onToggle(),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: task.dueDate != null
            ? Text('Due: ${task.dueDate!.toLocal().toString().split(' ')[0]}')
            : null,
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                onEdit();
                break;
              case 'delete':
                onDelete();
                break;
              case 'reschedule':
                if (onReschedule != null) onReschedule!();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
            if (onReschedule != null)
              const PopupMenuItem(value: 'reschedule', child: Text('Reschedule')),
          ],
        ),
      ),
    );
  }
}
