import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AccountDeletionService {
  AccountDeletionService({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  Future<void> deleteCurrentUserAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Oturum bulunamadı. Lütfen tekrar giriş yap.');
    }

    await _deleteUserFirestoreData(user.uid);
    await user.delete();
  }

  Future<void> _deleteUserFirestoreData(String uid) async {
    final userRef = _firestore.collection('users').doc(uid);

    await _deleteCollection(userRef.collection('personalityTest'));
    await _deleteCollection(userRef.collection('debug'));
    await _deleteCollection(userRef.collection('unlocked_vaults'));
    await _deleteCollection(userRef.collection('openedVaults'));
    await _deleteCollection(userRef.collection('vault_access'));

    await userRef.delete();
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    const batchSize = 100;

    while (true) {
      final snapshot = await collection.limit(batchSize).get();
      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();

      if (snapshot.docs.length < batchSize) return;
    }
  }
}
