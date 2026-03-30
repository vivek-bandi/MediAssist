import 'dart:async';

import 'package:flutter/material.dart';

import 'core/engine/assistant_service.dart';
import 'core/online/groq_online_adapter.dart';
import 'core/rules/offline_rules_repository.dart';
import 'core/safety/red_flag_detector.dart';
import 'core/storage/session_history_repository.dart';
import 'features/shell/app_shell.dart';

void main() {
  runApp(const MediAssistApp());
}

class MediAssistApp extends StatelessWidget {
  const MediAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    const groqApiKey = String.fromEnvironment('GROQ_API_KEY');
    final rulesRepository = OfflineRulesRepository();
    unawaited(rulesRepository.preloadRules());

    final assistantService = AssistantService(
      rulesRepository: rulesRepository,
      redFlagDetector: const RedFlagDetector(),
      historyRepository: SessionHistoryRepository(),
      onlineAdapter: GroqOnlineAdapter(apiKey: groqApiKey),
    );

    return MaterialApp(
      title: 'MediAssist AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF147A73)),
        visualDensity: VisualDensity.standard,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFFF4F8F7),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ),
      home: AppShell(assistantService: assistantService),
    );
  }
}
