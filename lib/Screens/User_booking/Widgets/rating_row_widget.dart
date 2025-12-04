import 'package:flutter/material.dart';

class _MoodItem {
  final IconData icon;
  final String label;
  const _MoodItem(this.icon, this.label);
}

class RatingRow extends StatelessWidget {
  const RatingRow({
    required this.selected,
    required this.onSelect,
  });

  final int selected;
  final ValueChanged<int> onSelect;

  static const List<_MoodItem> items = [
    _MoodItem(Icons.sentiment_very_dissatisfied_rounded, 'Terrible'),
    _MoodItem(Icons.sentiment_dissatisfied_rounded,     'Bad'),
    _MoodItem(Icons.sentiment_neutral_rounded,          'Okay'),
    _MoodItem(Icons.sentiment_satisfied_alt_rounded,    'Good'),
    _MoodItem(Icons.sentiment_very_satisfied_rounded,   'Amazing'),
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(items.length, (i) {
        final item = items[i];
        return _MoodPill(
          icon: item.icon,
          label: item.label,
          selected: i == selected,
          onTap: () => onSelect(i),
        );
      }),
    );
  }
}

class _MoodPill extends StatelessWidget {
  const _MoodPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF5C2E91).withOpacity(.12) : const Color(0xFFF4E9FF);
    final border = selected ? const Color(0xFF5C2E91) : const Color(0xFFE6DAF7);
    final fg = selected ? const Color(0xFF5C2E91) : const Color(0xFF5C2E91);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.04),
              blurRadius: 10,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
