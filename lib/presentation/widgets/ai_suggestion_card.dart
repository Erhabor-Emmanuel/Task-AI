import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/ai_suggest.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/theme_provider.dart';

class AISuggestionCard extends StatelessWidget {
  final AITaskSuggestion suggestion;
  final int index;
  final bool isSelected;
  final VoidCallback? onToggle;
  final VoidCallback? onRemove;

  const AISuggestionCard({
    super.key,
    required this.suggestion,
    required this.index,
    required this.isSelected,
    this.onToggle,
    this.onRemove,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'No due date';
    return DateFormat.yMMMEd().format(date);
  }

  Color _priorityColor(BuildContext context, TaskPriority priority) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    switch (priority) {
      case TaskPriority.high:
        return Colors.redAccent;
      case TaskPriority.medium:
        return Colors.orangeAccent;
      case TaskPriority.low:
      default:
        return isDark ? Colors.grey[400]! : Colors.grey[700]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => onToggle?.call(),
        ),
        title: Text(
          suggestion.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(suggestion.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                const SizedBox(width: 1),
                Text(_formatDate(suggestion.suggestedDueDate)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _priorityColor(context, suggestion.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    suggestion.priority.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: _priorityColor(context, suggestion.priority),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

