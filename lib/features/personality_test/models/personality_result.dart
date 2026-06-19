class PersonalityResult {
  const PersonalityResult({
    required this.answers,
    required this.scores,
    required this.levels,
    required this.displayLevels,
  });

  final Map<String, int> answers;
  final Map<String, int> scores;
  final Map<String, String> levels;
  final Map<String, String> displayLevels;

  factory PersonalityResult.fromFirestore(Map<String, dynamic> data) {
    final rawAnswers = Map<String, dynamic>.from(data['answers'] as Map);
    final rawScores = Map<String, dynamic>.from(data['scores'] as Map);

    return PersonalityResult(
      answers: rawAnswers.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      scores: rawScores.map(
        (key, value) => MapEntry(key, (value as num).toInt()),
      ),
      levels: Map<String, String>.from(data['levels'] as Map),
      displayLevels: Map<String, String>.from(data['displayLevels'] as Map),
    );
  }
}
