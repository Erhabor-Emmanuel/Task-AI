import 'package:flutter/material.dart';
import '../../data/providers/ai_provider.dart';

class ExamplePrompts extends StatelessWidget {
  final void Function(String prompt) onPromptSelected;

  const ExamplePrompts({super.key, required this.onPromptSelected});

  @override
  Widget build(BuildContext context) {
    final prompts = AIProvider.getExamplePrompts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Try a prompt:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prompts.map((prompt) {
            return ActionChip(
              label: Text(prompt),
              onPressed: () => onPromptSelected(prompt),
            );
          }).toList(),
        ),
      ],
    );
  }
}
