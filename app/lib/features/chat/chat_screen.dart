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
  List<SessionEntry> _history = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

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
    final history = await widget.assistantService.loadHistory();

    setState(() {
      _result = result;
      _history = history;
      _loading = false;
    });
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
              Expanded(
                child: ListView.builder(
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
              ),
            ],
          ],
        ),
      ),
    );
  }
}
