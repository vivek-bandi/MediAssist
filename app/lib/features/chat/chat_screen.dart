import 'package:flutter/material.dart';

import '../../core/engine/assistant_service.dart';
import '../../models/assistant_models.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.assistantService});

  final AssistantService assistantService;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  AppLanguage _language = AppLanguage.english;
  RuntimeMode _mode = RuntimeMode.offline;
  AssistantResult? _result;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final query = _controller.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _loading = true;
    });

    final result = await widget.assistantService.handleQuery(
      query: query,
      language: _language,
      mode: _mode,
    );

    setState(() {
      _result = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MediAssist AI'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                SegmentedButton<RuntimeMode>(
                  segments: const [
                    ButtonSegment(
                      value: RuntimeMode.offline,
                      label: Text('Offline'),
                    ),
                    ButtonSegment(
                      value: RuntimeMode.online,
                      label: Text('Online'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _mode = selection.first;
                    });
                  },
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
                  onPressed: null,
                  icon: const Icon(Icons.mic),
                  label: const Text('Voice (next)'),
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
                      Text(_result!.message),
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
          ],
        ),
      ),
    );
  }
}
