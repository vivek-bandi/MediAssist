import 'dart:convert';

import 'package:flutter/services.dart';

import '../../models/assistant_models.dart';

class OfflineRulesRepository {
  Future<List<SymptomRule>> loadSymptomRules() async {
    final raw = await rootBundle.loadString('assets/rules/symptom_rules.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final rules = parsed['rules'] as List<dynamic>;
    return rules
        .map((item) => SymptomRule.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<RedFlagRule>> loadRedFlagRules() async {
    final raw = await rootBundle.loadString('assets/rules/red_flag_rules.json');
    final parsed = jsonDecode(raw) as Map<String, dynamic>;
    final rules = parsed['rules'] as List<dynamic>;
    return rules
        .map((item) => RedFlagRule.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
