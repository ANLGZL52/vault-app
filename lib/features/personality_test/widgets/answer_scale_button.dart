import 'package:flutter/material.dart';

class AnswerScaleButton extends StatelessWidget {
  const AnswerScaleButton({
    required this.score,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    super.key,
  });

  final int score;
  final String label;
  final bool isSelected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? const Color(0xFFF6C85F)
        : Colors.white.withValues(alpha: 0.10);
    final backgroundColor = isSelected
        ? const Color(0xFFF6C85F).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.06);

    return InkWell(
      onTap: () => onSelected(score),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 1.4 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF6C85F)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  color: isSelected ? const Color(0xFF05070D) : Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isSelected ? Colors.white : const Color(0xFFA5A8B3),
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFFF6C85F),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
