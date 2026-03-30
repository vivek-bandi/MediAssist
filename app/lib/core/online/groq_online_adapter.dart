import 'dart:convert';

import 'package:dio/dio.dart';

import '../../models/assistant_models.dart';
import 'online_safety_guard.dart';

enum OnlineFetchStatus {
  success,
  notConfigured,
  rateLimited,
  unavailable,
}

class OnlineFetchResult {
  const OnlineFetchResult({
    required this.status,
    this.tips = const [],
    this.summary,
  });

  final OnlineFetchStatus status;
  final List<String> tips;
  final String? summary;
}

class _ParsedOnlineContent {
  const _ParsedOnlineContent({
    required this.tips,
    this.summary,
  });

  final List<String> tips;
  final String? summary;
}

class GroqOnlineAdapter {
  GroqOnlineAdapter({
    required String apiKey,
    Dio? dio,
    OnlineSafetyGuard? safetyGuard,
  })  : _apiKey = apiKey,
        _dio = dio ?? Dio(),
        _safetyGuard = safetyGuard ?? const OnlineSafetyGuard();

  static const String _endpoint =
      'https://api.groq.com/openai/v1/chat/completions';
  static const String _model = 'llama-3.3-70b-versatile';

  final String _apiKey;
  final Dio _dio;
  final OnlineSafetyGuard _safetyGuard;

  bool get isConfigured => _apiKey.trim().isNotEmpty;

  Future<OnlineFetchResult> fetchEnrichedTips({
    required String query,
    required AppLanguage language,
    required String baselineSummary,
  }) async {
    if (!isConfigured) {
      return const OnlineFetchResult(status: OnlineFetchStatus.notConfigured);
    }

    final payload = {
      'model': _model,
      'temperature': 0.2,
      'max_tokens': 220,
      'response_format': {'type': 'json_object'},
      'messages': [
        {
          'role': 'system',
          'content':
            'You are a safety-first healthcare assistant. Return only valid JSON matching {"summary":"one short line","tips":["tip 1","tip 2","tip 3"]}.',
        },
        {
          'role': 'user',
          'content': _buildPrompt(
            query: query,
            languageName: language == AppLanguage.telugu ? 'Telugu' : 'English',
            baselineSummary: baselineSummary,
          ),
        },
      ],
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _endpoint,
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Authorization': 'Bearer $_apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: payload,
      );

      final body = response.data;
      if (body == null) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }

