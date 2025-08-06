import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/task_stats.dart';
import '../services/ai_service.dart';
import '../services/api_response_service.dart';
import '../services/database_service.dart';

enum TaskState { idle, loading, error, syncing }

class TaskProvider extends ChangeNotifier {
  TaskState _state = TaskState.idle;
  List<Task> _allTasks = [];
  List<Task> _todayTasks = [];
  List<Task> _overdueTasks = [];
  String? _errorMessage;
  bool _isSyncing = false;

  TaskState get state => _state;
  List<Task> get allTasks => List.unmodifiable(_allTasks);
  List<Task> get todayTasks => List.unmodifiable(_todayTasks);
  List<Task> get overdueTasks => List.unmodifiable(_overdueTasks);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == TaskState.loading;
  bool get isSyncing => _isSyncing;

  // Get tasks by project
  List<Task> getTasksByProject(String projectId) {
    return _allTasks.where((task) => task.projectId == projectId).toList();
  }

  // Get task by ID
  Task? getTaskById(String id) {
    try {
      return _allTasks.firstWhere((task) => task.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get task statistics
  TaskStats getTaskStats() {
    final completed = _allTasks.where((task) => task.isCompleted).length;
    final pending = _allTasks.where((task) => !task.isCompleted).length;
    final overdue = _overdueTasks.length;
    final today = _todayTasks.length;

    return TaskStats(
      total: _allTasks.length,
      completed: completed,
      pending: pending,
      overdue: overdue,
      today: today,
    );
  }

  // Load all tasks for a user
  Future<void> loadTasks(String userId) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _allTasks = await DatabaseService.instance.getTasksByUserId(userId);
      _todayTasks = await DatabaseService.instance.getTodayTasks(userId);
      _overdueTasks = await DatabaseService.instance.getOverdueTasks(userId);
      _state = TaskState.idle;
    } catch (e) {
      _errorMessage = 'Failed to load tasks';
      _state = TaskState.error;
    }

    notifyListeners();
  }

  // Create a new task
  Future<bool> createTask({
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? dueDate,
    required String projectId,
    required String userId,
  }) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final task = Task(
        title: title,
        description: description,
        priority: priority,
        dueDate: dueDate,
        projectId: projectId,
        userId: userId,
      );

      // Save locally first
      await DatabaseService.instance.insertTask(task);
      _allTasks.insert(0, task);

      // Update filtered lists
      await _updateFilteredLists(userId);

      _state = TaskState.idle;
      notifyListeners();

      // Sync with server in background
      _syncTaskWithServer(task, isNew: true);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create task';
      _state = TaskState.error;
      notifyListeners();
      return false;
    }
  }

  // Update an existing task
  Future<bool> updateTask(Task updatedTask) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update locally first
      await DatabaseService.instance.updateTask(updatedTask);

      final index = _allTasks.indexWhere((t) => t.id == updatedTask.id);
      if (index != -1) {
        _allTasks[index] = updatedTask;
      }

      // Update filtered lists
      await _updateFilteredLists(updatedTask.userId);

      _state = TaskState.idle;
      notifyListeners();

      // Sync with server in background
      _syncTaskWithServer(updatedTask, isNew: false);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update task';
      _state = TaskState.error;
      notifyListeners();
      return false;
    }
  }

  // Toggle task completion
  Future<bool> toggleTaskCompletion(String taskId, String userId) async {
    final task = getTaskById(taskId);
    if (task == null) return false;

    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      updatedAt: DateTime.now(),
    );

    return await updateTask(updatedTask);
  }

  // Delete a task
  Future<bool> deleteTask(String taskId, String userId) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete locally first
      await DatabaseService.instance.deleteTask(taskId);
      _allTasks.removeWhere((task) => task.id == taskId);

      // Update filtered lists
      await _updateFilteredLists(userId);

      _state = TaskState.idle;
      notifyListeners();

      // Sync with server in background
      _syncTaskDeletion(taskId);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete task';
      _state = TaskState.error;
      notifyListeners();
      return false;
    }
  }

  // Reschedule task with AI suggestion
  Future<bool> rescheduleTask(Task task) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await AIService.instance.suggestReschedule(task);

      if (response.success && response.data != null) {
        final newDueDate = response.data!;
        final updatedTask = task.copyWith(dueDate: newDueDate);

        return await updateTask(updatedTask);
      } else {
        _errorMessage = response.error ?? 'Failed to reschedule task';
        _state = TaskState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to get reschedule suggestion';
      _state = TaskState.error;
      notifyListeners();
      return false;
    }
  }

  // Bulk create tasks (for AI integration)
  Future<bool> createTasks(List<Task> tasks, String userId) async {
    _state = TaskState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Save locally first
      await DatabaseService.instance.insertTasks(tasks);
      _allTasks.insertAll(0, tasks);

      // Update filtered lists
      await _updateFilteredLists(userId);

      _state = TaskState.idle;
      notifyListeners();

      // Sync with server in background
      for (final task in tasks) {
        _syncTaskWithServer(task, isNew: true);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create tasks';
      _state = TaskState.error;
      notifyListeners();
      return false;
    }
  }

  // Sync all tasks with server
  Future<void> syncWithServer(String userId) async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final response = await APIService.instance.syncTasks(userId, _allTasks);

      if (response.success && response.data != null) {
        // Update local data with server response
        final serverTasks = response.data!;

        // Update database with server data
        for (final task in serverTasks) {
          await DatabaseService.instance.updateTask(task);
        }

        _allTasks = serverTasks;
        await _updateFilteredLists(userId);
        _errorMessage = null;
      } else {
        _errorMessage = response.error ?? 'Sync failed';
      }
    } catch (e) {
      _errorMessage = 'Network error during sync';
    }

    _isSyncing = false;
    notifyListeners();
  }

  // Update filtered task lists
  Future<void> _updateFilteredLists(String userId) async {
    try {
      _todayTasks = await DatabaseService.instance.getTodayTasks(userId);
      _overdueTasks = await DatabaseService.instance.getOverdueTasks(userId);
    } catch (e) {
      debugPrint('Failed to update filtered lists: $e');
    }
  }

  // Background sync for individual task
  Future<void> _syncTaskWithServer(Task task, {required bool isNew}) async {
    try {
      final response = isNew
          ? await APIService.instance.createTask(task)
          : await APIService.instance.updateTask(task);

      if (response.success && response.data != null) {
        // Update local data with server response
        final serverTask = response.data!;
        await DatabaseService.instance.updateTask(serverTask);

        final index = _allTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _allTasks[index] = serverTask;
          await _updateFilteredLists(task.userId);
          notifyListeners();
        }
      }
    } catch (e) {
      // Silent failure for background sync
      debugPrint('Background sync failed for task ${task.id}: $e');
    }
  }

  // Background sync for task deletion
  Future<void> _syncTaskDeletion(String taskId) async {
    try {
      await APIService.instance.deleteTask(taskId);
    } catch (e) {
      // Silent failure for background sync
      debugPrint('Background deletion sync failed for task $taskId: $e');
    }
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _allTasks;

    final lowercaseQuery = query.toLowerCase();
    return _allTasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
          task.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Filter tasks by priority
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _allTasks.where((task) => task.priority == priority).toList();
  }

  // Filter tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _allTasks.where((task) => task.status == status).toList();
  }

  // Get tasks for a specific date range
  List<Task> getTasksInDateRange(DateTime start, DateTime end) {
    return _allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.isAfter(start) && task.dueDate!.isBefore(end);
    }).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == TaskState.error) {
      _state = TaskState.idle;
    }
    notifyListeners();
  }

  // Get priority color
  static Color getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red;
      case TaskPriority.medium:
        return Colors.orange;
      case TaskPriority.low:
        return Colors.green;
    }
  }

  // Get priority icon
  static IconData getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.keyboard_double_arrow_up;
      case TaskPriority.medium:
        return Icons.keyboard_arrow_up;
      case TaskPriority.low:
        return Icons.keyboard_arrow_down;
    }
  }

  // Get status color
  static Color getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.pending:
        return Colors.blue;
      case TaskStatus.overdue:
        return Colors.red;
    }
  }
}