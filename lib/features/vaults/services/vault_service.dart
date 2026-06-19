import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/vault_access_service.dart';
import '../../../core/services/vault_ai_service.dart';
import '../data/vault_topics.dart';
import '../models/vault_result.dart';

class VaultService {
  VaultService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    VaultAiService? vaultAiService,
    VaultAccessService? vaultAccessService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _vaultAiService = vaultAiService ?? VaultAiService(),
       _vaultAccessService = vaultAccessService ?? VaultAccessService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final VaultAiService _vaultAiService;
  final VaultAccessService _vaultAccessService;

  User? get currentUser => _firebaseAuth.currentUser;

  DocumentReference<Map<String, dynamic>> _personalityResultDocument(
    String uid,
  ) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('personalityTest')
        .doc('result');
  }

  Future<VaultResult?> getOpenedVault(int vaultId) async {
    return _vaultAccessService.getUnlockedVaultResult(vaultId);
  }

  Future<bool> canOpenVault(int vaultId) async {
    return _vaultAccessService.canOpenVault(vaultId);
  }

  Future<VaultResult> openVault(int vaultId) async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    _debugLog('STEP 3: Firebase user authenticated');
    _debugLog('uid: ${user.uid}');
    _debugLog('email: ${user.email}');

    final topic = vaultTopics[vaultId];
    if (topic == null) {
      throw StateError('Kasa bulunamadı.');
    }

    final openedVault = await getOpenedVault(vaultId);
    if (openedVault != null) return openedVault;

    try {
      final canOpen = await _vaultAccessService.canOpenVault(vaultId);
      if (!canOpen) {
        throw StateError('Bu kasayı açmak için kasa kredisi gerekiyor.');
      }

      final personalityResult = await getPersonalityResult();
      final aiResponse = await _vaultAiService.generateVaultInsight(
        vaultId: vaultId,
        topic: topic,
        personalityResult: personalityResult,
      );

      final personalitySnapshot = <String, dynamic>{
        'scores': _numericMapAsDouble(personalityResult['scores']),
        'levels': _stringMap(personalityResult['levels']),
        'displayLevels': _stringMap(personalityResult['displayLevels']),
      };

      final result = await _vaultAccessService.markVaultUnlocked(
        vaultId: vaultId,
        topic: topic,
        insight: aiResponse.insight,
        model: aiResponse.model,
        personalitySnapshot: personalitySnapshot,
      );

      _debugLog('STEP 6: AI result saved');
      _debugLog('firestore document id: $vaultId');
      _debugLog('saved successfully: true');

      return result;
    } catch (error, stackTrace) {
      _debugLog('VaultService.openVault failed: $error');
      _debugStack(stackTrace);
      rethrow;
    }
  }

  Future<int> getOpenedVaultCount() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('unlocked_vaults')
        .get();

    return snapshot.docs.length;
  }

  Future<Set<int>> getOpenedVaultIds() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('unlocked_vaults')
        .get();

    return snapshot.docs
        .map((document) => int.tryParse(document.id))
        .whereType<int>()
        .toSet();
  }

  Future<Map<String, dynamic>> getPersonalityResult() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    final snapshot = await _personalityResultDocument(user.uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null || data['completed'] != true) {
      throw StateError('Kişilik testi sonucu bulunamadı.');
    }

    return Map<String, dynamic>.from(data);
  }

  Map<String, double> _numericMapAsDouble(Object? value) {
    if (value is! Map) return const {};

    return value.map((key, mapValue) {
      final numericValue = mapValue is num ? mapValue.toDouble() : 0.0;
      return MapEntry('$key', numericValue);
    });
  }

  Map<String, String> _stringMap(Object? value) {
    if (value is! Map) return const {};

    return value.map((key, mapValue) => MapEntry('$key', '$mapValue'));
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[VaultAI] $message');
    }
  }

  void _debugStack(StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
