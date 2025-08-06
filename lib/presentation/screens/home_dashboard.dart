import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../data/models/project_model.dart';
import '../../data/models/task_model.dart';
import '../../data/models/user_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/project_provider.dart';
import '../../data/providers/task_provider.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.read<AuthProvider>().currentUser;

    return RefreshIndicator(
      onRefresh: () => _refreshData(context),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(theme, user),

            const SizedBox(height: 24),

            // Quick Stats
            _buildQuickStats(theme),

            const SizedBox(height: 24),

            // Today's Tasks
            _buildTodayTasks(theme),

            const SizedBox(height: 24),

            // Recent Projects
            _buildRecentProjects(theme),

            const SizedBox(height: 24),

            // Overdue Tasks (if any)
            _buildOverdueTasks(theme),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData(BuildContext context) async {
    final userId = context.read<AuthProvider>().currentUser?.id;
    if (userId != null) {
      await Future.wait([
        context.read<ProjectProvider>().loadProjects(userId),
        context.read<TaskProvider>().loadTasks(userId),
      ]);
    }
  }

  Widget _buildWelcomeSection(ThemeData theme, User? user) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            user?.name ?? 'User',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, y').format(now),
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimary.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final stats = taskProvider.getTaskStats();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Total Tasks',
                    stats.total.toString(),
                    Icons.task_alt,
                    theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Completed',
                    stats.completed.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Pending',
                    stats.pending.toString(),
                    Icons.pending,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    theme,
                    'Overdue',
                    stats.overdue.toString(),
                    Icons.warning,
                    Colors.red,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
      ThemeData theme,
      String title,
      String value,
      IconData icon,
      Color color,
      ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTasks(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final todayTasks = taskProvider.todayTasks;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Today\'s Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (todayTasks.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to tasks screen filtered by today
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (todayTasks.isEmpty)
              _buildEmptyState(
                theme,
                'No tasks for today',
                'Great! You have a clear schedule today.',
                Icons.calendar_today,
              )
            else
              ...todayTasks.take(3).map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildTaskCard(theme, task),
              )),
          ],
        );
      },
    );
  }

  Widget _buildRecentProjects(ThemeData theme) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        final projects = projectProvider.projects.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Recent Projects',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (projects.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to projects screen
                    },
                    child: const Text('View All'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (projects.isEmpty)
              _buildEmptyState(
                theme,
                'No projects yet',
                'Create your first project to get started.',
                Icons.folder_outlined,
              )
            else
              ...projects.map((project) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildProjectCard(theme, project),
              )),
          ],
        );
      },
    );
  }

  Widget _buildOverdueTasks(ThemeData theme) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final overdueTasks = taskProvider.overdueTasks;

        if (overdueTasks.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Overdue Tasks',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    overdueTasks.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...overdueTasks.take(2).map((task) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTaskCard(theme, task, isOverdue: true),
            )),
          ],
        );
      },
    );
  }

  Widget _buildTaskCard(ThemeData theme, Task task, {bool isOverdue = false}) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Card(
          child: ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (value) {
                final userId = context.read<AuthProvider>().currentUser?.id;
                if (userId != null) {
                  taskProvider.toggleTaskCompletion(task.id, userId);
                }
              },
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                color: isOverdue ? Colors.red : null,
              ),
            ),
            subtitle: task.dueDate != null
                ? Text(
              'Due: ${DateFormat('MMM d, h:mm a').format(task.dueDate!)}',
              style: TextStyle(
                color: isOverdue ? Colors.red : theme.colorScheme.onSurfaceVariant,
              ),
            )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  TaskProvider.getPriorityIcon(task.priority),
                  color: TaskProvider.getPriorityColor(task.priority),
                  size: 16,
                ),
                if (isOverdue)
                  IconButton(
                    onPressed: () => _rescheduleTask(context, task),
                    icon: const Icon(Icons.schedule, color: Colors.orange),
                    tooltip: 'Suggest new time',
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectCard(ThemeData theme, Project project) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final projectTasks = taskProvider.getTasksByProject(project.id);
        final completedTasks = projectTasks.where((t) => t.isCompleted).length;

        return Card(
          child: ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: ProjectProvider.getColorFromHex(project.color),
                shape: BoxShape.circle,
              ),
            ),
            title: Text(project.name),
            subtitle: Text(
              '$completedTasks/${projectTasks.length} tasks completed',
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navigate to project details
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
      ThemeData theme,
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _rescheduleTask(BuildContext context, Task task) {
    final taskProvider = context.read<TaskProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Task'),
        content: const Text('Would you like AI to suggest a new time for this overdue task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await taskProvider.rescheduleTask(task);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Task rescheduled successfully'
                          : taskProvider.errorMessage ?? 'Failed to reschedule task',
                    ),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Suggest New Time'),
          ),
        ],
      ),
    );
  }
}