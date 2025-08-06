


import 'dart:math';

import '../models/project_model.dart';
import '../models/task_model.dart';

class APIResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final int statusCode;

  APIResponse({
    required this.success,
    this.data,
    this.error,
    required this.statusCode,
  });
}

class APIService {
  static final APIService _instance = APIService._internal();
  static APIService get instance => _instance;
  APIService._internal();

  final Random _random = Random();

  // Simulate network latency
  Future<void> _simulateLatency([int? customDelay]) async {
    final delay = customDelay ?? (_random.nextInt(1000) + 500); // 500-1500ms
    await Future.delayed(Duration(milliseconds: delay));
  }

  // Simulate network errors
  bool _shouldSimulateError() {
    return _random.nextDouble() < 0.1; // 10% chance of error
  }

  // Authentication APIs
  Future<APIResponse<Map<String, dynamic>>> login(String email, String password) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Network error occurred',
        statusCode: 500,
      );
    }

    // Mock validation
    if (email.isNotEmpty && password.length >= 6) {
      return APIResponse(
        success: true,
        data: {
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'user_${email.hashCode.abs()}',
            'email': email,
            'name': email.split('@').first.toUpperCase(),
          }
        },
        statusCode: 200,
      );
    } else {
      return APIResponse(
        success: false,
        error: 'Invalid email or password',
        statusCode: 401,
      );
    }
  }

  Future<APIResponse<Map<String, dynamic>>> register(String email, String password, String name) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Network error occurred',
        statusCode: 500,
      );
    }

    // Mock validation
    if (email.contains('@') && password.length >= 6 && name.isNotEmpty) {
      return APIResponse(
        success: true,
        data: {
          'token': 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}',
          'user': {
            'id': 'user_${email.hashCode.abs()}',
            'email': email,
            'name': name,
          }
        },
        statusCode: 201,
      );
    } else {
      return APIResponse(
        success: false,
        error: 'Invalid registration data',
        statusCode: 400,
      );
    }
  }

  // Project APIs
  Future<APIResponse<List<Project>>> syncProjects(String userId, List<Project> localProjects) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to sync projects',
        statusCode: 500,
      );
    }

    // Mock server response - return the same projects with updated timestamps
    final updatedProjects = localProjects.map((project) {
      return project.copyWith(updatedAt: DateTime.now());
    }).toList();

    return APIResponse(
      success: true,
      data: updatedProjects,
      statusCode: 200,
    );
  }

  Future<APIResponse<Project>> createProject(Project project) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to create project',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      data: project.copyWith(updatedAt: DateTime.now()),
      statusCode: 201,
    );
  }

  Future<APIResponse<Project>> updateProject(Project project) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to update project',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      data: project.copyWith(updatedAt: DateTime.now()),
      statusCode: 200,
    );
  }

  Future<APIResponse<void>> deleteProject(String projectId) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to delete project',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      statusCode: 200,
    );
  }

  // Task APIs
  Future<APIResponse<List<Task>>> syncTasks(String userId, List<Task> localTasks) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to sync tasks',
        statusCode: 500,
      );
    }

    // Mock server response - return the same tasks with updated timestamps
    final updatedTasks = localTasks.map((task) {
      return task.copyWith(updatedAt: DateTime.now());
    }).toList();

    return APIResponse(
      success: true,
      data: updatedTasks,
      statusCode: 200,
    );
  }

  Future<APIResponse<Task>> createTask(Task task) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to create task',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      data: task.copyWith(updatedAt: DateTime.now()),
      statusCode: 201,
    );
  }

  Future<APIResponse<Task>> updateTask(Task task) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to update task',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      data: task.copyWith(updatedAt: DateTime.now()),
      statusCode: 200,
    );
  }

  Future<APIResponse<void>> deleteTask(String taskId) async {
    await _simulateLatency();

    if (_shouldSimulateError()) {
      return APIResponse(
        success: false,
        error: 'Failed to delete task',
        statusCode: 500,
      );
    }

    return APIResponse(
      success: true,
      statusCode: 200,
    );
  }
}