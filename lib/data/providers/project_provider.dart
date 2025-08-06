import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../services/api_response_service.dart';
import '../services/database_service.dart';

enum ProjectState { idle, loading, error, syncing }

class ProjectProvider extends ChangeNotifier {
  ProjectState _state = ProjectState.idle;
  List<Project> _projects = [];
  String? _errorMessage;
  bool _isSyncing = false;

  ProjectState get state => _state;
  List<Project> get projects => List.unmodifiable(_projects);
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == ProjectState.loading;
  bool get isSyncing => _isSyncing;

  // Get project by ID
  Project? getProjectById(String id) {
    try {
      return _projects.firstWhere((project) => project.id == id);
    } catch (e) {
      return null;
    }
  }

  // Load projects from local database
  Future<void> loadProjects(String userId) async {
    _state = ProjectState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await DatabaseService.instance.getProjectsByUserId(userId);
      _state = ProjectState.idle;
    } catch (e) {
      _errorMessage = 'Failed to load projects';
      _state = ProjectState.error;
    }

    notifyListeners();
  }

  // Create a new project
  Future<bool> createProject({
    required String name,
    required String description,
    required String color,
    required String userId,
  }) async {
    _state = ProjectState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final project = Project(
        name: name,
        description: description,
        color: color,
        userId: userId,
      );

      // Save locally first
      await DatabaseService.instance.insertProject(project);
      _projects.insert(0, project);
      _state = ProjectState.idle;
      notifyListeners();

      // Sync with server in background
      _syncProjectWithServer(project, isNew: true);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to create project';
      _state = ProjectState.error;
      notifyListeners();
      return false;
    }
  }

  // Update an existing project
  Future<bool> updateProject(Project updatedProject) async {
    _state = ProjectState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update locally first
      await DatabaseService.instance.updateProject(updatedProject);

      final index = _projects.indexWhere((p) => p.id == updatedProject.id);
      if (index != -1) {
        _projects[index] = updatedProject;
      }

      _state = ProjectState.idle;
      notifyListeners();

      // Sync with server in background
      _syncProjectWithServer(updatedProject, isNew: false);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project';
      _state = ProjectState.error;
      notifyListeners();
      return false;
    }
  }

  // Delete a project
  Future<bool> deleteProject(String projectId) async {
    _state = ProjectState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Delete locally first
      await DatabaseService.instance.deleteProject(projectId);
      _projects.removeWhere((project) => project.id == projectId);

      _state = ProjectState.idle;
      notifyListeners();

      // Sync with server in background
      _syncProjectDeletion(projectId);

      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project';
      _state = ProjectState.error;
      notifyListeners();
      return false;
    }
  }

  // Sync all projects with server
  Future<void> syncWithServer(String userId) async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      final response = await APIService.instance.syncProjects(userId, _projects);

      if (response.success && response.data != null) {
        // Update local data with server response
        final serverProjects = response.data!;

        // Update database with server data
        for (final project in serverProjects) {
          await DatabaseService.instance.updateProject(project);
        }

        _projects = serverProjects;
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

  // Background sync for individual project
  Future<void> _syncProjectWithServer(Project project, {required bool isNew}) async {
    try {
      final response = isNew
          ? await APIService.instance.createProject(project)
          : await APIService.instance.updateProject(project);

      if (response.success && response.data != null) {
        // Update local data with server response
        final serverProject = response.data!;
        await DatabaseService.instance.updateProject(serverProject);

        final index = _projects.indexWhere((p) => p.id == project.id);
        if (index != -1) {
          _projects[index] = serverProject;
          notifyListeners();
        }
      }
    } catch (e) {
      // Silent failure for background sync
      debugPrint('Background sync failed for project ${project.id}: $e');
    }
  }

  // Background sync for project deletion
  Future<void> _syncProjectDeletion(String projectId) async {
    try {
      await APIService.instance.deleteProject(projectId);
    } catch (e) {
      // Silent failure for background sync
      debugPrint('Background deletion sync failed for project $projectId: $e');
    }
  }

  // Get projects by color for organization
  List<Project> getProjectsByColor(String color) {
    return _projects.where((project) => project.color == color).toList();
  }

  // Search projects
  List<Project> searchProjects(String query) {
    if (query.isEmpty) return _projects;

    final lowercaseQuery = query.toLowerCase();
    return _projects.where((project) {
      return project.name.toLowerCase().contains(lowercaseQuery) ||
          project.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    if (_state == ProjectState.error) {
      _state = ProjectState.idle;
    }
    notifyListeners();
  }

  // Predefined project colors
  static const List<String> projectColors = [
    '#6366F1', // Indigo
    '#EF4444', // Red
    '#10B981', // Green
    '#F59E0B', // Yellow
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
    '#F97316', // Orange
    '#EC4899', // Pink
    '#84CC16', // Lime
    '#6B7280', // Gray
  ];

  static Color getColorFromHex(String hexColor) {
    return Color(int.parse(hexColor.substring(1), radix: 16) + 0xFF000000);
  }
}