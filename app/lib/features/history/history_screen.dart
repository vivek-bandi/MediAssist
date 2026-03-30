import 'package:flutter/material.dart';

import '../../core/engine/assistant_service.dart';
import '../../models/assistant_models.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.assistantService});

  final AssistantService assistantService;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<SessionEntry> _history = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final result = await widget.assistantService.loadHistory();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = result;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent Sessions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: _loadHistory,
                  tooltip: 'Refresh',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _history.isEmpty
                    ? const Center(child: Text('No sessions yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _history.length,
                        itemBuilder: (context, index) {
                          final item = _history[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(item.query),
                              subtitle: Text(item.resultSummary),
                              trailing: item.isEmergency
                                  ? const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.red,
                                    )
                                  : const Icon(Icons.check_circle_outline),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
