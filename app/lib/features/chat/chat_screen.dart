import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/engine/assistant_service.dart';
import '../../core/input/voice_input_service.dart';
import '../../core/output/tts_service.dart';
import '../../models/assistant_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.assistantService});

  final AssistantService assistantService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  VoiceInputService? _voiceInputService;
  TtsService? _ttsService;

  AppLanguage _language = AppLanguage.english;
  final RuntimeMode _mode = RuntimeMode.offline;
  AssistantResult? _result;
  List<SessionEntry> _history = const [];
  bool _loading = false;
  bool _voiceReady = false;
  bool _voiceInitializing = true;
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _initializeVoice();
  }

  @override
  void dispose() {
    _voiceInputService?.stopListening();
    _ttsService?.stop();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeVoice() async {
    _voiceInputService ??= VoiceInputService();

    bool ready = false;
    try {
      ready = await _voiceInputService!.initialize();
    } catch (_) {
      ready = false;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _voiceReady = ready && !kIsWeb;
      _voiceInitializing = false;
    });
  }

  Future<void> _submit() async {
    if (_loading) {
      return;
    }

    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final result = await widget.assistantService.handleQuery(
        query: query,
        language: _language,
        mode: _mode,
      );
      final history = await widget.assistantService.loadHistory();

      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
        _history = history;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    final history = await widget.assistantService.loadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = history;
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_voiceInitializing || !_voiceReady) {
      return;
    }

    final service = _voiceInputService;
    if (service == null) {
      return;
    }

    if (_listening) {
      await service.stopListening();
      if (!mounted) {
        return;
      }
      setState(() {
        _listening = false;
      });
      return;
    }

    await service.startListening(
      language: _language,
      onResult: (words) {
        if (!mounted) {
          return;
        }
        setState(() {
          _controller.text = words;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );

    if (!mounted) {
      return;
    }
    setState(() {
      _listening = true;
    });
  }

  Future<void> _speakResult() async {
    if (_result == null) {
      return;
    }

    if (kIsWeb) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Read aloud is currently available on mobile/desktop builds.'),
        ),
      );
      return;
    }

    _ttsService ??= TtsService();
    final text = [
      _result!.summary,
      ..._result!.steps,
      _result!.safetyNote,
    ].join(' ');

    try {
      await _ttsService!.speak(text: text, language: _language);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start text-to-speech on this device.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediAssist AI'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              DropdownButton<AppLanguage>(
                value: _language,
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _language = value;
                  });
                },
                items: const [
                  DropdownMenuItem(
                    value: AppLanguage.english,
                    child: Text('English'),
                  ),
                  DropdownMenuItem(
                    value: AppLanguage.telugu,
                    child: Text('Telugu'),
                  ),
                ],
              ),
              const Chip(
                avatar: Icon(Icons.cloud_off, size: 18),
                label: Text('Offline only'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Describe your symptoms',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FilledButton(
                onPressed: _loading ? null : _submit,
                child: Text(_loading ? 'Checking...' : 'Get Guidance'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _toggleVoiceInput,
                icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic),
                label: Text(
                  _voiceInitializing
                      ? 'Voice loading...'
                      : _listening
                          ? 'Stop Listening'
                          : _voiceReady
                              ? 'Start Voice'
                              : kIsWeb
                                  ? 'Voice unavailable (web)'
                                  : 'Voice unavailable',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_result != null)
            Card(
              color: _result!.isEmergency
                  ? Colors.red.shade50
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.isEmergency ? 'Emergency Guidance' : 'Guidance',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(_result!.summary),
                    const SizedBox(height: 8),
                    for (final step in _result!.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(step)),
                          ],
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      _result!.safetyNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _speakResult,
                      icon: const Icon(Icons.volume_up_outlined),
                      label: const Text('Read aloud'),
                    ),
                    if (_result!.usedOnlineEnhancement)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Mode: Online enhancement',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  child: ListTile(
                    title: Text(item.query),
                    subtitle: Text(item.resultSummary),
                    trailing: item.isEmergency
                        ? const Icon(Icons.warning_amber_rounded, color: Colors.red)
                        : const Icon(Icons.check_circle_outline),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
