class PersonalityQuestion {
  const PersonalityQuestion({
    required this.id,
    required this.text,
    required this.category,
    this.reverseScored = false,
  });

  final int id;
  final String text;
  final String category;
  final bool reverseScored;
}
