import 'package:flutter/material.dart';

import '../../core/engine/assistant_service.dart';
import '../chat/chat_screen.dart';
import '../history/history_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.assistantService});

  final AssistantService assistantService;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;

  void _goToTalkTab() {
    setState(() {
      _currentIndex = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomePage(onStart: _goToTalkTab),
      ChatScreen(assistantService: widget.assistantService),
      HistoryScreen(assistantService: widget.assistantService),
      const _FeaturesPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.record_voice_over_outlined),
            selectedIcon: Icon(Icons.record_voice_over),
            label: 'Talk',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Features',
          ),
        ],
      ),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  colorScheme.primary,
                  const Color(0xFF1A8E86),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'MediAssist',
                        style: textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'v1',
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Smart health guidance for every home',
                  style: textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Voice-ready, bilingual and offline-first. Built for fast, reliable care decisions.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _HeroPill(icon: Icons.wifi_off_outlined, text: 'Offline-first'),
                    _HeroPill(icon: Icons.translate_rounded, text: 'English + Telugu'),
                    _HeroPill(icon: Icons.emergency_outlined, text: 'Emergency-ready'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start now',
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final narrow = constraints.maxWidth < 430;
                      final talkButton = FilledButton.icon(
                        onPressed: onStart,
                        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                        icon: const Icon(Icons.mic_rounded),
                        label: const Text(
                          'Talk to Assistant',
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700),
                        ),
                      );
                      final typeButton = OutlinedButton.icon(
                        onPressed: onStart,
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                        icon: const Icon(Icons.keyboard_alt_rounded),
                        label: const Text(
                          'Type Symptoms',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      );

                      if (narrow) {
                        return Column(
                          children: [
                            SizedBox(width: double.infinity, child: talkButton),
                            const SizedBox(height: 10),
                            SizedBox(width: double.infinity, child: typeButton),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: talkButton),
                          const SizedBox(width: 10),
                          Expanded(child: typeButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _MetricTile(
                            value: '24x7',
                            label: 'Availability',
                            color: colorScheme.primary,
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            value: '2',
                            label: 'Languages',
                            color: Colors.teal,
                          ),
                        ),
                        Expanded(
                          child: _MetricTile(
                            value: 'Offline',
                            label: 'Fallback',
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Why MediAssist',
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _FeatureCardHighlight(
                icon: Icons.emergency_rounded,
                iconColor: Colors.red.shade700,
                title: 'Emergency Triage',
                description: 'Identify red flags quickly and guide the next safe step.',
              ),
              _FeatureCardHighlight(
                icon: Icons.language_rounded,
                iconColor: colorScheme.primary,
                title: 'Bilingual Support',
                description: 'Works naturally in both English and Telugu.',
              ),
              _FeatureCardHighlight(
                icon: Icons.cloud_off_rounded,
                iconColor: Colors.orange.shade700,
                title: 'Works Offline',
                description: 'Guidance remains available even with unstable internet.',
              ),
              _FeatureCardHighlight(
                icon: Icons.record_voice_over_rounded,
                iconColor: Colors.teal.shade700,
                title: 'Voice First UX',
                description: 'Large controls and voice flow for fast usage.',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 14),
                const _StepIndicator(
                  step: '1',
                  title: 'Tell your symptoms',
                  description: 'Speak or type what you are feeling right now.',
                ),
                const SizedBox(height: 12),
                const _StepIndicator(
                  step: '2',
                  title: 'Get safe guidance',
                  description: 'Receive practical next steps instantly.',
                ),
                const SizedBox(height: 12),
                const _StepIndicator(
                  step: '3',
                  title: 'Escalate when needed',
                  description: 'For serious symptoms, seek immediate medical care.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 19, color: Colors.blue.shade800),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MediAssist provides guidance only and is not a diagnosis. Consult a doctor for medical decisions.',
                    style: textTheme.bodySmall?.copyWith(color: Colors.blue.shade900),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _FeatureCardHighlight extends StatelessWidget {
  const _FeatureCardHighlight({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: MediaQuery.of(context).size.width > 460
          ? (MediaQuery.of(context).size.width - 42) / 2
          : double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surface,
      ),
      child: ListTile(
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
        ),
        subtitle: Text(description),
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeaturesPage extends StatelessWidget {
  const _FeaturesPage();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _FeatureTile(
            icon: Icons.medication_outlined,
            title: 'Medicine Reminders',
            subtitle: 'Planned: schedule local reminders and voice alerts.',
          ),
          _FeatureTile(
            icon: Icons.local_hospital_outlined,
            title: 'Nearby Health Centers',
            subtitle: 'Planned: discover nearby care options in low-connectivity mode.',
          ),
          _FeatureTile(
            icon: Icons.family_restroom_outlined,
            title: 'Family Profiles',
            subtitle: 'Planned: save profiles for children, elders, and caregivers.',
          ),
          _FeatureTile(
            icon: Icons.favorite_outline,
            title: 'Wellness Follow-ups',
            subtitle: 'Planned: daily symptom follow-up and recovery tracking.',
          ),
        ],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
