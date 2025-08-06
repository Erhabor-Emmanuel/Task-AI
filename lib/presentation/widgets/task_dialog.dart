import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/task_model.dart';
import '../../data/providers/task_provider.dart';

class CreateTaskDialog extends StatefulWidget {
  final Task? task;

  const CreateTaskDialog({super.key, this.task});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TaskPriority _priority;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _descriptionController = TextEditingController(text: widget.task?.description ?? '');
    _priority = widget.task?.priority ?? TaskPriority.low;
    _dueDate = widget.task?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Task' : 'Create Task'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) => value == null || value.isEmpty ? 'Enter title' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                onChanged: (val) => setState(() => _priority = val!),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                  value: p,
                  child: Text(p.name.toUpperCase()),
                ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_dueDate == null
                    ? 'No Due Date'
                    : 'Due: ${_dueDate!.toLocal().toString().split(' ')[0]}'),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _dueDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _dueDate = picked);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;

            final provider = context.read<TaskProvider>();
            final userId = widget.task?.userId ?? 'current_user_id'; // Replace with auth ID
            final projectId = widget.task?.projectId ?? 'default_project'; // Replace with real value

            if (widget.task == null) {
              await provider.createTask(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                priority: _priority,
                dueDate: _dueDate,
                projectId: projectId,
                userId: userId,
              );
            } else {
              final updated = widget.task!.copyWith(
                title: _titleController.text.trim(),
                description: _descriptionController.text.trim(),
                priority: _priority,
                dueDate: _dueDate,
              );
              await provider.updateTask(updated);
            }

            if (mounted) Navigator.pop(context);
          },
          child: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
