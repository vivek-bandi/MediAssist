import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/assistant_models.dart';

class SessionHistoryRepository {
  static const String _historyKey = 'medassist_session_history';

  Future<List<SessionEntry>> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => SessionEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> addEntry(SessionEntry entry, {int maxEntries = 30}) async {
    final existing = await loadHistory();
    final next = [entry, ...existing];
    final truncated = next.take(maxEntries).toList();

    final prefs = await SharedPreferences.getInstance();
    final serialized = jsonEncode(
      truncated.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_historyKey, serialized);
  }
}
