import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/project_model.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/project_provider.dart';

class CreateProjectDialog extends StatefulWidget {
  final Project? project;

  const CreateProjectDialog({super.key, this.project});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  String _selectedColor = ProjectProvider.projectColors.first;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project?.name ?? '');
    _descController = TextEditingController(text: widget.project?.description ?? '');
    _selectedColor = widget.project?.color ?? ProjectProvider.projectColors.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.project != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Project' : 'New Project'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name'),
                validator: (value) => value!.isEmpty ? 'Enter project name' : null,
              ),
              const SizedBox(height: 12),

              // Description
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Color selector
              Wrap(
                spacing: 8,
                children: ProjectProvider.projectColors.map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: CircleAvatar(
                      radius: isSelected ? 20 : 16,
                      backgroundColor: ProjectProvider.getColorFromHex(color),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              final authProvider = context.read<AuthProvider>();
              final userId = authProvider.currentUser?.id;

              if (userId == null) return;

              final success = isEdit
                  ? await context.read<ProjectProvider>().updateProject(
                widget.project!.copyWith(
                  name: _nameController.text.trim(),
                  description: _descController.text.trim(),
                  color: _selectedColor,
                ),
              )
                  : await context.read<ProjectProvider>().createProject(
                name: _nameController.text.trim(),
                description: _descController.text.trim(),
                color: _selectedColor,
                userId: userId,
              );

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Project ${isEdit ? 'updated' : 'created'} successfully'
                        : 'Failed to ${isEdit ? 'update' : 'create'} project'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            }
          },
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
