import 'package:flutter/material.dart';

import '../data/personality_questions.dart';
import '../services/personality_test_service.dart';
import '../widgets/question_card.dart';

class PersonalityTestScreen extends StatefulWidget {
  const PersonalityTestScreen({
    required this.service,
    required this.onCompleted,
    super.key,
  });

  final PersonalityTestService service;
  final VoidCallback onCompleted;

  @override
  State<PersonalityTestScreen> createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<PersonalityTestScreen> {
  final Map<int, int> _answers = {};
  int _currentIndex = 0;
  bool _isSaving = false;

  bool get _isFirstQuestion => _currentIndex == 0;
  bool get _isLastQuestion => _currentIndex == personalityQuestions.length - 1;
  bool get _isComplete => _answers.length == personalityQuestions.length;

  void _selectAnswer(int score) {
    setState(() {
      _answers[personalityQuestions[_currentIndex].id] = score;
    });
  }

  void _goBack() {
    if (_isFirstQuestion || _isSaving) return;
    setState(() => _currentIndex--);
  }

  void _goNext() {
    if (_isLastQuestion || _isSaving) return;
    setState(() => _currentIndex++);
  }

  Future<void> _submitTest() async {
    if (!_isComplete || _isSaving) return;

    if (widget.service.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oturum bulunamadı. Lütfen tekrar gir.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = widget.service.calculateResult(_answers);
      await widget.service.saveResult(result);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kişilik testi başarıyla kaydedildi.')),
      );
      widget.onCompleted();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Test kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final question = personalityQuestions[_currentIndex];
    final selectedAnswer = _answers[question.id];
    final progress = (_currentIndex + 1) / personalityQuestions.length;

    return Scaffold(
      backgroundColor: const Color(0xFF05070D),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6C85F).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0x33F6C85F)),
                  ),
                  child: const Icon(
                    Icons.psychology_alt_rounded,
                    color: Color(0xFFF6C85F),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kişilik Testi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${_currentIndex + 1} / ${personalityQuestions.length}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFFA5A8B3),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(999),
              color: const Color(0xFFF6C85F),
              backgroundColor: Colors.white.withValues(alpha: 0.10),
            ),
            const SizedBox(height: 24),
            QuestionCard(
              question: question,
              selectedAnswer: selectedAnswer,
              onAnswerSelected: _selectAnswer,
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isFirstQuestion || _isSaving ? null : _goBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Geri'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isLastQuestion
                        ? (_isComplete && !_isSaving ? _submitTest : null)
                        : (selectedAnswer == null || _isSaving
                              ? null
                              : _goNext),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF05070D),
                            ),
                          )
                        : Icon(
                            _isLastQuestion
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                          ),
                    label: Text(_isLastQuestion ? 'Testi Tamamla' : 'İleri'),
                  ),
                ),
              ],
            ),
            if (_isLastQuestion && !_isComplete) ...[
              const SizedBox(height: 14),
              Text(
                'Testi tamamlamak için 30 sorunun tamamını cevaplamalısın.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFA5A8B3),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
