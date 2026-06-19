import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreditService {
  CreditService({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> _userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<int> getCredits() async {
    final user = _requireUser();
    final snapshot = await _userDocument(user.uid).get();
    final data = snapshot.data();
    return (data?['vaultCredits'] as num?)?.toInt() ?? 0;
  }

  Future<bool> hasAllVaults() async {
    final user = _requireUser();
    final snapshot = await _userDocument(user.uid).get();
    final data = snapshot.data();
    return data?['hasAllVaults'] == true;
  }

  Future<void> addCredits(int amount) async {
    if (amount <= 0) {
      throw ArgumentError.value(
        amount,
        'amount',
        'Kredi miktarı pozitif olmalı.',
      );
    }

    final user = _requireUser();
    final userRef = _userDocument(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();
      final currentCredits = (data?['vaultCredits'] as num?)?.toInt() ?? 0;
      final nextCredits = currentCredits + amount;

      transaction.set(userRef, {
        'vaultCredits': nextCredits.toDouble(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> unlockAllVaults() async {
    final user = _requireUser();
    await _userDocument(
      user.uid,
    ).set({'hasAllVaults': true}, SetOptions(merge: true));
  }

  Future<void> consumeOneCredit() async {
    final user = _requireUser();
    final userRef = _userDocument(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final data = snapshot.data();

      if (data?['hasAllVaults'] == true) return;

      final currentCredits = (data?['vaultCredits'] as num?)?.toInt() ?? 0;
      if (currentCredits <= 0) {
        throw StateError('Kasa kredisi bulunamadı.');
      }

      transaction.set(userRef, {
        'vaultCredits': (currentCredits - 1).toDouble(),
      }, SetOptions(merge: true));
    });
  }

  Future<bool> canOpenPaidVault() async {
    if (await hasAllVaults()) return true;
    return await getCredits() > 0;
  }

  User _requireUser() {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    return user;
  }
}
