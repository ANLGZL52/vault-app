import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../features/vaults/models/vault_result.dart';

const vaultAnalysisFunctionName = 'generateVaultAnalysis';
const vaultAnalysisFunctionRegion = 'us-central1';

class VaultAiServiceException implements Exception {
  const VaultAiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class VaultAiResponse {
  const VaultAiResponse({required this.insight, required this.model});

  final VaultInsight insight;
  final String model;
}

class VaultAiService {
  VaultAiService({FirebaseAuth? firebaseAuth, FirebaseFunctions? functions})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: vaultAnalysisFunctionRegion);

  final FirebaseAuth _firebaseAuth;
  final FirebaseFunctions _functions;

  Future<VaultAiResponse> generateVaultInsight({
    required int vaultId,
    required String topic,
    required Map<String, dynamic> personalityResult,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const VaultAiServiceException('Devam etmek için giriş yapmalısın.');
    }

    _debugLog('STEP 3: Firebase user authenticated');
    _debugLog('uid: ${user.uid}');
    _debugLog('email: ${user.email}');

    final prompt = _buildUserPrompt(
      topic: topic,
      personalityResult: personalityResult,
    );

    final payload = <String, dynamic>{
      'vaultId': '$vaultId',
      'prompt': prompt,
      'userId': user.uid,
      'metadata': {
        'topic': topic,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      },
    };

    await debugAiGeneration(vaultId: vaultId, payload: payload);

    try {
      _debugLog('STEP 4: Cloud Function request started');
      _debugLog('function name: $vaultAnalysisFunctionName');
      _debugLog('payload size: ${jsonEncode(payload).length}');
      _debugLog('vault id: $vaultId');
      await _debugCallableAuthState();

      final callable = _functions.httpsCallable(
        vaultAnalysisFunctionName,
        options: HttpsCallableOptions(timeout: const Duration(seconds: 90)),
      );
      final response = await callable.call<Map<String, dynamic>>(payload);

      _debugLog('STEP 5: Cloud Function response received');
      _debugLog('success: true');
      _debugLog('response size: ${jsonEncode(response.data).length}');

      final content = response.data['content'];
      if (content is! Map) {
        throw const VaultAiServiceException(
          'Analiz oluşturulamadı. Lütfen tekrar dene.',
        );
      }

      final insight = VaultInsight.fromJson(Map<String, dynamic>.from(content));
      _ensureInsightIsComplete(insight);

      final model = response.data['model'];
      return VaultAiResponse(
        insight: insight,
        model: model is String && model.trim().isNotEmpty ? model : 'unknown',
      );
    } on VaultAiServiceException catch (error, stackTrace) {
      _debugLog('VaultAiServiceException: $error');
      _debugStack(stackTrace);
      rethrow;
    } on FirebaseFunctionsException catch (error, stackTrace) {
      _debugLog('FirebaseFunctionsException code: ${error.code}');
      _debugLog('FirebaseFunctionsException message: ${error.message}');
      _debugLog('FirebaseFunctionsException details: ${error.details}');
      _debugStack(stackTrace);
      throw VaultAiServiceException(_messageForFunctionsError(error));
    } catch (error, stackTrace) {
      _debugLog('Unexpected AI generation error: $error');
      _debugStack(stackTrace);
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> debugAiGeneration({
    int? vaultId,
    Map<String, dynamic>? payload,
  }) async {
    if (!kDebugMode) return;

    final user = _firebaseAuth.currentUser;
    _debugLog('--- AI generation debug ---');
    _debugLog('auth status: ${user == null ? 'signed-out' : 'signed-in'}');
    _debugLog('current uid: ${user?.uid}');
    _debugLog('function endpoint: $vaultAnalysisFunctionName');
    _debugLog('function region: $vaultAnalysisFunctionRegion');
    _debugLog('platform: ${kIsWeb ? 'web' : defaultTargetPlatform.name}');
    _debugLog('vault id: ${vaultId ?? 'unknown'}');
    _debugLog(
      'request payload: ${payload == null ? 'unavailable' : jsonEncode(payload)}',
    );
  }

  static String _buildUserPrompt({
    required String topic,
    required Map<String, dynamic> personalityResult,
  }) {
    final hiddenSignals = {
      'numericPatterns': personalityResult['scores'] ?? const {},
      'behavioralLevels': personalityResult['levels'] ?? const {},
      'localizedLevelHints': personalityResult['displayLevels'] ?? const {},
      'answerPattern': personalityResult['answers'] ?? const {},
    };

    return '''
Kasa konusu:
$topic

Görünmez analiz sinyalleri:
${jsonEncode(hiddenSignals)}

Bu sinyalleri kullanıcıya göstermeden, puanlardan veya kategori isimlerinden söz etmeden, sadece doğal gözleme dönüştür.
Bu kullanıcı için kasa konusuna özel, beklenmedik ama mantıklı en az bir içgörü içeren kişisel analiz üret.
''';
  }

  void _ensureInsightIsComplete(VaultInsight insight) {
    final values = insight.toJson().values;
    if (values.any((value) => value is! String || value.trim().isEmpty)) {
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
  }

  Future<void> _debugCallableAuthState() async {
    if (!kDebugMode) return;

    final injectedUser = _firebaseAuth.currentUser;
    final defaultUser = FirebaseAuth.instance.currentUser;
    _debugLog('CALLABLE AUTH DEBUG');
    _debugLog('injected FirebaseAuth uid: ${injectedUser?.uid}');
    _debugLog('FirebaseAuth.instance uid: ${defaultUser?.uid}');
    _debugLog('FirebaseAuth.instance email: ${defaultUser?.email}');
    _debugLog(
      'auth users match: ${injectedUser?.uid != null && injectedUser?.uid == defaultUser?.uid}',
    );

    try {
      final idToken = await defaultUser?.getIdToken(true);
      _debugLog('ID token generated: ${idToken != null && idToken.isNotEmpty}');
      _debugLog('ID token length: ${idToken?.length ?? 0}');
      _debugIdTokenClaims(idToken);
    } on FirebaseAuthException catch (error, stackTrace) {
      _debugLog('ID token FirebaseAuthException code: ${error.code}');
      _debugLog('ID token FirebaseAuthException message: ${error.message}');
      _debugStack(stackTrace);
    } catch (error, stackTrace) {
      _debugLog('ID token generation failed: $error');
      _debugStack(stackTrace);
    }
  }

  void _debugIdTokenClaims(String? idToken) {
    if (idToken == null || idToken.isEmpty) return;

    try {
      final segments = idToken.split('.');
      if (segments.length != 3) {
        _debugLog('ID token has unexpected segment count: ${segments.length}');
        return;
      }

      final payloadJson = utf8.decode(
        base64Url.decode(base64Url.normalize(segments[1])),
      );
      final claims = jsonDecode(payloadJson);
      if (claims is! Map<String, dynamic>) {
        _debugLog('ID token claims are not a JSON object.');
        return;
      }

      final firebaseClaim = claims['firebase'];
      _debugLog('ID token aud: ${claims['aud']}');
      _debugLog('ID token iss: ${claims['iss']}');
      _debugLog('ID token sub: ${claims['sub']}');
      _debugLog('ID token email: ${claims['email']}');
      _debugLog(
        'ID token sign_in_provider: ${firebaseClaim is Map ? firebaseClaim['sign_in_provider'] : null}',
      );
    } catch (error, stackTrace) {
      _debugLog('ID token claim decode failed: $error');
      _debugStack(stackTrace);
    }
  }

  String _messageForFunctionsError(FirebaseFunctionsException error) {
    if (error.code == 'unauthenticated') {
      return 'Devam etmek için giriş yapmalısın.';
    }

    if (error.code == 'resource-exhausted') {
      return error.message?.trim().isNotEmpty == true
          ? error.message!
          : 'Kullanım limitine ulaştın. Lütfen daha sonra tekrar dene.';
    }

    return 'Analiz oluşturulamadı. Lütfen tekrar dene.';
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
