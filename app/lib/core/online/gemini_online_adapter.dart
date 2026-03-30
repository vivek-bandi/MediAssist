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
  });

  final OnlineFetchStatus status;
  final List<String> tips;
}

class GeminiOnlineAdapter {
  GeminiOnlineAdapter({
    required String apiKey,
    Dio? dio,
    OnlineSafetyGuard? safetyGuard,
  })  : _apiKey = apiKey,
        _dio = dio ?? Dio(),
        _safetyGuard = safetyGuard ?? const OnlineSafetyGuard();

  final String _apiKey;
  final Dio _dio;
  final OnlineSafetyGuard _safetyGuard;

  bool get isConfigured => _apiKey.isNotEmpty;

  Future<OnlineFetchResult> fetchEnrichedTips({
    required String query,
    required AppLanguage language,
    required String baselineSummary,
  }) async {
    if (!isConfigured) {
      return const OnlineFetchResult(status: OnlineFetchStatus.notConfigured);
    }

    final languageName = language == AppLanguage.telugu ? 'Telugu' : 'English';
    final prompt = _buildPrompt(
      query: query,
      languageName: languageName,
      baselineSummary: baselineSummary,
    );

    final payload = {
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
    };

    try {
      final response = await _postGenerateContent(payload);

      final body = response.data;
      if (body == null) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }

      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }

      final decoded = _decodeTipsFromCandidates(candidates);
      if (decoded == null) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }

      final tips = (decoded['tips'] as List<dynamic>)
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList();
      final sanitized = _safetyGuard.sanitizeTips(tips);
      if (sanitized.isEmpty) {
        return const OnlineFetchResult(status: OnlineFetchStatus.unavailable);
      }
      return OnlineFetchResult(
        status: OnlineFetchStatus.success,
        tips: sanitized.take(3).toList(),
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

  Future<Response<Map<String, dynamic>>> _postGenerateContent(
    Map<String, dynamic> payload,
  ) {
    return _dio.post<Map<String, dynamic>>(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent',
      queryParameters: {'key': _apiKey},
      options: Options(
        sendTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ),
      data: payload,
    );
  }

  Map<String, dynamic>? _decodeTipsPayload(String raw) {
    try {
      final direct = jsonDecode(raw) as Map<String, dynamic>;
      if (direct['tips'] is List<dynamic>) {
        return direct;
      }
    } catch (_) {
      // Try extracting JSON payload from wrapped content.
    }

    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) {
      return null;
    }

    final slice = raw.substring(start, end + 1);
    try {
      final extracted = jsonDecode(slice) as Map<String, dynamic>;
      if (extracted['tips'] is List<dynamic>) {
        return extracted;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

  Map<String, dynamic>? _decodeTipsFromCandidates(List<dynamic> candidates) {
    for (final candidate in candidates) {
      final candidateMap = candidate as Map<String, dynamic>;
      final content = candidateMap['content'] as Map<String, dynamic>?;
      if (content == null) {
        continue;
      }

      final parts = content['parts'] as List<dynamic>?;
      if (parts == null || parts.isEmpty) {
        continue;
      }

      final texts = <String>[];
      for (final part in parts) {
        final text = (part as Map<String, dynamic>)['text'] as String?;
        if (text != null && text.isNotEmpty) {
          texts.add(text);
        }
      }

      if (texts.isEmpty) {
        continue;
      }

      final decoded = _decodeTipsPayload(texts.join('\n'));
      if (decoded != null) {
        return decoded;
      }
    }

    return null;
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
- Keep each tip concise.
- Return ONLY valid JSON, no markdown.

Required JSON schema:
{"tips":["tip 1","tip 2","tip 3"]}
''';
  }
}
