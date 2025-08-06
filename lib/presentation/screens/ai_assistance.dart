import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/ai_provider.dart';
import '../../data/providers/auth_provider.dart';
import '../../data/providers/project_provider.dart';
import '../../data/providers/task_provider.dart';
import '../widgets/ai_suggestion_card.dart';
import '../widgets/example_prompts.dart';

class AIAssistantScreen extends StatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  String? _selectedProjectId;
  List<int> _selectedSuggestions = [];

  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // title: const Text('AI Assistant'),
        actions: [
          Consumer<AIProvider>(
            builder: (context, aiProvider, child) {
              if (!aiProvider.hasSuggestions) return const SizedBox.shrink();

              return IconButton(
                icon: const Icon(Icons.clear_all),
                onPressed: () => _showClearSuggestionsDialog(),
                tooltip: 'Clear suggestions',
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primaryContainer,
                  theme.colorScheme.secondaryContainer,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.psychology,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Task Assistant',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Generate personalized tasks with AI',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Prompt Input
                _buildPromptInput(theme),

                const SizedBox(height: 12),

                // Project Selection
                _buildProjectSelection(theme),
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: Consumer<AIProvider>(
              builder: (context, aiProvider, child) {
                if (aiProvider.isLoading) {
                  return _buildLoadingState(aiProvider);
                }

                if (aiProvider.errorMessage != null) {
                  return _buildErrorState(aiProvider);
                }

                if (aiProvider.hasSuggestions) {
                  return _buildSuggestionsState(aiProvider);
                }

                return _buildInitialState();
              },
            ),
          ),

          // Action Buttons (when suggestions are available)
          Consumer<AIProvider>(
            builder: (context, aiProvider, child) {
              if (!aiProvider.hasSuggestions || _selectedSuggestions.isEmpty) {
                return const SizedBox.shrink();
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadowColor.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedSuggestions.clear();
                          });
                        },
                        child: Text('Clear Selection (${_selectedSuggestions.length})'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectedProjectId != null
                            ? () => _importSelectedTasks()
                            : null,
                        icon: const Icon(Icons.add_task),
                        label: Text('Import (${_selectedSuggestions.length})'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPromptInput(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _promptController,
            focusNode: _focusNode,
            maxLines: null,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Ask AI to create tasks for you...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
              prefixIcon: const Icon(Icons.chat_bubble_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Consumer<AIProvider>(
          builder: (context, aiProvider, child) {
            return IconButton.filled(
              onPressed: aiProvider.isLoading ? null : _generateTasks,
              icon: aiProvider.isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.send),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProjectSelection(ThemeData theme) {
    return Consumer<ProjectProvider>(
      builder: (context, projectProvider, child) {
        if (projectProvider.projects.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('Create a project first to import tasks'),
                  ),
                ],
              ),
            ),
          );
        }

        return DropdownButtonFormField<String>(
          value: _selectedProjectId,
          decoration: InputDecoration(
            labelText: 'Select Project for Import',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
          items: projectProvider.projects.map((project) {
            return DropdownMenuItem(
              value: project.id,
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: ProjectProvider.getColorFromHex(project.color),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(project.name),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedProjectId = value;
            });
          },
        );
      },
    );
  }

  Widget _buildLoadingState(AIProvider aiProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            aiProvider.getRandomLoadingMessage(),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a few moments...',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AIProvider aiProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              'Oops! Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              aiProvider.errorMessage!,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                aiProvider.clearError();
                if (_promptController.text.isNotEmpty) {
                  _generateTasks();
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsState(AIProvider aiProvider) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Suggestions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Select tasks to import to your project',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (_selectedSuggestions.length == aiProvider.suggestions.length) {
                      _selectedSuggestions.clear();
                    } else {
                      _selectedSuggestions = List.generate(
                        aiProvider.suggestions.length,
                            (index) => index,
                      );
                    }
                  });
                },
                child: Text(
                  _selectedSuggestions.length == aiProvider.suggestions.length
                      ? 'Deselect All'
                      : 'Select All',
                ),
              ),
            ],
          ),
        ),

        // Suggestions List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: aiProvider.suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = aiProvider.suggestions[index];
              final isSelected = _selectedSuggestions.contains(index);

              return AISuggestionCard(
                suggestion: suggestion,
                isSelected: isSelected,
                onToggle: () {
                  setState(() {
                    if (isSelected) {
                      _selectedSuggestions.remove(index);
                    } else {
                      _selectedSuggestions.add(index);
                    }
                  });
                },
                onRemove: () {
                  aiProvider.removeSuggestion(index);
                  setState(() {
                    _selectedSuggestions = _selectedSuggestions
                        .where((i) => i < index)
                        .toList();
                  });
                }, index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInitialState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Message
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.waving_hand,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'How can I help you today?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'I can help you create personalized tasks based on your goals, schedule, and preferences. Just tell me what you need help with!',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Example Prompts
          ExamplePrompts(
            onPromptSelected: (prompt) {
              final aiProvider = Provider.of<AIProvider>(context, listen: false);
              aiProvider.generateTasks(prompt);
            },
          ),

          const SizedBox(height: 24),

          // Tips Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tips for better results',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ..._getTips().map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.only(top: 6, right: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(child: Text(tip)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getTips() {
    return [
      'Be specific about your goals and timeframe',
      'Mention the type of tasks you prefer (work, personal, health, etc.)',
      'Include any constraints or preferences you have',
      'Ask for a specific number of tasks if needed',
      'Don\'t forget to select a project before importing tasks',
    ];
  }

  Future<void> _generateTasks() async {
    final prompt = _promptController.text.trim();

    // Validate prompt
    final validationError = AIProvider.validatePrompt(prompt);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Clear previous selections
    setState(() {
      _selectedSuggestions.clear();
    });

    // Generate tasks
    await context.read<AIProvider>().generateTasks(prompt);

    // Clear input and dismiss keyboard
    _promptController.clear();
    _focusNode.unfocus();
  }

  Future<void> _importSelectedTasks() async {
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a project first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aiProvider = context.read<AIProvider>();
    final taskProvider = context.read<TaskProvider>();
    final authProvider = context.read<AuthProvider>();

    final userId = authProvider.currentUser?.id;
    if (userId == null) return;

    // Convert selected suggestions to tasks
    final tasksToImport = aiProvider.convertSuggestionsToTasks(
      selectedIndices: _selectedSuggestions,
      projectId: _selectedProjectId!,
      userId: userId,
    );

    if (tasksToImport.isEmpty) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text('Importing ${tasksToImport.length} tasks...'),
          ],
        ),
      ),
    );

    // Import tasks
    final success = await taskProvider.createTasks(tasksToImport, userId);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      if (success) {
        // Remove imported suggestions
        for (int i = _selectedSuggestions.length - 1; i >= 0; i--) {
          final index = _selectedSuggestions[i];
          aiProvider.removeSuggestion(index);
        }

        setState(() {
          _selectedSuggestions.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${tasksToImport.length} tasks'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Tasks',
              onPressed: () {
                // Navigate to tasks screen
                DefaultTabController.of(context)?.animateTo(2);
              },
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              taskProvider.errorMessage ?? 'Failed to import tasks',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearSuggestionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Suggestions'),
        content: const Text(
          'Are you sure you want to clear all AI suggestions? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AIProvider>().clearSuggestions();
              setState(() {
                _selectedSuggestions.clear();
              });
            },
            child: Text(
              'Clear All',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}