import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../data/personality_questions.dart';
import '../models/personality_result.dart';

class PersonalityTestService {
  PersonalityTestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  DocumentReference<Map<String, dynamic>> _resultDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('personalityTest')
        .doc('result');
  }

  Future<bool> hasCompletedTest(String uid) async {
    final user = currentUser;
    debugPrint('uid: ${user?.uid}');
    debugPrint('email: ${user?.email}');
    assert(user != null);

    final snapshot = await _resultDocument(uid).get();
    if (!snapshot.exists) return false;

    final data = snapshot.data();
    if (data == null) return false;

    final completed = data['completed'];
    return completed == true;
  }

  PersonalityResult calculateResult(Map<int, int> selectedAnswers) {
    final answers = <String, int>{};
    final scores = {
      for (final category in personalityCategoryLabels.keys) category: 0,
    };

    for (final question in personalityQuestions) {
      final selectedScore = selectedAnswers[question.id];
      if (selectedScore == null) {
        throw StateError('Question ${question.id} is not answered.');
      }

      answers['q${question.id}'] = selectedScore;
      final effectiveScore = question.reverseScored
          ? 6 - selectedScore
          : selectedScore;
      scores.update(question.category, (value) => value + effectiveScore);
    }

    final levels = {
      for (final entry in scores.entries)
        entry.key: _levelForScore(entry.value),
    };
    final displayLevels = {
      for (final entry in levels.entries)
        entry.key: _displayLevelFor(entry.value),
    };

    return PersonalityResult(
      answers: answers,
      scores: scores,
      levels: levels,
      displayLevels: displayLevels,
    );
  }

  Future<void> saveResult(PersonalityResult result) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    debugPrint('uid: ${user.uid}');
    debugPrint('email: ${user.email}');

    final payload = <String, dynamic>{
      'completed': true,
      'completedAt': DateTime.now().toUtc().toIso8601String(),
      'answers': result.answers.map(
        (key, value) => MapEntry(key, value.toDouble()),
      ),
      'scores': result.scores.map(
        (key, value) => MapEntry(key, value.toDouble()),
      ),
      'levels': Map<String, String>.from(result.levels),
      'displayLevels': Map<String, String>.from(result.displayLevels),
    };

    await _resultDocument(user.uid).set(payload, SetOptions(merge: true));
  }

  Future<void> testFirestoreMinimalWrite() async {
    final user = currentUser;
    debugPrint('uid: ${user?.uid}');
    debugPrint('email: ${user?.email}');
    assert(user != null);

    if (user == null) {
      throw StateError('No authenticated user found.');
    }

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('debug')
        .doc('test')
        .set({
          'name': 'test',
          'value': 1.0,
          'createdAt': DateTime.now().toUtc().toIso8601String(),
        });
  }

  String _levelForScore(int score) {
    if (score <= 12) return 'low';
    if (score <= 20) return 'medium';
    return 'high';
  }

  String _displayLevelFor(String level) {
    return switch (level) {
      'low' => 'Düşük',
      'medium' => 'Orta',
      'high' => 'Yüksek',
      _ => 'Bilinmiyor',
    };
  }
}
