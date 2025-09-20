import 'package:flutter/material.dart';

class LabeledIcon extends StatelessWidget {
  final String label;
  final IconData icon;
  const LabeledIcon({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.black54),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}