import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/purchase/services/credit_service.dart';
import '../../features/vaults/data/vault_topics.dart';
import '../../features/vaults/models/vault_result.dart';
import '../models/subscription_status.dart';
import 'revenuecat_service.dart';
import 'subscription_service.dart';

class VaultAccessService {
  VaultAccessService({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    SubscriptionService? subscriptionService,
    CreditService? creditService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _subscriptionService =
           subscriptionService ?? SubscriptionService.instance,
       _creditService = creditService ?? CreditService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;
  final SubscriptionService _subscriptionService;
  final CreditService _creditService;

  User? get _currentUser => _firebaseAuth.currentUser;

  DocumentReference<Map<String, dynamic>> _statusDocument(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('vault_access')
        .doc('main');
  }

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  DocumentReference<Map<String, dynamic>> _unlockedVaultDocument({
    required String uid,
    required int vaultId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('unlocked_vaults')
        .doc('$vaultId');
  }

  DocumentReference<Map<String, dynamic>> _openedVaultDocument({
    required String uid,
    required int vaultId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('openedVaults')
        .doc('$vaultId');
  }

  Future<void> refreshAccessFromRevenueCat() async {
    final user = _requireUser();
    await _subscriptionService.refresh();
    final status = _subscriptionService.status;
    final snapshot = await _statusDocument(user.uid).get();
    final existing = snapshot.data() ?? const <String, dynamic>{};
    final usedPurchasedUnlocks =
        (existing['usedPurchasedVaultUnlocks'] as num?)?.toInt() ?? 0;

    await _statusDocument(user.uid).set({
      'freeVaultAllowance': freeVaultLimit.toDouble(),
      'purchasedVaultAllowance': status.purchasedVaultAllowance.toDouble(),
      'usedPurchasedVaultUnlocks': usedPurchasedUnlocks.toDouble(),
      'hasUnlimitedVaults': status.hasUnlimitedVaults,
      'activeProducts': _activeProductIds(status).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    _debugLog(
      'Vault access snapshot refreshed: purchased=${status.purchasedVaultAllowance}, used=$usedPurchasedUnlocks, unlimited=${status.hasUnlimitedVaults}',
    );
  }

  Future<bool> isVaultUnlocked(int vaultId) async {
    final user = _requireUser();
    final unlockedSnapshot = await _unlockedVaultDocument(
      uid: user.uid,
      vaultId: vaultId,
    ).get();
    if (unlockedSnapshot.exists) return true;

    final openedSnapshot = await _openedVaultDocument(
      uid: user.uid,
      vaultId: vaultId,
    ).get();

    return openedSnapshot.exists;
  }

  Future<VaultResult?> getUnlockedVaultResult(int vaultId) async {
    final user = _requireUser();
    final unlockedSnapshot = await _unlockedVaultDocument(
      uid: user.uid,
      vaultId: vaultId,
    ).get();
    final unlockedData = unlockedSnapshot.data();
    if (unlockedSnapshot.exists && unlockedData != null) {
      return VaultResult.fromFirestore(unlockedData);
    }

    final openedSnapshot = await _openedVaultDocument(
      uid: user.uid,
      vaultId: vaultId,
    ).get();
    final openedData = openedSnapshot.data();
    if (!openedSnapshot.exists || openedData == null) return null;

    return VaultResult.fromFirestore(openedData);
  }

  Future<int> getRemainingPurchasedUnlocks() async {
    final user = _requireUser();
    await refreshAccessFromRevenueCat();
    final snapshot = await _statusDocument(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final allowance = (data['purchasedVaultAllowance'] as num?)?.toInt() ?? 0;
    final used = (data['usedPurchasedVaultUnlocks'] as num?)?.toInt() ?? 0;
    return (allowance - used).clamp(0, allowance).toInt();
  }

  Future<bool> canOpenVault(int vaultId) async {
    final user = _requireUser();
    if (await isVaultUnlocked(vaultId)) return true;
    if (isVaultFree(vaultId)) return true;

    if (await _creditService.canOpenPaidVault()) return true;

    try {
      await refreshAccessFromRevenueCat();
    } catch (error) {
      _debugLog('RevenueCat access refresh skipped: $error');
    }

    final snapshot = await _statusDocument(user.uid).get();
    final data = snapshot.data() ?? const <String, dynamic>{};
    final hasUnlimitedVaults = data['hasUnlimitedVaults'] == true;
    if (hasUnlimitedVaults) return true;

    final allowance = (data['purchasedVaultAllowance'] as num?)?.toInt() ?? 0;
    final used = (data['usedPurchasedVaultUnlocks'] as num?)?.toInt() ?? 0;
    return allowance - used > 0;
  }

  Future<VaultResult> markVaultUnlocked({
    required int vaultId,
    required String topic,
    required VaultInsight insight,
    required String model,
    required Map<String, dynamic> personalitySnapshot,
  }) async {
    final user = _requireUser();
    try {
      await refreshAccessFromRevenueCat();
    } catch (error) {
      _debugLog('RevenueCat access refresh skipped: $error');
    }

    final userRef = _userDocument(user.uid);
    final statusRef = _statusDocument(user.uid);
    final vaultRef = _unlockedVaultDocument(uid: user.uid, vaultId: vaultId);
    final openedVaultRef = _openedVaultDocument(
      uid: user.uid,
      vaultId: vaultId,
    );

    final payload = await _firestore.runTransaction<Map<String, dynamic>>((
      transaction,
    ) async {
      final existingVault = await transaction.get(vaultRef);
      final existingVaultData = existingVault.data();
      if (existingVault.exists && existingVaultData != null) {
        _debugLog('Vault $vaultId already unlocked; allowance not consumed.');
        return existingVaultData;
      }

      final existingOpenedVault = await transaction.get(openedVaultRef);
      final existingOpenedVaultData = existingOpenedVault.data();
      if (existingOpenedVault.exists && existingOpenedVaultData != null) {
        _debugLog(
          'Vault $vaultId already exists in openedVaults; credit not consumed.',
        );
        return existingOpenedVaultData;
      }

      final userSnapshot = await transaction.get(userRef);
      final userData = userSnapshot.data() ?? const <String, dynamic>{};
      final statusSnapshot = await transaction.get(statusRef);
      final statusData = statusSnapshot.data() ?? const <String, dynamic>{};
      final hasAllVaults = userData['hasAllVaults'] == true;
      final hasUnlimitedVaults =
          hasAllVaults || statusData['hasUnlimitedVaults'] == true;
      final vaultCredits = (userData['vaultCredits'] as num?)?.toInt() ?? 0;
      final allowance =
          (statusData['purchasedVaultAllowance'] as num?)?.toInt() ?? 0;
      final used =
          (statusData['usedPurchasedVaultUnlocks'] as num?)?.toInt() ?? 0;

      final unlockType = _resolveUnlockType(
        vaultId: vaultId,
        hasUnlimitedVaults: hasUnlimitedVaults,
        vaultCredits: vaultCredits,
        remainingPurchasedUnlocks: allowance - used,
      );
      if (unlockType == null) {
        throw StateError('Bu kasayı açmak için kasa kredisi gerekiyor.');
      }

      final content = insight.toJson();
      final data = <String, dynamic>{
        'vaultId': '$vaultId',
        'unlockType': unlockType,
        'productSource': _productSource(
          unlockType: unlockType,
          activeProducts: List<String>.from(
            statusData['activeProducts'] as List? ?? const [],
          ),
        ),
        'openedAt': FieldValue.serverTimestamp(),
        'result': jsonEncode(content),
        'title': insight.title,
        'topic': topic,
        'content': content,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'model': model,
        'personalitySnapshot': personalitySnapshot,
      };

      transaction.set(vaultRef, data);
      transaction.set(openedVaultRef, data);

      if (unlockType == 'credit') {
        transaction.set(userRef, {
          'vaultCredits': (vaultCredits - 1).clamp(0, vaultCredits).toDouble(),
        }, SetOptions(merge: true));
      } else if (unlockType == 'purchased') {
        transaction.set(statusRef, {
          'usedPurchasedVaultUnlocks': (used + 1).toDouble(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return data;
    });

    return VaultResult.fromFirestore(payload);
  }

  User _requireUser() {
    final user = _currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    return user;
  }

  String? _resolveUnlockType({
    required int vaultId,
    required bool hasUnlimitedVaults,
    required int vaultCredits,
    required int remainingPurchasedUnlocks,
  }) {
    if (isVaultFree(vaultId)) return 'free';
    if (hasUnlimitedVaults) return 'unlimited';
    if (vaultCredits > 0) return 'credit';
    if (remainingPurchasedUnlocks > 0) return 'purchased';
    return null;
  }

  String? _productSource({
    required String unlockType,
    required List<String> activeProducts,
  }) {
    if (unlockType == 'free') return null;
    if (unlockType == 'unlimited') return RevenueCatService.productAllVaults;
    if (unlockType == 'credit') return 'vaultCredits';

    if (activeProducts.contains(RevenueCatService.productFiveVaults)) {
      return RevenueCatService.productFiveVaults;
    }
    if (activeProducts.contains(RevenueCatService.productThreeVaults)) {
      return RevenueCatService.productThreeVaults;
    }

    return 'package_allowance';
  }

  Iterable<String> _activeProductIds(SubscriptionStatus status) {
    return status.activeProducts.map((product) {
      return switch (product) {
        VaultPurchaseProduct.threeVaults =>
          RevenueCatService.productThreeVaults,
        VaultPurchaseProduct.fiveVaults => RevenueCatService.productFiveVaults,
        VaultPurchaseProduct.allVaults => RevenueCatService.productAllVaults,
      };
    });
  }

  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('[VaultAccess] $message');
    }
  }
}
