import 'package:flutter/material.dart';
import '../models/ai_suggest.dart';
import '../models/task_model.dart';
import '../services/ai_service.dart';

enum AIState { idle, loading, success, error }

class AIProvider extends ChangeNotifier {
  AIState _state = AIState.idle;
  List<AITaskSuggestion> _suggestions = [];
  String? _errorMessage;
  String _lastPrompt = '';

  AIState get state => _state;
  List<AITaskSuggestion> get suggestions => List.unmodifiable(_suggestions);
  String? get errorMessage => _errorMessage;
  String get lastPrompt => _lastPrompt;
  bool get isLoading => _state == AIState.loading;
  bool get hasSuggestions => _suggestions.isNotEmpty;

  // Generate task suggestions from AI
  Future<void> generateTasks(String prompt) async {
    if (prompt.trim().isEmpty) {
      _errorMessage = 'Please enter a prompt';
      _state = AIState.error;
      notifyListeners();
      return;
    }

    _state = AIState.loading;
    _errorMessage = null;
    _lastPrompt = prompt;
    _suggestions.clear();
    notifyListeners();

    try {
      final response = await AIService.instance.generateTasks(prompt);

      if (response.success && response.data != null) {
        _suggestions = response.data!;
        _state = _suggestions.isEmpty ? AIState.error : AIState.success;
        if (_suggestions.isEmpty) {
          _errorMessage = 'No task suggestions were generated';
        }
      } else {
        _errorMessage = response.error ?? 'Failed to generate tasks';
        _state = AIState.error;
      }
    } catch (e) {
      _errorMessage = 'Network error occurred';
      _state = AIState.error;
    }

    notifyListeners();
  }

  // Convert AI suggestions to tasks
  List<Task> convertSuggestionsToTasks({
    required List<int> selectedIndices,
    required String projectId,
    required String userId,
  }) {
    final selectedSuggestions = selectedIndices
        .where((index) => index >= 0 && index < _suggestions.length)
        .map((index) => _suggestions[index])
        .toList();

    return selectedSuggestions
        .map((suggestion) => suggestion.toTask(
      projectId: projectId,
      userId: userId,
    ))
        .toList();
  }

  // Remove a suggestion from the list
  void removeSuggestion(int index) {
    if (index >= 0 && index < _suggestions.length) {
      _suggestions.removeAt(index);
      if (_suggestions.isEmpty) {
        _state = AIState.idle;
      }
      notifyListeners();
    }
  }

  // Clear all suggestions
  void clearSuggestions() {
    _suggestions.clear();
    _state = AIState.idle;
    _errorMessage = null;
    _lastPrompt = '';
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == AIState.error) {
      _state = _suggestions.isEmpty ? AIState.idle : AIState.success;
    }
    notifyListeners();
  }

  // Get suggestion by index
  AITaskSuggestion? getSuggestionAt(int index) {
    if (index >= 0 && index < _suggestions.length) {
      return _suggestions[index];
    }
    return null;
  }

  // Modify a suggestion
  void updateSuggestion(int index, AITaskSuggestion updatedSuggestion) {
    if (index >= 0 && index < _suggestions.length) {
      _suggestions[index] = updatedSuggestion;
      notifyListeners();
    }
  }

  // Get example prompts for user guidance
  static List<String> getExamplePrompts() {
    return [
      'Plan my week with 3 work tasks and 2 wellness tasks',
      'Create a morning routine with 4 healthy habits',
      'Generate 5 study tasks for learning Flutter',
      'Plan weekend activities with family time and chores',
      'Create a workout plan for the next 3 days',
      'Organize my home office with 6 improvement tasks',
      'Plan a project launch with key deliverables',
      'Create daily writing tasks for my blog',
    ];
  }

  // Get AI prompt suggestions based on context
  static List<String> getContextualPrompts({
    required int projectCount,
    required int pendingTasks,
    String? currentProjectName,
  }) {
    final prompts = <String>[];

    if (pendingTasks > 10) {
      prompts.add('Help me organize my ${pendingTasks} pending tasks');
      prompts.add('Break down my overdue tasks into smaller steps');
    }

    if (projectCount == 0) {
      prompts.add('Create my first project with starter tasks');
      prompts.add('Plan a personal productivity system');
    }

    if (currentProjectName != null) {
      prompts.add('Add more tasks to my $currentProjectName project');
      prompts.add('Create milestone tasks for $currentProjectName');
    }

    prompts.addAll([
      'Plan tomorrow\'s most important tasks',
      'Create a balanced work-life schedule',
      'Generate tasks for skill development',
    ]);

    return prompts;
  }

  // Validate prompt before sending
  static String? validatePrompt(String prompt) {
    final trimmed = prompt.trim();

    if (trimmed.isEmpty) {
      return 'Please enter a prompt';
    }

    if (trimmed.length < 5) {
      return 'Prompt is too short. Please be more specific.';
    }

    if (trimmed.length > 200) {
      return 'Prompt is too long. Please keep it under 200 characters.';
    }

    return null;
  }

  // Get loading messages for better UX
  static List<String> getLoadingMessages() {
    return [
      'AI is analyzing your request...',
      'Generating personalized tasks...',
      'Creating your task suggestions...',
      'Processing with artificial intelligence...',
      'Crafting the perfect tasks for you...',
    ];
  }

  // Get random loading message
  String getRandomLoadingMessage() {
    final messages = getLoadingMessages();
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }
}