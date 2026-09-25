import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';
import 'package:sentinel/services/api_service.dart';
import 'package:sentinel/widgets/cards/ai_analysis_card.dart';

class AdminAnomaliesScreen extends StatefulWidget {
  const AdminAnomaliesScreen({super.key});

  @override
  State<AdminAnomaliesScreen> createState() => _AdminAnomaliesScreenState();
}

class _AdminAnomaliesScreenState extends State<AdminAnomaliesScreen> {
  AnomalyResponse? _response;
  bool _isLoading = true;
  bool _hasError = false;

  AiAnomalyResponse? _aiResponse;
  bool _isAiLoading = false;
  bool _hasAiError = false;

  @override
  void initState() {
    super.initState();
    _loadAnomalies();
  }

  Future<void> _loadAnomalies() async {
    try {
      final response = await ApiService.getAnomalies();

      if (!mounted) return;

      setState(() {
        _response = response;
        _hasError = false;
      });
    } catch (error) {
      debugPrint('Son analiz sonuçları alınamadı: $error');

      if (!mounted) return;

      setState(() => _hasError = true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _analyzeWithAi() async {
    if (_isAiLoading || _isLoading) return;

    setState(() {
      _isAiLoading = true;
      _hasAiError = false;
      _aiResponse = null;
    });

    try {
      final result = await ApiService.getAiAnomalies();

      if (!mounted) return;

      setState(() {
        _aiResponse = result;

        _response = AnomalyResponse(
          deviceId: result.deviceId,
          analyzedReadings: result.analyzedReadings,
          anomalyReadings: result.anomalyReadings,
          results: result.anomalies,
        );
      });
    } catch (error) {
      debugPrint('AI yorumu alınamadı: $error');

      if (!mounted) return;

      setState(() => _hasAiError = true);
    } finally {
      if (mounted) {
        setState(() => _isAiLoading = false);
      }
    }
  }

  void _refresh() {
    if (_isLoading || _isAiLoading) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _aiResponse = null;
      _hasAiError = false;
    });

    _loadAnomalies();
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.tryParse(timestamp);

    return date == null
        ? timestamp
        : DateFormat('dd.MM.yyyy HH.mm.ss').format(date.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final response = _response;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.latestAnalysisResults),
        actions: [
          IconButton(
            tooltip: l10n.refreshData,
            onPressed: _isLoading || _isAiLoading ? null : _refresh,
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
                child: Text(l10n.anomalyLoadFailed),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  response.deviceId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(l10n.measurementsAnalyzed(response.analyzedReadings)),
                const SizedBox(height: 8),
                Text(
                  l10n.latestAnalysisNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: _isAiLoading ? null : _analyzeWithAi,
                    label: Text(l10n.analyzeWithAi),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isAiLoading || _hasAiError || _aiResponse != null) ...[
                  AiAnalysisCard(
                    response: _aiResponse,
                    isLoading: _isAiLoading,
                    hasError: _hasAiError,
                  ),
                  const SizedBox(height: 12),
                ],

                if (_aiResponse != null) ...[
                  Text(
                    l10n.aiResultsScope,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                ],
                if (response.results.isEmpty)
                  Text(l10n.systemNormal)
                else
                  ...response.results.reversed.map(
                    (anomaly) => Card(
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
                    ),
                  ),
              ],
            ),
    );
  }
}