      final parsed = _extractTipsFromResponse(body);
      final sanitized = _sanitizeAndLimit(parsed.tips);
      if (sanitized.isEmpty) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }

      final normalizedSummary = _normalizeSummary(parsed.summary, sanitized);

      return OnlineFetchResult(
        status: OnlineFetchStatus.success,
        tips: sanitized,
        summary: normalizedSummary,
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 429) {
        return const OnlineFetchResult(status: OnlineFetchStatus.rateLimited);
      }
      return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
    } catch (_) {
      return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
    }
  }

  _ParsedOnlineContent _extractTipsFromResponse(Map<String, dynamic> body) {
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      return const _ParsedOnlineContent(tips: []);
    }

    for (final choice in choices) {
      if (choice is! Map) {
        continue;
      }

      final choiceMap = Map<String, dynamic>.from(choice);
      final messageRaw = choiceMap['message'];
      if (messageRaw is! Map) {
        continue;
      }

      final message = Map<String, dynamic>.from(messageRaw);
      final content = _normalizeContent(message['content']);
      if (content.isEmpty || _isInvalidNoise(content)) {
        continue;
      }

      final jsonTips = _extractTipsFromJsonContent(content);
      if (jsonTips.isNotEmpty) {
        return _ParsedOnlineContent(
          tips: jsonTips,
          summary: _extractSummaryFromJsonContent(content),
        );
      }

      final textTips = _extractTipsFromPlainText(content);
      if (textTips.isNotEmpty) {
        return _ParsedOnlineContent(
          tips: textTips,
          summary: textTips.first,
        );
      }
    }

    return const _ParsedOnlineContent(tips: []);
  }

  String _normalizeContent(dynamic content) {
    if (content is String) {
      return content.replaceAll('\u0000', '').trim();
    }

    if (content is List) {
      final parts = <String>[];
      for (final item in content) {
        if (item is Map && item['text'] is String) {
          parts.add((item['text'] as String));
        }
      }
      return parts.join('\n').replaceAll('\u0000', '').trim();
    }

    return '';
  }

  List<String> _extractTipsFromJsonContent(String content) {
    final payload = _tryDecodeTipsPayload(content);
    if (payload == null) {
      return const [];
    }

    final tips = payload['tips'];
    if (tips is! List) {
      return const [];
    }

    return tips
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty && !_isInvalidNoise(item))
        .toList();
  }

  String? _extractSummaryFromJsonContent(String content) {
    final payload = _tryDecodeTipsPayload(content);
    if (payload == null) {
      return null;
    }

    final summary = payload['summary']?.toString().trim();
    if (summary == null || summary.isEmpty || _isInvalidNoise(summary)) {
      return null;
    }
    return summary;
  }

  Map<String, dynamic>? _tryDecodeTipsPayload(String raw) {
    try {
      final direct = jsonDecode(raw);
      if (direct is Map<String, dynamic> && direct['tips'] is List) {
        return direct;
      }
    } catch (_) {
      // Fallback to extracting object substring.
    }

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return null;
    }

    final candidate = raw.substring(start, end + 1);
    try {
      final extracted = jsonDecode(candidate);
      if (extracted is Map<String, dynamic> && extracted['tips'] is List) {
        return extracted;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  List<String> _extractTipsFromPlainText(String raw) {
    final cleaned = raw.replaceAll('\r', '\n').trim();
    if (cleaned.isEmpty) {
      return const [];
    }

    final lines = cleaned
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => line.replaceFirst(RegExp(r'^[-*•\d.)\s]+'), '').trim())
        .where((line) => line.isNotEmpty && !_isInvalidNoise(line))
        .toList();

    if (lines.isEmpty) {
      return const [];
    }

    if (lines.length == 1) {
      return lines.first
          .split(RegExp(r'(?<=[.!?])\s+'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty && !_isInvalidNoise(item))
          .toList();
    }

    return lines;
  }

  List<String> _sanitizeAndLimit(List<String> tips) {
    final filteredNoise = tips
        .map((tip) => tip.trim())
        .where((tip) => tip.isNotEmpty && !_isInvalidNoise(tip))
        .toList();
    final safe = _safetyGuard.sanitizeTips(filteredNoise);
    final unique = <String>[];
    for (final tip in safe) {
      final polished = _polishSentence(tip);
      if (polished.isEmpty) {
        continue;
      }

      final exists = unique.any(
        (item) => item.toLowerCase() == polished.toLowerCase(),
      );
      if (!exists) {
        unique.add(polished);
      }
    }
    return unique.take(3).toList();
  }

  String _normalizeSummary(String? summary, List<String> sanitizedTips) {
    final normalized = _polishSentence(summary?.trim() ?? '');
    if (normalized.isNotEmpty && !_isInvalidNoise(normalized)) {
      return normalized;
    }
    return _polishSentence(sanitizedTips.first);
  }

  String _polishSentence(String value) {
    final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.isEmpty) {
      return compact;
    }

    final capitalized = compact[0].toUpperCase() + compact.substring(1);
    if (RegExp(r'[.!?]$').hasMatch(capitalized)) {
      return capitalized;
    }
    return '$capitalized.';
  }

  bool _isInvalidNoise(String text) {
    final normalized = text.trim().toLowerCase();
    return normalized == '0x00000000' ||
        normalized == '0x0' ||
        normalized == 'null' ||
        normalized == '[object object]' ||
        normalized.contains('\u0000');
  }

  String _buildPrompt({
    required String query,
    required String languageName,
    required String baselineSummary,
  }) {
    return '''
You are a safety-first healthcare assistant for low-resource settings.

User symptom input: "$query"
Baseline offline summary: "$baselineSummary"
Response language: $languageName

Rules:
- NOT a diagnosis.
- NO medicine names, NO dosage, NO prescriptions.
- Keep tips practical and low-risk.
- Keep each tip concise and action-oriented.
- Speak in supportive, simple language for non-medical users.
- Avoid repeating the same idea in multiple tips.
- Start summary with uncertainty wording (for example: "You may have...").
- If symptoms can worsen, include one tip to consult a doctor.
- Return ONLY valid JSON, no markdown.

Required JSON schema:
{"summary":"one short line","tips":["tip 1","tip 2","tip 3"]}
''';
  }
}