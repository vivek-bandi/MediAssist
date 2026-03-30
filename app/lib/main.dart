import 'package:flutter/material.dart';

import 'core/engine/assistant_service.dart';
import 'core/rules/offline_rules_repository.dart';
import 'core/safety/red_flag_detector.dart';
import 'features/chat/chat_screen.dart';

void main() {
  runApp(const MediAssistApp());
}

class MediAssistApp extends StatelessWidget {
  const MediAssistApp({super.key});

  @override
  Widget build(BuildContext context) {
    final assistantService = AssistantService(
      rulesRepository: OfflineRulesRepository(),
      redFlagDetector: const RedFlagDetector(),
    );

    return MaterialApp(
      title: 'MediAssist AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF147A73)),
      ),
      home: ChatScreen(assistantService: assistantService),
    );
  }
}
