import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_ai/presentation/screens/project_details.dart';
import 'package:task_ai/presentation/widgets/create_project_dialog.dart';
import 'package:task_ai/presentation/widgets/project_card.dart';
import '../../data/models/project_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/project_provider.dart';
import '../../data/providers/task_provider.dart';


class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Projects'),
        actions: [
          // Consumer<ProjectProvider>(
          //   builder: (context, projectProvider, child) {
          //     return IconButton(
          //       icon: projectProvider.isSyncing
          //           ? const SizedBox(
          //         width: 20,
          //         height: 20,
          //         child: CircularProgressIndicator(strokeWidth: 2),
          //       )
          //           : const Icon(Icons.sync),
          //       onPressed: projectProvider.isSyncing ? null : () => _syncProjects(),
          //     );
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateProjectDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search projects...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Projects List
          Expanded(
            child: Consumer<ProjectProvider>(
              builder: (context, projectProvider, child) {
                if (projectProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (projectProvider.errorMessage != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          projectProvider.errorMessage!,
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            projectProvider.clearError();
                            _loadProjects();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredProjects = _searchQuery.isEmpty
                    ? projectProvider.projects
                    : projectProvider.searchProjects(_searchQuery);

                if (filteredProjects.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isEmpty ? Icons.folder_outlined : Icons.search_off,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No projects yet'
                              : 'No projects found for "$_searchQuery"',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Create your first project to get started'
                              : 'Try searching with different keywords',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showCreateProjectDialog(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Project'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => _syncProjects(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredProjects.length,
                    itemBuilder: (context, index) {
                      final project = filteredProjects[index];
                      return Consumer<TaskProvider>(
                        builder: (context, taskProvider, child) {
                          final projectTasks = taskProvider.getTasksByProject(project.id);
                          final completedTasks = projectTasks.where((t) => t.isCompleted).length;

                          return ProjectCard(
                            project: project,
                            taskCount: projectTasks.length,
                            completedTasks: completedTasks,
                            onTap: () => _navigateToProjectDetail(project),
                            onEdit: () => _showEditProjectDialog(project),
                            onDelete: () => _showDeleteProjectDialog(project),
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToProjectDetail(Project project) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProjectDetailScreen(project: project),
      ),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateProjectDialog(),
    );
  }

  void _showEditProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(project: project),
    );
  }

  void _showDeleteProjectDialog(Project project) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? This will also delete all tasks in this project.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await context.read<ProjectProvider>().deleteProject(project.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Project deleted successfully'
                          : 'Failed to delete project',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _syncProjects() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      await context.read<ProjectProvider>().syncWithServer(userId);
    }
  }

  void _loadProjects() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      context.read<ProjectProvider>().loadProjects(userId);
    }
  }
}