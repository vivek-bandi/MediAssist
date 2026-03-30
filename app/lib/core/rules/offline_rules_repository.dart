import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/assistant_models.dart';

class OfflineRulesRepository {
  List<SymptomRule>? _symptomRulesCache;
  List<RedFlagRule>? _redFlagRulesCache;

  Future<void> preloadRules() async {
    await Future.wait([
      loadSymptomRules(),
      loadRedFlagRules(),
    ]);
  }

  Future<List<SymptomRule>> loadSymptomRules() async {
    final cached = _symptomRulesCache;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString('assets/rules/symptom_rules.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final rules = parsed['rules'] as List<dynamic>;
    final loaded = rules
        .map((item) => SymptomRule.fromJson(item as Map<String, dynamic>))
        .toList();
    _symptomRulesCache = loaded;
    return loaded;
  }

  Future<List<RedFlagRule>> loadRedFlagRules() async {
    final cached = _redFlagRulesCache;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString('assets/rules/red_flag_rules.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final rules = parsed['rules'] as List<dynamic>;
    final loaded = rules
        .map((item) => RedFlagRule.fromJson(item as Map<String, dynamic>))
        .toList();
    _redFlagRulesCache = loaded;
    return loaded;
  }
}
