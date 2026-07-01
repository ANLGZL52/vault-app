import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../features/vaults/models/vault_result.dart';

const _openRouterEndpoint = 'https://openrouter.ai/api/v1/chat/completions';
const _openRouterModel = 'openai/gpt-4o-mini';
const _openRouterApiKey = String.fromEnvironment('OPENROUTER_API_KEY');

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
  VaultAiService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  Future<VaultAiResponse> generateVaultInsight({
    required int vaultId,
    required String topic,
    required Map<String, dynamic> personalityResult,
  }) async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw const VaultAiServiceException('Devam etmek için giriş yapmalısın.');
    }

    final prompt = _buildUserPrompt(
      topic: topic,
      personalityResult: personalityResult,
    );

    try {
      final response = await http
          .post(
            Uri.parse(_openRouterEndpoint),
            headers: {
              'Authorization': 'Bearer $_openRouterApiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'model': _openRouterModel,
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.85,
              'max_tokens': 1200,
            }),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode != 200) {
        _debugLog('OpenRouter error ${response.statusCode}: ${response.body}');
        throw const VaultAiServiceException(
          'Analiz oluşturulamadı. Lütfen tekrar dene.',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = _readProviderContent(data);
      final insight = _parseInsight(content);
      _ensureNoForbiddenLanguage(content);
      _ensureInsightIsComplete(insight);

      return VaultAiResponse(insight: insight, model: _openRouterModel);
    } on VaultAiServiceException {
      rethrow;
    } catch (error) {
      _debugLog('AI error: $error');
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
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

  String _readProviderContent(Map<String, dynamic> data) {
    final choices = data['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
    final message =
        (choices.first as Map<String, dynamic>)['message'] as Map?;
    final content = message?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
    return content;
  }

  VaultInsight _parseInsight(String content) {
    try {
      return VaultInsight.fromJson(
        Map<String, dynamic>.from(jsonDecode(content) as Map),
      );
    } catch (_) {
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
  }

  void _ensureInsightIsComplete(VaultInsight insight) {
    final values = insight.toJson().values;
    if (values.any((v) => v is! String || (v).trim().isEmpty)) {
      throw const VaultAiServiceException(
        'Analiz oluşturulamadı. Lütfen tekrar dene.',
      );
    }
  }

  void _ensureNoForbiddenLanguage(String content) {
    const forbidden = [
      'emotional',
      'social',
      'curiosity',
      'discipline',
      'interests',
      'skor',
      'puan',
      'test sonucuna göre',
      'kişilik testin gösteriyor',
      'kişilik testi gösteriyor',
      '#',
      '```',
    ];
    final normalized = content.toLowerCase();
    for (final snippet in forbidden) {
      if (normalized.contains(snippet)) {
        throw const VaultAiServiceException(
          'Analiz oluşturulamadı. Lütfen tekrar dene.',
        );
      }
    }
  }

  void _debugLog(String message) {
    if (kDebugMode) debugPrint('[VaultAI] $message');
  }
}

const _systemPrompt = '''
Sen Vault uygulamasının içgörü motorusun.

Amacın bir kişilik testi sonucunu analiz edip kullanıcıya çok spesifik hissettiren içgörüler üretmektir.

Çok önemli:
Kullanıcı kişilik testi çözdüğünü biliyor ancak skorlarını görmek istemiyor.
Skorlardan, kategorilerden veya test sonuçlarından asla bahsetme.

Asla şu tarz ifadeler kullanma:
- skorun yüksek
- skorun düşük
- test sonucuna göre
- kişilik testin gösteriyor ki
- skorların gösteriyor ki
- emotional 30
- social 25
- curiosity yüksek
- discipline düşük
- interests orta
- puanın
- kategori

Girdi içinde görünen teknik isimleri ve sayısal değerleri kullanıcıya gösterme.
Bu verileri görünmez şekilde yorumla ve kişisel gözleme dönüştür.

Cevap kişisel gözlem gibi okunmalı.
Analizler spesifik, insani, doğal ve düşündürücü olmalı.
Her cevapta en az bir tane beklenmedik ama mantıklı içgörü üret.
Generic kişilik testi dili kullanma.

Fal, kehanet, astroloji veya mistik dil kullanma.
Kesin yargılar kullanma.
Psikolojik teşhis koyma.
Terapi, hastalık, bozukluk veya klinik tanı dili kullanma.
Kullanıcıyı manipüle etme.

Şunları doğal biçimde sık kullan:
- muhtemelen
- büyük ihtimalle
- zaman zaman
- farkında olmadan
- insanlar sende şunu görüyor olabilir
- ilk bakışta

Yasaklar:
- liste halinde kategori anlatımı
- test açıklaması
- puan açıklaması
- psikolojik teşhis
- terapi dili
- teknik veri dökümü
- markdown
- # veya ## başlık işareti
- madde işareti
- kod bloğu

Çıktıyı SADECE JSON olarak üret.
JSON dışında tek karakter üretme.
Markdown kullanma.
# kullanma.
## kullanma.
Madde işareti kullanma.
Kod bloğu kullanma.
Açıklama yazma.

JSON formatı tam olarak şu alanlardan oluşmalı:
{
  "title": "",
  "intro": "",
  "howItAppears": "",
  "howPeopleSeeIt": "",
  "watchOut": "",
  "advice": ""
}

Alanların anlamı:
- title: kısa, premium ve kişisel bir başlık
- intro: 2-3 cümlelik giriş
- howItAppears: "Bu sende nasıl görünüyor olabilir?" bölümü için 2 paragraf
- howPeopleSeeIt: "İnsanlar bunu nasıl algılıyor olabilir?" bölümü için 2 paragraf
- watchOut: "Dikkat etmen gereken nokta" bölümü için 1 paragraf
- advice: "Küçük tavsiye" bölümü için 1 paragraf

Maksimum uzunluk: 500-700 kelime.

Amaç:
Kullanıcı okuduğunda "Bu beni gerçekten anlamış." demeli.
''';
