import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../features/referrals/services/referral_service.dart';

class AuthService {
  AuthService({this.firebaseAuth, this.referralService});

  final FirebaseAuth? firebaseAuth;
  final ReferralService? referralService;

  FirebaseAuth get _auth => firebaseAuth ?? FirebaseAuth.instance;

  ReferralService get _referrals => referralService ?? ReferralService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    String? referralCode,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());

    final user = credential.user;
    if (user == null) {
      throw Exception('Kullanıcı oluşturulamadı.');
    }

    await _referrals.ensureUserDocument(
      uid: user.uid,
      name: name,
      email: email,
    );
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'acceptedPrivacyPolicy': true,
      'acceptedTermsOfUse': true,
      'acceptedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _referrals.ensureReferralCode(uid: user.uid);

    final normalizedReferralCode = referralCode?.trim().toUpperCase() ?? '';
    if (normalizedReferralCode.isEmpty) return null;

    try {
      final result = await _referrals.applyReferralCode(
        newUserUid: user.uid,
        rawCode: normalizedReferralCode,
      );

      return switch (result.status) {
        ReferralApplyStatus.success => null,
        ReferralApplyStatus.notFound =>
          'Referans kodu bulunamadı, kayıt tamamlandı.',
        ReferralApplyStatus.invalid =>
          'Referans kodu geçersiz, kayıt tamamlandı.',
        ReferralApplyStatus.selfReferral =>
          'Kendi referans kodunu kullanamazsın, kayıt tamamlandı.',
        ReferralApplyStatus.alreadyUsed => null,
        ReferralApplyStatus.skipped => null,
      };
    } catch (_) {
      return 'Referans kodu işlenemedi, kayıt tamamlandı.';
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
