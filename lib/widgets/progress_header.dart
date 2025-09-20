import 'package:flutter/material.dart';

class ProgressHeader extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  const ProgressHeader({
    super.key,
    required this.title,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final pct = step / totalSteps;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(value: pct),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
