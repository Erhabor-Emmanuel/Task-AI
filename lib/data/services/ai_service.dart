import 'dart:math';
import '../models/ai_suggest.dart';
import '../models/task_model.dart';
import 'api_response_service.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  static AIService get instance => _instance;
  AIService._internal();

  final Random _random = Random();

  Future<void> _simulateAILatency() async {
    await Future.delayed(Duration(milliseconds: _random.nextInt(2000) + 1000)); // 1-3 seconds
  }

  Future<APIResponse<List<AITaskSuggestion>>> generateTasks(String prompt) async {
    await _simulateAILatency();

    if (_random.nextDouble() < 0.1) { // 10% chance of error
      return APIResponse(
        success: false,
        error: 'AI service is temporarily unavailable',
        statusCode: 503,
      );
    }

    // Mock AI response based on prompt keywords
    final suggestions = _generateMockSuggestions(prompt);

    return APIResponse(
      success: true,
      data: suggestions,
      statusCode: 200,
    );
  }

  Future<APIResponse<DateTime>> suggestReschedule(Task task) async {
    await _simulateAILatency();

    if (_random.nextDouble() < 0.1) { // 10% chance of error
      return APIResponse(
        success: false,
        error: 'Failed to generate reschedule suggestion',
        statusCode: 503,
      );
    }

    // Generate smart reschedule suggestion
    final now = DateTime.now();
    final suggestedTime = _generateSmartReschedule(task, now);

    return APIResponse(
      success: true,
      data: suggestedTime,
      statusCode: 200,
    );
  }

  List<AITaskSuggestion> _generateMockSuggestions(String prompt) {
    final lowercasePrompt = prompt.toLowerCase();
    final suggestions = <AITaskSuggestion>[];

    // Work-related suggestions
    if (lowercasePrompt.contains('work') || lowercasePrompt.contains('office') || lowercasePrompt.contains('meeting')) {
      suggestions.addAll([
        AITaskSuggestion(
          title: 'Review quarterly reports',
          description: 'Analyze Q4 performance metrics and prepare summary',
          priority: TaskPriority.high,
          suggestedDueDate: DateTime.now().add(const Duration(days: 2)),
        ),
        AITaskSuggestion(
          title: 'Team standup meeting',
          description: 'Daily sync with development team',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        AITaskSuggestion(
          title: 'Update project documentation',
          description: 'Revise API documentation and user guides',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 3)),
        ),
      ]);
    }

    // Wellness-related suggestions
    if (lowercasePrompt.contains('wellness') || lowercasePrompt.contains('health') || lowercasePrompt.contains('exercise')) {
      suggestions.addAll([
        AITaskSuggestion(
          title: 'Morning workout',
          description: '30-minute cardio session',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        AITaskSuggestion(
          title: 'Meditation session',
          description: '15-minute mindfulness practice',
          priority: TaskPriority.low,
          suggestedDueDate: DateTime.now().add(const Duration(hours: 2)),
        ),
      ]);
    }

    // Personal tasks
    if (lowercasePrompt.contains('personal') || lowercasePrompt.contains('home')) {
      suggestions.addAll([
        AITaskSuggestion(
          title: 'Grocery shopping',
          description: 'Buy weekly groceries and household items',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        AITaskSuggestion(
          title: 'Clean living room',
          description: 'Vacuum and organize living space',
          priority: TaskPriority.low,
          suggestedDueDate: DateTime.now().add(const Duration(days: 2)),
        ),
      ]);
    }

    // Learning tasks
    if (lowercasePrompt.contains('learn') || lowercasePrompt.contains('study') || lowercasePrompt.contains('course')) {
      suggestions.addAll([
        AITaskSuggestion(
          title: 'Complete Flutter course module',
          description: 'Finish chapter on state management',
          priority: TaskPriority.high,
          suggestedDueDate: DateTime.now().add(const Duration(days: 3)),
        ),
        AITaskSuggestion(
          title: 'Practice coding exercises',
          description: 'Solve 5 algorithm problems on LeetCode',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);
    }

    // Default suggestions if no specific keywords found
    if (suggestions.isEmpty) {
      suggestions.addAll([
        AITaskSuggestion(
          title: 'Plan weekly goals',
          description: 'Set priorities and objectives for the upcoming week',
          priority: TaskPriority.high,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
        AITaskSuggestion(
          title: 'Review and organize tasks',
          description: 'Clean up task list and update priorities',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 2)),
        ),
        AITaskSuggestion(
          title: 'Schedule time for deep work',
          description: 'Block 2 hours for focused, uninterrupted work',
          priority: TaskPriority.medium,
          suggestedDueDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ]);
    }

    // Extract number from prompt if specified
    final numberMatch = RegExp(r'(\d+)').firstMatch(lowercasePrompt);
    if (numberMatch != null) {
      final requestedCount = int.tryParse(numberMatch.group(1)!) ?? suggestions.length;
      return suggestions.take(requestedCount).toList();
    }

    return suggestions.take(5).toList(); // Return max 5 suggestions
  }

  DateTime _generateSmartReschedule(Task task, DateTime now) {
    final priority = task.priority;
    final originalDue = task.dueDate;

    // Smart rescheduling logic based on priority and current time
    switch (priority) {
      case TaskPriority.high:
      // High priority: reschedule to tomorrow morning
        return DateTime(now.year, now.month, now.day + 1, 9, 0);

      case TaskPriority.medium:
      // Medium priority: reschedule to day after tomorrow
        return DateTime(now.year, now.month, now.day + 2, 14, 0);

      case TaskPriority.low:
      // Low priority: reschedule to next week
        final daysUntilNextWeek = 7 - now.weekday + 1;
        return DateTime(now.year, now.month, now.day + daysUntilNextWeek, 10, 0);
    }
  }
}