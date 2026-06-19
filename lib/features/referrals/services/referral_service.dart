import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class ReferralService {
  ReferralService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  static const _codeCharacters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final _random = Random.secure();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _referralCodeDocument(String code) {
    return _firestore.collection('referralCodes').doc(code);
  }

  Future<void> ensureUserDocument({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      final userRef = _userDocument(uid);
      _debugRead('users/$uid');
      final snapshot = await userRef.get();
      final data = snapshot.data() ?? const <String, dynamic>{};

      await userRef.set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt':
            data['createdAt'] as String? ??
            DateTime.now().toUtc().toIso8601String(),
        'puzzlePieces': ((data['puzzlePieces'] as num?) ?? 0).toDouble(),
        'vaultCredits': ((data['vaultCredits'] as num?) ?? 0).toDouble(),
        'hasAllVaults': data['hasAllVaults'] == true,
      }, SetOptions(merge: true));
    } catch (error, stackTrace) {
      _debugFailure('ensureUserDocument failed', error, stackTrace);
      rethrow;
    }
  }

  Future<String> ensureReferralCode({String? uid}) async {
    try {
      final userId = uid ?? _requireUser().uid;
      final userRef = _userDocument(userId);
      _debugRead('users/$userId');
      final snapshot = await userRef.get();
      final data = snapshot.data();
      final existingCode = data?['referralCode'] as String?;

      if (existingCode != null && existingCode.trim().isNotEmpty) {
        await _ensureDefaultUserFields(userRef);
        return existingCode;
      }

      for (var attempt = 0; attempt < 10; attempt++) {
        final code = _generateCode(length: attempt < 6 ? 6 : 8);
        final codeRef = _referralCodeDocument(code);

        try {
          await _firestore.runTransaction((transaction) async {
            _debugRead('referralCodes/$code');
            final codeSnapshot = await transaction.get(codeRef);
            if (codeSnapshot.exists) {
              throw _ReferralCodeCollision();
            }

            _debugRead('users/$userId');
            final freshUserSnapshot = await transaction.get(userRef);
            final freshUserData = freshUserSnapshot.data();
            final freshCode = freshUserData?['referralCode'] as String?;
            if (freshCode != null && freshCode.trim().isNotEmpty) {
              return;
            }

            transaction.set(userRef, {
              'referralCode': code,
              'puzzlePieces':
                  (freshUserData?['puzzlePieces'] as num?)?.toDouble() ?? 0.0,
              'vaultCredits':
                  (freshUserData?['vaultCredits'] as num?)?.toDouble() ?? 0.0,
              'hasAllVaults': freshUserData?['hasAllVaults'] == true,
            }, SetOptions(merge: true));

            transaction.set(codeRef, {
              'uid': userId,
              'createdAt': DateTime.now().toUtc().toIso8601String(),
            });
          });

          _debugRead('users/$userId');
          final updatedSnapshot = await userRef.get();
          final updatedCode =
              updatedSnapshot.data()?['referralCode'] as String?;
          if (updatedCode != null && updatedCode.trim().isNotEmpty) {
            return updatedCode;
          }
        } on _ReferralCodeCollision {
          continue;
        }
      }

      throw StateError('Referans kodu oluşturulamadı. Lütfen tekrar dene.');
    } catch (error, stackTrace) {
      _debugFailure('ensureReferralCode failed', error, stackTrace);
      rethrow;
    }
  }

  Future<ReferralApplyResult> applyReferralCode({
    required String newUserUid,
    required String rawCode,
  }) async {
    try {
      final code = rawCode.trim().toUpperCase();
      if (code.isEmpty) return ReferralApplyResult.skipped();

      final newUserRef = _userDocument(newUserUid);
      _debugRead('users/$newUserUid');
      final newUserSnap = await newUserRef.get();
      final newUserData = newUserSnap.data();

      if (newUserData?['usedReferralCode'] != null) {
        return ReferralApplyResult.alreadyUsed();
      }

      _debugRead('referralCodes/$code');
      final codeSnapshot = await _referralCodeDocument(code).get();
      final codeData = codeSnapshot.data();
      final ownerUid = codeData?['uid'] as String?;
      if (!codeSnapshot.exists) {
        return ReferralApplyResult.notFound(code);
      }

      if (ownerUid == null || ownerUid.isEmpty) {
        return ReferralApplyResult.invalid(code);
      }

      if (ownerUid == newUserUid) return ReferralApplyResult.selfReferral();

      final ownerRef = _userDocument(ownerUid);

      await _firestore.runTransaction((transaction) async {
        _debugRead('users/$newUserUid');
        final newUserSnapshot = await transaction.get(newUserRef);
        final newUserData = newUserSnapshot.data() ?? const <String, dynamic>{};

        if (newUserData['referredBy'] != null ||
            newUserData['usedReferralCode'] != null) {
          return;
        }

        _debugRead('users/$ownerUid');
        final ownerSnapshot = await transaction.get(ownerRef);
        final ownerData = ownerSnapshot.data() ?? const <String, dynamic>{};
        final ownerPieces = (ownerData['puzzlePieces'] as num?)?.toInt() ?? 0;

        transaction.set(newUserRef, {
          'referredBy': ownerUid,
          'usedReferralCode': code,
          'referralAppliedAt': DateTime.now().toUtc().toIso8601String(),
        }, SetOptions(merge: true));

        transaction.set(ownerRef, {
          'puzzlePieces': (ownerPieces + 1).toDouble(),
        }, SetOptions(merge: true));
      });

      return ReferralApplyResult.applied(code, ownerUid);
    } catch (error, stackTrace) {
      _debugFailure('applyReferralCode failed', error, stackTrace);
      rethrow;
    }
  }

  Future<int> getPuzzlePieces() async {
    try {
      final user = _requireUser();
      _debugRead('users/${user.uid}');
      final snapshot = await _userDocument(user.uid).get();
      return (snapshot.data()?['puzzlePieces'] as num?)?.toInt() ?? 0;
    } catch (error, stackTrace) {
      _debugFailure('getPuzzlePieces failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> convertPuzzleToVaultCredit() async {
    try {
      final user = _requireUser();
      final userRef = _userDocument(user.uid);

      await _firestore.runTransaction((transaction) async {
        _debugRead('users/${user.uid}');
        final snapshot = await transaction.get(userRef);
        final data = snapshot.data() ?? const <String, dynamic>{};
        final currentPieces = (data['puzzlePieces'] as num?)?.toInt() ?? 0;
        final currentCredits = (data['vaultCredits'] as num?)?.toInt() ?? 0;

        if (currentPieces < 5) {
          throw StateError(
            'Kasa hakkına çevirmek için 5 puzzle parçası gerekli.',
          );
        }

        transaction.set(userRef, {
          'puzzlePieces': (currentPieces - 5).toDouble(),
          'vaultCredits': (currentCredits + 1).toDouble(),
        }, SetOptions(merge: true));
      });
    } catch (error, stackTrace) {
      _debugFailure('convertPuzzleToVaultCredit failed', error, stackTrace);
      rethrow;
    }
  }

  Future<ReferralProfile> getReferralProfile() async {
    try {
      final user = _requireUser();
      final code = await ensureReferralCode(uid: user.uid);
      _debugRead('users/${user.uid}');
      final snapshot = await _userDocument(user.uid).get();
      final data = snapshot.data() ?? const <String, dynamic>{};

      return ReferralProfile(
        referralCode: code,
        puzzlePieces: (data['puzzlePieces'] as num?)?.toInt() ?? 0,
      );
    } catch (error, stackTrace) {
      _debugFailure('Referral load failed', error, stackTrace);
      rethrow;
    }
  }

  Future<void> _ensureDefaultUserFields(
    DocumentReference<Map<String, dynamic>> userRef,
  ) async {
    _debugRead('users/${userRef.id}');
    final snapshot = await userRef.get();
    final data = snapshot.data() ?? const <String, dynamic>{};

    await userRef.set({
      'puzzlePieces': ((data['puzzlePieces'] as num?) ?? 0).toDouble(),
      'vaultCredits': ((data['vaultCredits'] as num?) ?? 0).toDouble(),
      'hasAllVaults': data['hasAllVaults'] == true,
    }, SetOptions(merge: true));
  }

  String _generateCode({required int length}) {
    return List.generate(length, (_) {
      return _codeCharacters[_random.nextInt(_codeCharacters.length)];
    }).join();
  }

  User _requireUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    return user;
  }

  void _debugRead(String path) {
    debugPrint('READ $path');
  }

  void _debugFailure(String label, Object error, StackTrace stackTrace) {
    debugPrint('$label: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class ReferralProfile {
  const ReferralProfile({
    required this.referralCode,
    required this.puzzlePieces,
  });

  final String referralCode;
  final int puzzlePieces;
}

class ReferralApplyResult {
  const ReferralApplyResult._({required this.status, this.code, this.ownerUid});

  final ReferralApplyStatus status;
  final String? code;
  final String? ownerUid;

  bool get isSuccess => status == ReferralApplyStatus.success;

  static ReferralApplyResult skipped() {
    return const ReferralApplyResult._(status: ReferralApplyStatus.skipped);
  }

  static ReferralApplyResult alreadyUsed() {
    return const ReferralApplyResult._(status: ReferralApplyStatus.alreadyUsed);
  }

  static ReferralApplyResult notFound(String code) {
    return ReferralApplyResult._(
      status: ReferralApplyStatus.notFound,
      code: code,
    );
  }

  static ReferralApplyResult invalid(String code) {
    return ReferralApplyResult._(
      status: ReferralApplyStatus.invalid,
      code: code,
    );
  }

  static ReferralApplyResult selfReferral() {
    return const ReferralApplyResult._(
      status: ReferralApplyStatus.selfReferral,
    );
  }

  static ReferralApplyResult applied(String code, String ownerUid) {
    return ReferralApplyResult._(
      status: ReferralApplyStatus.success,
      code: code,
      ownerUid: ownerUid,
    );
  }
}

enum ReferralApplyStatus {
  skipped,
  alreadyUsed,
  notFound,
  invalid,
  selfReferral,
  success,
}

class _ReferralCodeCollision implements Exception {}
