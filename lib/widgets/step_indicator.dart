import 'package:flutter/material.dart';
import '../theme/tokens.dart';

class StepIndicator extends StatelessWidget {
  final int index;
  final int total;
  const StepIndicator({super.key, required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: Tokens.s4),
          height: 8,
          width: active ? 22 : 8,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey[300],
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
