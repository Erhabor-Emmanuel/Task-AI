import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/project_model.dart';
import '../../data/providers/project_provider.dart';
import '../../data/providers/task_provider.dart';

class ProjectDetailScreen extends StatelessWidget {
  final Project project;

  const ProjectDetailScreen({super.key, required this.project});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taskProvider = context.watch<TaskProvider>();
    final tasks = taskProvider.getTasksByProject(project.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(project.name),
        backgroundColor: ProjectProvider.getColorFromHex(project.color),
      ),
      body: tasks.isEmpty
          ? Center(
        child: Text(
          'No tasks yet for this project',
          style: theme.textTheme.bodyLarge,
        ),
      )
          : ListView.builder(
        itemCount: tasks.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            trailing: Icon(
              task.isCompleted ? Icons.check_circle : Icons.circle_outlined,
              color: task.isCompleted ? Colors.green : null,
            ),
          );
        },
      ),
    );
  }
}
