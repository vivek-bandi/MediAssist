class OnlineSafetyGuard {
  const OnlineSafetyGuard();

  static const List<String> _blockedFragments = [
    'mg',
    'tablet',
    'capsule',
    'dose',
    'dosage',
    'prescribe',
    'prescription',
    'antibiotic',
  ];

  List<String> sanitizeTips(List<String> tips) {
    final sanitized = <String>[];
    for (final tip in tips) {
      final normalized = tip.toLowerCase();
      final containsBlocked = _blockedFragments.any(normalized.contains);
      if (!containsBlocked) {
        sanitized.add(tip.trim());
      }
    }
    return sanitized;
  }
}
