import '../../models/assistant_models.dart';

class RedFlagDetector {
  const RedFlagDetector();

  RedFlagRule? detect(String query, List<RedFlagRule> rules) {
    final normalized = query.toLowerCase();
    for (final rule in rules) {
      for (final trigger in rule.triggers) {
        if (normalized.contains(trigger.toLowerCase())) {
          return rule;
        }
      }
    }
    return null;
  }
}
