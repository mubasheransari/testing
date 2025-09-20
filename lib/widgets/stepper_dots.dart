import 'package:flutter/material.dart';

class StepperDots extends StatelessWidget {
  final int activeIndex;
  final int total;
  const StepperDots({super.key, required this.activeIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 8,
          width: active ? 20 : 8,
          decoration: BoxDecoration(
            color: active ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}
