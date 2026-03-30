import '../../models/assistant_models.dart';
import '../rules/offline_rules_repository.dart';
import '../safety/red_flag_detector.dart';

class AssistantService {
  AssistantService({
    required OfflineRulesRepository rulesRepository,
    required RedFlagDetector redFlagDetector,
  })  : _rulesRepository = rulesRepository,
        _redFlagDetector = redFlagDetector;

  final OfflineRulesRepository _rulesRepository;
  final RedFlagDetector _redFlagDetector;

  Future<AssistantResult> handleQuery({
    required String query,
    required AppLanguage language,
    required RuntimeMode mode,
  }) async {
    final redFlags = await _rulesRepository.loadRedFlagRules();
    final match = _redFlagDetector.detect(query, redFlags);

    if (match != null) {
      return AssistantResult(
        message: _pickText(
          language: language,
          english: 'Emergency signs detected. ${match.escalationEn} This is not a diagnosis.',
          telugu: 'అత్యవసర హెచ్చరిక లక్షణాలు గుర్తించబడ్డాయి. ${match.escalationTe} ఇది నిర్ధారణ కాదు.',
        ),
        isEmergency: true,
        usedOnlineEnhancement: false,
      );
    }

    final symptomRules = await _rulesRepository.loadSymptomRules();
    final normalized = query.toLowerCase();
    SymptomRule? symptomMatch;
    for (final rule in symptomRules) {
      for (final trigger in rule.triggers) {
        if (normalized.contains(trigger.toLowerCase())) {
          symptomMatch = rule;
          break;
        }
      }
      if (symptomMatch != null) {
        break;
      }
    }

    final baseMessage = symptomMatch == null
        ? _pickText(
            language: language,
            english:
                'I could not map this clearly. Please monitor symptoms, stay hydrated, and seek care if worsening. This is not a diagnosis.',
            telugu:
                'ఈ లక్షణాన్ని స్పష్టంగా మ్యాప్ చేయలేకపోయాను. దయచేసి లక్షణాలను గమనించండి, ద్రవాలు తీసుకోండి, ఎక్కువైతే వైద్య సహాయం పొందండి. ఇది నిర్ధారణ కాదు.',
          )
        : _pickText(
            language: language,
            english: '${symptomMatch.guidanceEn} This is not a diagnosis.',
            telugu: '${symptomMatch.guidanceTe} ఇది నిర్ధారణ కాదు.',
          );

    if (mode == RuntimeMode.offline) {
      return AssistantResult(
        message: baseMessage,
        isEmergency: false,
        usedOnlineEnhancement: false,
      );
    }

    return AssistantResult(
      message: _pickText(
        language: language,
        english:
            '$baseMessage\n\nOnline enhancement: If symptoms continue beyond 24-48 hours, consult a doctor.',
        telugu:
            '$baseMessage\n\nఆన్‌లైన్ మెరుగుదల: లక్షణాలు 24-48 గంటలకంటే ఎక్కువగా ఉంటే వైద్యుడిని సంప్రదించండి.',
      ),
      isEmergency: false,
      usedOnlineEnhancement: true,
    );
  }

  String _pickText({
    required AppLanguage language,
    required String english,
    required String telugu,
  }) {
    return language == AppLanguage.telugu ? telugu : english;
  }
}
