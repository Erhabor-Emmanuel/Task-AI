import 'package:task_ai/data/models/task_model.dart';

class AITaskSuggestion {
  final String title;
  final String description;
  final TaskPriority priority;
  final DateTime? suggestedDueDate;

  AITaskSuggestion({
    required this.title,
    required this.description,
    required this.priority,
    this.suggestedDueDate,
  });

  factory AITaskSuggestion.fromJson(Map<String, dynamic> json) {
    return AITaskSuggestion(
      title: json['title'],
      description: json['description'],
      priority: _parsePriority(json['priority']),
      suggestedDueDate: json['dueDate'] != null
          ? DateTime.tryParse(json['dueDate'])
          : null,
    );
  }

  static TaskPriority _parsePriority(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }

  Task toTask({required String projectId, required String userId}) {
    return Task(
      title: title,
      description: description,
      priority: priority,
      dueDate: suggestedDueDate,
      projectId: projectId,
      userId: userId,
    );
  }
}