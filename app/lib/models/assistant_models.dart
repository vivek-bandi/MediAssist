enum AppLanguage { english, telugu }

enum RuntimeMode { offline, online }

class SymptomRule {
  const SymptomRule({
    required this.id,
    required this.triggers,
    required this.guidanceEn,
    required this.guidanceTe,
  });

  final String id;
  final List<String> triggers;
  final String guidanceEn;
  final String guidanceTe;

  factory SymptomRule.fromJson(Map<String, dynamic> json) {
    return SymptomRule(
      id: json['id'] as String,
      triggers: List<String>.from(json['triggers'] as List<dynamic>),
      guidanceEn: json['guidance_en'] as String,
      guidanceTe: json['guidance_te'] as String,
    );
  }
}

class RedFlagRule {
  const RedFlagRule({
    required this.id,
    required this.triggers,
    required this.escalationEn,
    required this.escalationTe,
  });

  final String id;
  final List<String> triggers;
  final String escalationEn;
  final String escalationTe;

  factory RedFlagRule.fromJson(Map<String, dynamic> json) {
    return RedFlagRule(
      id: json['id'] as String,
      triggers: List<String>.from(json['triggers'] as List<dynamic>),
      escalationEn: json['escalation_en'] as String,
      escalationTe: json['escalation_te'] as String,
    );
  }
}

class AssistantResult {
  const AssistantResult({
    required this.message,
    required this.isEmergency,
    required this.usedOnlineEnhancement,
  });

  final String message;
  final bool isEmergency;
  final bool usedOnlineEnhancement;
}
