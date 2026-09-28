import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';
import 'package:sentinel/services/api_service.dart';

class AnomalyHistoryScreen extends StatefulWidget {
  const AnomalyHistoryScreen({super.key});

  @override
  State<AnomalyHistoryScreen> createState() => _AnomalyHistoryScreenState();
}

class _AnomalyHistoryScreenState extends State<AnomalyHistoryScreen> {
  AnomalyHistoryResponse? _response;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await ApiService.getAnomalyHistory();

      if (!mounted) return;

      setState(() => _response = response);
    } catch (error) {
      debugPrint('Anomali geçmişi alınamadı: $error');

      if (!mounted) return;
      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.tryParse(timestamp);

    return date == null
        ? timestamp
        : DateFormat('dd.MM.yyyy HH:mm:ss').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final response = _response;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedHistoryTab),
        actions: [
          IconButton(
            tooltip: l10n.refreshData,
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hasError || response == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.anomalyHistoryLoadFailed),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: response.results.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response.deviceId,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(l10n.anomalyHistoryCount(response.returnedCount)),
                        const SizedBox(height: 8),
                        Text(
                          l10n.anomalyHistoryNotice,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (response.results.isEmpty) ...[
                          const SizedBox(height: 24),
                          Text(l10n.anomalyHistoryEmpty),
                        ],
                      ],
                    ),
                  );
                }

                final anomaly = response.results[index - 1];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.amber,
                    ),
                    title: Text(_formatTimestamp(anomaly.timestamp)),
                    subtitle: Text(
                      '${l10n.affectedSensors}: '
                      '${anomaly.measurements.keys.join(', ')}',
                    ),
                    children: [
                      for (final entry in anomaly.measurements.entries)
                        ListTile(
                          title: Text(entry.key),
                          subtitle: Text(
                            '${l10n.measurementValue}: '
                            '${entry.value.value}\n'
                            '${l10n.baselineMedian}: '
                            '${entry.value.median}\n'
                            'Robust Z-score: '
                            '${entry.value.robustZScore}',
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
