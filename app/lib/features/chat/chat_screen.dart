import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final Connectivity _connectivity = Connectivity();

  AppLanguage _language = AppLanguage.english;
  RuntimeMode _mode = RuntimeMode.offline;
  AssistantResult? _result;
  bool _loading = false;
  bool _onlineConfigured = false;
  bool _internetAvailable = false;
  bool _voiceReady = false;
  bool _voiceInitializing = true;
  bool _listening = false;

  String _text({required String en, required String te}) {
    return _language == AppLanguage.telugu ? te : en;
  }

  List<String> _quickSymptoms() {
    if (_language == AppLanguage.telugu) {
      return const [
        'జ్వరం',
        'దగ్గు',
        'తలనొప్పి',
        'వాంతులు',
        'విరేచనాలు',
        'శ్వాస ఇబ్బంది',
      ];
    }
    return const [
      'Fever',
      'Cough',
      'Headache',
      'Vomiting',
      'Diarrhea',
      'Breathing trouble',
    ];
  }

  void _applyQuickSymptom(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  @override
  void initState() {
    super.initState();
    _onlineConfigured = widget.assistantService.isOnlineConfigured;
    _initializeVoice();
    _initializeConnectivity();
  }

  @override
  void dispose() {
    _voiceInputService?.stopListening();
    _ttsService?.stop();
    _connectivitySubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeConnectivity() async {
    final initial = await _connectivity.checkConnectivity();
    _applyConnectivityResults(initial);

    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _applyConnectivityResults,
    );
  }

  void _applyConnectivityResults(List<ConnectivityResult> results) {
    final connected = results.any((result) => result != ConnectivityResult.none);
    final onlineAllowed = connected && _onlineConfigured;
    if (!mounted) {
      return;
    }
    setState(() {
      _internetAvailable = connected;
      _mode = onlineAllowed ? RuntimeMode.online : RuntimeMode.offline;
    });
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

  Future<void> _submit({bool autoSpeak = false}) async {
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
      if (!mounted) {
        return;
      }
      setState(() {
        _result = result;
      });

      if (autoSpeak && !kIsWeb) {
        await _speakResult();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _result = AssistantResult(
          summary: _text(
            en: 'Could not process this request right now. Showing offline-safe guidance.',
            te: 'ప్రస్తుతం ఈ అభ్యర్థనను ప్రాసెస్ చేయలేకపోయాము. ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం చూపిస్తోంది.',
          ),
          steps: [
            _text(
              en: 'Try again after a few seconds.',
              te: 'కొన్ని సెకన్ల తర్వాత మళ్లీ ప్రయత్నించండి.',
            ),
            _text(
              en: 'If symptoms are severe or worsening, consult a doctor immediately.',
              te: 'లక్షణాలు తీవ్రమై ఉంటే లేదా పెరుగుతుంటే వెంటనే వైద్యుడిని సంప్రదించండి.',
            ),
          ],
          safetyNote: _text(
            en: 'This is guidance only and not a diagnosis.',
            te: 'ఇది మార్గదర్శకం మాత్రమే, నిర్ధారణ కాదు.',
          ),
          isEmergency: false,
          usedOnlineEnhancement: false,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _text(
              en: 'Temporary issue occurred. Switched to safe fallback guidance.',
              te: 'తాత్కాలిక సమస్య వచ్చింది. సురక్షిత ఫాల్బ్యాక్ మార్గదర్శకానికి మారింది.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
      onResult: (words, isFinal) {
        if (!mounted) {
          return;
        }
        setState(() {
          _controller.text = words;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });

        if (isFinal && words.trim().isNotEmpty && !_loading) {
          service.stopListening();
          if (mounted) {
            setState(() {
              _listening = false;
            });
          }
          _submit(autoSpeak: true);
        }
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
    ].map(_ensureSentenceEnd).join(' ');

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

  String _ensureSentenceEnd(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    if (RegExp(r'[.!?]$').hasMatch(trimmed)) {
      return trimmed;
    }

    return '$trimmed.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headingStyle = theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    final modeIsOnline = _internetAvailable && _onlineConfigured;
    final modeColor = modeIsOnline ? Colors.green.shade700 : Colors.orange.shade800;
    final modeText = modeIsOnline ? _text(en: 'Online', te: 'ఆన్‌లైన్') : _text(en: 'Offline', te: 'ఆఫ్‌లైన్');
    final modeSubtitle = modeIsOnline
        ? _text(
            en: 'Connected. Enhanced online guidance is available.',
            te: 'కనెక్ట్ అయింది. మెరుగైన ఆన్‌లైన్ మార్గదర్శకం అందుబాటులో ఉంది.',
          )
        : _text(
            en: _onlineConfigured
                ? 'No internet right now. Using reliable offline-safe guidance.'
                : 'Online mode not configured. Using offline-safe guidance.',
            te: _onlineConfigured
                ? 'ప్రస్తుతం ఇంటర్నెట్ లేదు. విశ్వసనీయ ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం ఉపయోగిస్తోంది.'
                : 'ఆన్‌లైన్ మోడ్ కాన్ఫిగర్ కాలేదు. ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం ఉపయోగిస్తోంది.',
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(_text(en: 'MediAssist', te: 'మెడి అసిస్టు')),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: modeColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            modeIsOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                            size: 20,
                            color: modeColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _text(en: 'Mode: $modeText', te: 'మోడ్: $modeText'),
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      modeSubtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      _text(en: 'Language', te: 'భాష'),
                      style: headingStyle,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AppLanguage>(
                        segments: const [
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.english,
                            label: Text('English'),
                          ),
                          ButtonSegment<AppLanguage>(
                            value: AppLanguage.telugu,
                            label: Text('తెలుగు'),
                          ),
                        ],
                        selected: <AppLanguage>{_language},
                        showSelectedIcon: false,
                        onSelectionChanged: (selection) {
                          final selected = selection.first;
                          if (selected == _language) {
                            return;
                          }
                          setState(() {
                            _language = selected;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(en: 'Describe symptoms', te: 'లక్షణాలను వివరించండి'),
                      style: headingStyle,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _controller,
                      minLines: 3,
                      maxLines: 5,
                      style: const TextStyle(fontSize: 17),
                      decoration: InputDecoration(
                        hintText: _text(
                          en: 'Example: fever for 2 days, night cough',
                          te: 'ఉదాహరణ: 2 రోజులుగా జ్వరం, రాత్రిళ్లు దగ్గు',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final symptom in _quickSymptoms())
                          ActionChip(
                            label: Text(symptom),
                            onPressed: () => _applyQuickSymptom(symptom),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () {
                        _applyQuickSymptom(
                          _text(
                            en: 'Severe chest pain and breathing trouble',
                            te: 'తీవ్రమైన ఛాతి నొప్పి మరియు శ్వాస ఇబ్బంది',
                          ),
                        );
                        _submit();
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: Colors.red.shade700,
                      ),
                      icon: const Icon(Icons.emergency_rounded),
                      label: Text(
                        _text(en: 'Emergency Help', te: 'అత్యవసర సహాయం'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 10),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final narrow = constraints.maxWidth < 430;
                        final primaryButton = FilledButton.icon(
                          onPressed: _loading ? null : _submit,
                          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                          icon: const Icon(Icons.health_and_safety_rounded),
                          label: Text(
                            _loading ? _text(en: 'Checking...', te: 'పరిశీలిస్తోంది...') : _text(en: 'Get Guidance', te: 'సలహా పొందండి'),
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                          ),
                        );
                        final voiceButton = OutlinedButton.icon(
                          onPressed: _toggleVoiceInput,
                          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                          icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic_rounded),
                          label: Text(
                            _voiceInitializing
                                ? _text(en: 'Voice loading...', te: 'వాయిస్ లోడ్ అవుతోంది...')
                                : _listening
                                    ? _text(en: 'Stop Listening', te: 'వినడం ఆపు')
                                    : _voiceReady
                                        ? _text(en: 'Talk to Assistant', te: 'వాయిస్‌తో మాట్లాడండి')
                                        : kIsWeb
                                            ? _text(en: 'Voice unavailable (web)', te: 'వాయిస్ అందుబాటులో లేదు (వెబ్)')
                                            : _text(en: 'Voice unavailable', te: 'వాయిస్ అందుబాటులో లేదు'),
                            style: const TextStyle(fontSize: 16),
                          ),
                        );

                        if (narrow) {
                          return Column(
                            children: [
                              SizedBox(width: double.infinity, child: primaryButton),
                              const SizedBox(height: 10),
                              SizedBox(width: double.infinity, child: voiceButton),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: primaryButton),
                            const SizedBox(width: 10),
                            Expanded(child: voiceButton),
                          ],
                        );
                      },
                    ),
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            if (_result != null && modeIsOnline && !_result!.isEmergency && !_result!.usedOnlineEnhancement) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 1),
                      child: Icon(Icons.wifi_tethering_error_rounded, size: 16, color: Colors.orange),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _text(
                          en: 'Online enrichment was unavailable for this response. Showing offline-safe guidance.',
                          te: 'ఈ ప్రతిస్పందనకు ఆన్‌లైన్ మెరుగుదల అందుబాటులో లేదు. ఆఫ్‌లైన్ సురక్షిత మార్గదర్శకం చూపిస్తోంది.',
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 12),
              Card(
                color: _result!.isEmergency ? Colors.red.shade50 : theme.colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _result!.isEmergency ? _text(en: 'Emergency Guidance', te: 'అత్యవసర సూచనలు') : _text(en: 'Guidance', te: 'సూచనలు'),
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _result!.usedOnlineEnhancement ? Colors.green.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _result!.usedOnlineEnhancement ? _text(en: 'Online', te: 'ఆన్‌లైన్') : _text(en: 'Offline', te: 'ఆఫ్‌లైన్'),
                              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(_result!.summary, style: theme.textTheme.bodyLarge),
                      const SizedBox(height: 10),
                      for (final step in _result!.steps)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.check_circle_outline, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(step)),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(_result!.safetyNote, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _speakResult,
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                        icon: const Icon(Icons.volume_up_outlined),
                        label: Text(_text(en: 'Read aloud', te: 'వినిపించు')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
