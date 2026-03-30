enum AppLanguage { english, telugu }

enum RuntimeMode { offline, online }

extension AppLanguageCode on AppLanguage {
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.telugu:
        return 'te';
    }
  }

  static AppLanguage fromCode(String value) {
    return value == 'te' ? AppLanguage.telugu : AppLanguage.english;
  }
}

extension RuntimeModeCode on RuntimeMode {
  String get code {
    switch (this) {
      case RuntimeMode.offline:
        return 'offline';
      case RuntimeMode.online:
        return 'online';
    }
  }

  static RuntimeMode fromCode(String value) {
    return value == 'online' ? RuntimeMode.online : RuntimeMode.offline;
  }
}

class SymptomRule {
  const SymptomRule({
    required this.id,
    required this.triggers,
    required this.summaryEn,
    required this.summaryTe,
    required this.selfCareEn,
    required this.selfCareTe,
    required this.seekCareIfEn,
    required this.seekCareIfTe,
  });

  final String id;
  final List<String> triggers;
  final String summaryEn;
  final String summaryTe;
  final List<String> selfCareEn;
  final List<String> selfCareTe;
  final String seekCareIfEn;
  final String seekCareIfTe;

  factory SymptomRule.fromJson(Map<String, dynamic> json) {
    return SymptomRule(
      id: json['id'] as String,
      triggers: List<String>.from(json['triggers'] as List<dynamic>),
      summaryEn: json['summary_en'] as String,
      summaryTe: json['summary_te'] as String,
      selfCareEn: List<String>.from(json['self_care_en'] as List<dynamic>),
      selfCareTe: List<String>.from(json['self_care_te'] as List<dynamic>),
      seekCareIfEn: json['seek_care_if_en'] as String,
      seekCareIfTe: json['seek_care_if_te'] as String,
    );
  }
}

class RedFlagRule {
  const RedFlagRule({
    required this.id,
    required this.triggers,
    required this.summaryEn,
    required this.summaryTe,
    required this.stepsEn,
    required this.stepsTe,
  });

  final String id;
  final List<String> triggers;
  final String summaryEn;
  final String summaryTe;
  final List<String> stepsEn;
  final List<String> stepsTe;

  factory RedFlagRule.fromJson(Map<String, dynamic> json) {
    return RedFlagRule(
      id: json['id'] as String,
      triggers: List<String>.from(json['triggers'] as List<dynamic>),
      summaryEn: json['summary_en'] as String,
      summaryTe: json['summary_te'] as String,
      stepsEn: List<String>.from(json['steps_en'] as List<dynamic>),
      stepsTe: List<String>.from(json['steps_te'] as List<dynamic>),
    );
  }
}

class AssistantResult {
  const AssistantResult({
    required this.summary,
    required this.steps,
    required this.safetyNote,
    required this.isEmergency,
    required this.usedOnlineEnhancement,
  });

  final String summary;
  final List<String> steps;
  final String safetyNote;
  final bool isEmergency;
  final bool usedOnlineEnhancement;
}

class SessionEntry {
  const SessionEntry({
    required this.query,
    required this.resultSummary,
    required this.language,
    required this.mode,
    required this.isEmergency,
    required this.createdAtIso,
  });

  final String query;
  final String resultSummary;
  final AppLanguage language;
  final RuntimeMode mode;
  final bool isEmergency;
  final String createdAtIso;

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'result_summary': resultSummary,
      'language': language.code,
      'mode': mode.code,
      'is_emergency': isEmergency,
      'created_at_iso': createdAtIso,
    };
  }

  factory SessionEntry.fromJson(Map<String, dynamic> json) {
    return SessionEntry(
      query: json['query'] as String,
      resultSummary: json['result_summary'] as String,
      language: AppLanguageCode.fromCode(json['language'] as String),
      mode: RuntimeModeCode.fromCode(json['mode'] as String),
      isEmergency: json['is_emergency'] as bool,
      createdAtIso: json['created_at_iso'] as String,
    );
  }
}
