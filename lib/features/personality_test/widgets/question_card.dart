import 'package:flutter/material.dart';

import '../data/personality_questions.dart';
import '../models/personality_question.dart';
import 'answer_scale_button.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    required this.question,
    required this.selectedAnswer,
    required this.onAnswerSelected,
    super.key,
  });

  final PersonalityQuestion question;
  final int? selectedAnswer;
  final ValueChanged<int> onAnswerSelected;

  static const _scaleLabels = {
    1: 'Kesinlikle Katılmıyorum',
    2: 'Katılmıyorum',
    3: 'Kararsızım',
    4: 'Katılıyorum',
    5: 'Kesinlikle Katılıyorum',
  };

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        personalityCategoryLabels[question.category] ?? question.category;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6C85F).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x33F6C85F)),
                ),
                child: Text(
                  categoryLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: const Color(0xFFF6C85F),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'Soru ${question.id}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFFA5A8B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            question.text,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 24),
          ..._scaleLabels.entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnswerScaleButton(
                score: entry.key,
                label: entry.value,
                isSelected: selectedAnswer == entry.key,
                onSelected: onAnswerSelected,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
