class VaultInsight {
  const VaultInsight({
    required this.title,
    required this.intro,
    required this.howItAppears,
    required this.howPeopleSeeIt,
    required this.watchOut,
    required this.advice,
  });

  final String title;
  final String intro;
  final String howItAppears;
  final String howPeopleSeeIt;
  final String watchOut;
  final String advice;

  factory VaultInsight.fromJson(Map<String, dynamic> json) {
    return VaultInsight(
      title: json['title'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      howItAppears: json['howItAppears'] as String? ?? '',
      howPeopleSeeIt: json['howPeopleSeeIt'] as String? ?? '',
      watchOut: json['watchOut'] as String? ?? '',
      advice: json['advice'] as String? ?? '',
    );
  }

  factory VaultInsight.fromLegacyContent(String content) {
    return VaultInsight(
      title: 'Kasa İçgörün',
      intro: _cleanLegacyMarkdown(content),
      howItAppears: '',
      howPeopleSeeIt: '',
      watchOut: '',
      advice: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'intro': intro,
      'howItAppears': howItAppears,
      'howPeopleSeeIt': howPeopleSeeIt,
      'watchOut': watchOut,
      'advice': advice,
    };
  }
}

String _cleanLegacyMarkdown(String content) {
  return content
      .replaceAll(RegExp(r'```[\s\S]*?```'), '')
      .replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '')
      .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
      .trim();
}

class VaultResult {
  const VaultResult({
    required this.vaultId,
    required this.topic,
    required this.insight,
    required this.createdAt,
    required this.model,
    required this.personalitySnapshot,
  });

  final int vaultId;
  final String topic;
  final VaultInsight insight;
  final String createdAt;
  final String model;
  final Map<String, dynamic> personalitySnapshot;

  factory VaultResult.fromFirestore(Map<String, dynamic> data) {
    final rawVaultId = data['vaultId'];
    final rawContent = data['content'];

    return VaultResult(
      vaultId: switch (rawVaultId) {
        num value => value.toInt(),
        String value => int.tryParse(value) ?? 0,
        _ => 0,
      },
      topic: data['topic'] as String? ?? '',
      insight: switch (rawContent) {
        Map value => VaultInsight.fromJson(Map<String, dynamic>.from(value)),
        String value => VaultInsight.fromLegacyContent(value),
        _ => const VaultInsight(
          title: '',
          intro: '',
          howItAppears: '',
          howPeopleSeeIt: '',
          watchOut: '',
          advice: '',
        ),
      },
      createdAt: data['createdAt'] as String? ?? '',
      model: data['model'] as String? ?? '',
      personalitySnapshot: Map<String, dynamic>.from(
        data['personalitySnapshot'] as Map? ?? const {},
      ),
    );
  }
}
