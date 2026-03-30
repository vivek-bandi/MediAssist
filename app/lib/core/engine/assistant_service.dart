import '../../models/assistant_models.dart';
import '../online/groq_online_adapter.dart';
import '../rules/offline_rules_repository.dart';
import '../safety/red_flag_detector.dart';
import '../storage/session_history_repository.dart';

class AssistantService {
  AssistantService({
    required OfflineRulesRepository rulesRepository,
    required RedFlagDetector redFlagDetector,
    required SessionHistoryRepository historyRepository,
    GroqOnlineAdapter? onlineAdapter,
  })  : _rulesRepository = rulesRepository,
        _redFlagDetector = redFlagDetector,
        _historyRepository = historyRepository,
        _onlineAdapter = onlineAdapter;

  final OfflineRulesRepository _rulesRepository;
  final RedFlagDetector _redFlagDetector;
  final SessionHistoryRepository _historyRepository;
  final GroqOnlineAdapter? _onlineAdapter;

  bool get isOnlineConfigured => _onlineAdapter?.isConfigured ?? false;

  Future<List<SessionEntry>> loadHistory() {
    return _historyRepository.loadHistory();
  }

  Future<AssistantResult> handleQuery({
    required String query,
    required AppLanguage language,
    required RuntimeMode mode,
  }) async {
    final redFlags = await _rulesRepository.loadRedFlagRules();
    final match = _redFlagDetector.detect(query, redFlags);

    if (match != null) {
      final result = AssistantResult(
        summary: _polishSummary(
          language: language,
          summary: _pickText(
            language: language,
            english: match.summaryEn,
            telugu: match.summaryTe,
          ),
          isEmergency: true,
        ),
        steps: _finalizeSteps(
          language: language,
          rawSteps: _pickList(
            language: language,
            english: match.stepsEn,
            telugu: match.stepsTe,
          ),
          ensureDoctorTip: false,
        ),
        safetyNote: _pickText(
          language: language,
          english: 'This is emergency guidance only, not a diagnosis.',
          telugu: 'ఇది అత్యవసర మార్గదర్శకం మాత్రమే, ఇది నిర్ధారణ కాదు.',
        ),
        isEmergency: true,
        usedOnlineEnhancement: false,
      );

      await _historyRepository.addEntry(
        SessionEntry(
          query: query,
          resultSummary: result.summary,
          language: language,
          mode: mode,
          isEmergency: true,
          createdAtIso: DateTime.now().toIso8601String(),
        ),
      );

      return result;
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

    final summary = symptomMatch == null
        ? _pickText(
            language: language,
            english:
                'Symptoms are not clearly mapped to a known low-risk pattern.',
            telugu:
                'లక్షణాలు తెలిసిన తక్కువ ప్రమాద నమూనాతో స్పష్టంగా సరిపోలలేదు.',
          )
        : _pickText(
            language: language,
            english: symptomMatch.summaryEn,
            telugu: symptomMatch.summaryTe,
          );

    final steps = symptomMatch == null
        ? _pickList(
            language: language,
            english: const [
              'Monitor symptoms every 6 hours.',
              'Drink clean fluids and rest.',
              'Seek medical care if symptoms worsen.',
            ],
            telugu: const [
              'ప్రతి 6 గంటలకు లక్షణాలను గమనించండి.',
              'శుభ్రమైన ద్రవాలు తీసుకుని విశ్రాంతి తీసుకోండి.',
              'లక్షణాలు పెరిగితే వైద్య సహాయం పొందండి.',
            ],
          )
        : _pickList(
            language: language,
            english: symptomMatch.selfCareEn,
            telugu: symptomMatch.selfCareTe,
          );

    final seekCareIf = symptomMatch == null
        ? _pickText(
            language: language,
            english:
                'Get urgent help if chest pain, severe breathing trouble, heavy bleeding, or unconsciousness occurs.',
            telugu:
                'ఛాతి నొప్పి, తీవ్రమైన శ్వాస ఇబ్బంది, తీవ్రమైన రక్తస్రావం లేదా స్పృహ కోల్పోవడం ఉంటే వెంటనే సహాయం పొందండి.',
          )
        : _pickText(
            language: language,
            english: symptomMatch.seekCareIfEn,
            telugu: symptomMatch.seekCareIfTe,
          );

    final safetyNote = _pickText(
      language: language,
      english: 'This is basic guidance and not a diagnosis.',
      telugu: 'ఇది ప్రాథమిక మార్గదర్శకం మాత్రమే, ఇది నిర్ధారణ కాదు.',
    );

    if (mode == RuntimeMode.offline) {
      final result = AssistantResult(
        summary: _polishSummary(
          language: language,
          summary: summary,
          isEmergency: false,
        ),
        steps: _finalizeSteps(
          language: language,
          rawSteps: [...steps, seekCareIf],
          ensureDoctorTip: true,
        ),
        safetyNote: safetyNote,
        isEmergency: false,
        usedOnlineEnhancement: false,
      );

      await _historyRepository.addEntry(
        SessionEntry(
          query: query,
          resultSummary: result.summary,
          language: language,
          mode: mode,
          isEmergency: false,
          createdAtIso: DateTime.now().toIso8601String(),
        ),
      );

      return result;
    }

    final onlineResult = await _onlineAdapter?.fetchEnrichedTips(
        query: query,
        language: language,
        baselineSummary: summary,
      ) ??
      const OnlineFetchResult(status: OnlineFetchStatus.notConfigured);

    final usedOnline =
      onlineResult.status == OnlineFetchStatus.success && onlineResult.tips.isNotEmpty;

    final offlineFallbackMessage = switch (onlineResult.status) {
      OnlineFetchStatus.rateLimited => _pickText(
        language: language,
        english:
          'Online service is rate-limited right now (429). Using offline-safe guidance. Try online mode again in a few minutes; consult a doctor if symptoms continue beyond 24-48 hours.',
        telugu:
          'ప్రస్తుతం ఆన్‌లైన్ సేవకు రేట్-లిమిట్ (429) ఉంది. ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం ఉపయోగించబడుతోంది. కొన్ని నిమిషాల తర్వాత మళ్లీ ప్రయత్నించండి; లక్షణాలు 24-48 గంటలకంటే ఎక్కువగా ఉంటే వైద్యుడిని సంప్రదించండి.',
      ),
      OnlineFetchStatus.notConfigured => _pickText(
        language: language,
        english:
          'Online mode is not configured (missing GROQ_API_KEY). Using offline-safe guidance.',
        telugu:
          'ఆన్‌లైన్ మోడ్ కాన్ఫిగర్ కాలేదు (GROQ_API_KEY లేదు). ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం ఉపయోగించబడుతోంది.',
      ),
      _ => _pickText(
        language: language,
        english:
          'Online enrichment unavailable. Using offline-safe guidance. If symptoms continue beyond 24-48 hours, consult a doctor.',
        telugu:
          'ఆన్‌లైన్ మెరుగుదల అందుబాటులో లేదు. ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం ఉపయోగించబడుతోంది. లక్షణాలు 24-48 గంటలకంటే ఎక్కువగా ఉంటే వైద్యుడిని సంప్రదించండి.',
      ),
    };

    final result = AssistantResult(
      summary: _polishSummary(
        language: language,
        summary: usedOnline
            ? (onlineResult.summary ??
                _pickText(
                  language: language,
                  english: 'Online guidance generated for your symptoms.',
                  telugu: 'మీ లక్షణాల కోసం ఆన్‌లైన్ మార్గదర్శకం రూపొందించబడింది.',
                ))
            : summary,
        isEmergency: false,
      ),
      steps: _finalizeSteps(
        language: language,
        rawSteps: [
          if (usedOnline) ...onlineResult.tips,
          if (!usedOnline) ...steps,
          if (!usedOnline) seekCareIf,
          if (!usedOnline) offlineFallbackMessage,
        ],
        ensureDoctorTip: true,
      ),
      safetyNote: safetyNote,
      isEmergency: false,
      usedOnlineEnhancement: usedOnline,
    );

    await _historyRepository.addEntry(
      SessionEntry(
        query: query,
        resultSummary: result.summary,
        language: language,
        mode: mode,
        isEmergency: false,
        createdAtIso: DateTime.now().toIso8601String(),
      ),
    );

    return result;
  }

  String _pickText({
    required AppLanguage language,
    required String english,
    required String telugu,
  }) {
    return language == AppLanguage.telugu ? telugu : english;
  }

  List<String> _pickList({
    required AppLanguage language,
    required List<String> english,
    required List<String> telugu,
  }) {
    return language == AppLanguage.telugu ? telugu : english;
  }

  String _polishSummary({
    required AppLanguage language,
    required String summary,
    required bool isEmergency,
  }) {
    final cleaned = _normalizeSentence(summary);
    if (cleaned.isEmpty || isEmergency) {
      return cleaned;
    }

    if (language == AppLanguage.english) {
      final normalized = cleaned.toLowerCase();
      final alreadyHedged = normalized.contains('may ') ||
          normalized.contains('might ') ||
          normalized.contains('could ') ||
          normalized.contains('possible') ||
          normalized.contains('suggest');
      if (alreadyHedged) {
        return cleaned;
      }

      final lowerStart = cleaned[0].toLowerCase() + cleaned.substring(1);
      return _normalizeSentence('You may have symptoms related to $lowerStart');
    }

    if (cleaned.contains('ఉండవచ్చు') || cleaned.contains('సూచ')) {
      return cleaned;
    }
    return _normalizeSentence('మీ లక్షణాలు $cleaned అని సూచించవచ్చు');
  }

  List<String> _finalizeSteps({
    required AppLanguage language,
    required List<String> rawSteps,
    required bool ensureDoctorTip,
  }) {
    final unique = <String>[];
    for (final step in rawSteps) {
      final cleaned = _normalizeSentence(step);
      if (cleaned.isEmpty) {
        continue;
      }

      final exists = unique.any(
        (item) => item.toLowerCase() == cleaned.toLowerCase(),
      );
      if (!exists) {
        unique.add(cleaned);
      }
    }

    if (ensureDoctorTip) {
      final doctorTip = _doctorConsultTip(language);
      final hasDoctorTip = unique.any(
        (item) {
          final lower = item.toLowerCase();
          return lower.contains('doctor') || lower.contains('వైద్య');
        },
      );
      if (!hasDoctorTip) {
        unique.add(doctorTip);
      }
    }

    return unique;
  }

  String _doctorConsultTip(AppLanguage language) {
    return language == AppLanguage.telugu
        ? 'లక్షణాలు కొనసాగితే లేదా పెరిగితే వైద్యుడిని సంప్రదించండి.'
        : 'Consult a doctor if symptoms continue or worsen.';
  }

  String _normalizeSentence(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return compact;
    }

    final startsWithLetter = RegExp(r'^[A-Za-z]').hasMatch(compact);
    final capitalized = startsWithLetter
        ? compact[0].toUpperCase() + compact.substring(1)
        : compact;

    if (RegExp(r'[.!?]$').hasMatch(capitalized)) {
      return capitalized;
    }
    return '$capitalized.';
  }
}
