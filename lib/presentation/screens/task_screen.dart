import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:task_ai/presentation/widgets/task_dialog.dart';
import 'package:task_ai/presentation/widgets/task_item.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/project_provider.dart';
import '../../data/providers/task_provider.dart';

enum TaskFilter { all, today, overdue, completed, pending }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  TaskFilter _selectedFilter = TaskFilter.all;
  TaskPriority? _selectedPriority;
  String? _selectedProjectId;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // title: const Text('Tasks'),
        actions: [
          // Consumer<TaskProvider>(
          //   builder: (context, taskProvider, child) {
          //     return IconButton(
          //       icon: taskProvider.isSyncing
          //           ? const SizedBox(
          //         width: 20,
          //         height: 20,
          //         child: CircularProgressIndicator(strokeWidth: 2),
          //       )
          //           : const Icon(Icons.sync),
          //       onPressed: taskProvider.isSyncing ? null : () => _syncTasks(),
          //     );
          //   },
          // ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'create_task':
                  _showCreateTaskDialog();
                  break;
                case 'clear_completed':
                  _showClearCompletedDialog();
                  break;
                case 'export':
                  _exportTasks();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'create_task',
                child: Row(
                  children: [
                    Icon(Icons.add),
                    SizedBox(width: 8),
                    Text('Create Task'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.clear_all),
                    SizedBox(width: 8),
                    Text('Clear Completed'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('Export Tasks'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Today'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filters
          _buildSearchAndFilters(),

          // Task List
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(TaskFilter.all),
                _buildTaskList(TaskFilter.today),
                _buildTaskList(TaskFilter.pending),
                _buildTaskList(TaskFilter.completed),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
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

          const SizedBox(height: 16),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Priority Filter
                FilterChip(
                  label: Text(_selectedPriority == null
                      ? 'Priority'
                      : _selectedPriority!.name.toUpperCase()),
                  selected: _selectedPriority != null,
                  onSelected: (selected) => _showPriorityFilterDialog(),
                ),

                const SizedBox(width: 8),

                // Project Filter
                Consumer<ProjectProvider>(
                  builder: (context, projectProvider, child) {
                    final project = _selectedProjectId != null
                        ? projectProvider.getProjectById(_selectedProjectId!)
                        : null;

                    return FilterChip(
                      label: Text(project?.name ?? 'Project'),
                      selected: _selectedProjectId != null,
                      onSelected: (selected) => _showProjectFilterDialog(),
                    );
                  },
                ),

                const SizedBox(width: 8),

                // Clear Filters
                if (_selectedPriority != null || _selectedProjectId != null)
                  ActionChip(
                    label: const Text('Clear Filters'),
                    onPressed: () {
                      setState(() {
                        _selectedPriority = null;
                        _selectedProjectId = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(TaskFilter filter) {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (taskProvider.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  taskProvider.errorMessage!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    taskProvider.clearError();
                    _loadTasks();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredTasks = _getFilteredTasks(taskProvider, filter);

        if (filteredTasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getEmptyStateIcon(filter),
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _getEmptyStateTitle(filter),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  _getEmptyStateSubtitle(filter),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (filter == TaskFilter.all) ...[
                  ElevatedButton.icon(
                    onPressed: () => _showCreateTaskDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Task'),
                  ),
                ],
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _syncTasks(),
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filteredTasks.length,
            itemBuilder: (context, index) {
              final task = filteredTasks[index];
              return TaskItem(
                task: task,
                onToggle: () => _toggleTask(task),
                onEdit: () => _showEditTaskDialog(task),
                onDelete: () => _showDeleteTaskDialog(task),
                onReschedule: task.status == TaskStatus.overdue
                    ? () => _rescheduleTask(task)
                    : null,
              );
            },
          ),
        );
      },
    );
  }

  List<Task> _getFilteredTasks(TaskProvider taskProvider, TaskFilter filter) {
    List<Task> tasks;

    switch (filter) {
      case TaskFilter.all:
        tasks = taskProvider.allTasks;
        break;
      case TaskFilter.today:
        tasks = taskProvider.todayTasks;
        break;
      case TaskFilter.overdue:
        tasks = taskProvider.overdueTasks;
        break;
      case TaskFilter.completed:
        tasks = taskProvider.getTasksByStatus(TaskStatus.completed);
        break;
      case TaskFilter.pending:
        tasks = taskProvider.getTasksByStatus(TaskStatus.pending);
        break;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      tasks = taskProvider.searchTasks(_searchQuery);
    }

    // Apply priority filter
    if (_selectedPriority != null) {
      tasks = tasks.where((task) => task.priority == _selectedPriority).toList();
    }

    // Apply project filter
    if (_selectedProjectId != null) {
      tasks = tasks.where((task) => task.projectId == _selectedProjectId).toList();
    }

    return tasks;
  }

  IconData _getEmptyStateIcon(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return Icons.task_outlined;
      case TaskFilter.today:
        return Icons.today_outlined;
      case TaskFilter.overdue:
        return Icons.schedule_outlined;
      case TaskFilter.completed:
        return Icons.check_circle_outline;
      case TaskFilter.pending:
        return Icons.pending_outlined;
    }
  }

  String _getEmptyStateTitle(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'No tasks yet';
      case TaskFilter.today:
        return 'No tasks for today';
      case TaskFilter.overdue:
        return 'No overdue tasks';
      case TaskFilter.completed:
        return 'No completed tasks';
      case TaskFilter.pending:
        return 'No pending tasks';
    }
  }

  String _getEmptyStateSubtitle(TaskFilter filter) {
    switch (filter) {
      case TaskFilter.all:
        return 'Create your first task to get started';
      case TaskFilter.today:
        return 'You\'re all caught up for today!';
      case TaskFilter.overdue:
        return 'Great! You\'re on top of your tasks';
      case TaskFilter.completed:
        return 'Complete some tasks to see them here';
      case TaskFilter.pending:
        return 'All tasks are completed!';
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => const CreateTaskDialog(),
    );
  }

  void _showEditTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(task: task),
    );
  }

  void _showDeleteTaskDialog(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              final success = await context.read<TaskProvider>().deleteTask(
                task.id,
                task.userId,
              );

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Task deleted successfully'
                          : 'Failed to delete task',
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

  void _showPriorityFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Priority'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('All Priorities'),
              leading: Radio<TaskPriority?>(
                value: null,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ...TaskPriority.values.map((priority) => ListTile(
              title: Text(priority.name.toUpperCase()),
              leading: Radio<TaskPriority?>(
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                  Navigator.pop(context);
                },
              ),
              trailing: Icon(
                TaskProvider.getPriorityIcon(priority),
                color: TaskProvider.getPriorityColor(priority),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Future<void> _syncTasks() async {
    final taskProvider = context.read<TaskProvider>();
    final userId = 'current_user_id'; // Replace this with your actual auth user ID

    try {
      await taskProvider.syncWithServer(userId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasks synced successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    }
  }

  void _showClearCompletedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Tasks'),
        content: const Text('Are you sure you want to delete all completed tasks?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<TaskProvider>();
              final completed = provider.getTasksByStatus(TaskStatus.completed);
              for (final task in completed) {
                await provider.deleteTask(task.id, task.userId);
              }
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportTasks() {
    final tasks = context.read<TaskProvider>().allTasks;

    final csv = StringBuffer();
    csv.writeln('ID,Title,Description,Priority,DueDate,Status');

    for (var task in tasks) {
      csv.writeln(
        '${task.id},${task.title},${task.description},${task.priority.name},'
            '${task.dueDate?.toIso8601String() ?? ''},${task.status.name}',
      );
    }

    debugPrint(csv.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exported to console (simulate file export)')),
    );
  }

  void _showProjectFilterDialog() {
    final projects = context.read<ProjectProvider>().projects;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter by Project'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              RadioListTile<String?>(
                title: const Text('All Projects'),
                value: null,
                groupValue: _selectedProjectId,
                onChanged: (val) {
                  setState(() => _selectedProjectId = val);
                  Navigator.pop(context);
                },
              ),
              ...projects.map((project) => RadioListTile<String?>(
                title: Text(project.name),
                value: project.id,
                groupValue: _selectedProjectId,
                onChanged: (val) {
                  setState(() => _selectedProjectId = val);
                  Navigator.pop(context);
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleTask(Task task) async {
    final provider = context.read<TaskProvider>();
    await provider.toggleTaskCompletion(task.id, task.userId);
  }

  void _rescheduleTask(Task task) async {
    final provider = context.read<TaskProvider>();
    final success = await provider.rescheduleTask(task);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? 'Task rescheduled successfully'
            : provider.errorMessage ?? 'Failed to reschedule'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _loadTasks() async {
    final taskProvider = context.read<TaskProvider>();
    final userId = 'current_user_id'; // Replace this with actual user ID (e.g. from auth)

    await taskProvider.loadTasks(userId);

    if (mounted && taskProvider.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


}