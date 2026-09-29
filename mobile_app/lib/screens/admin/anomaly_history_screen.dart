import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/core/helpers/sensor_label_helper.dart';
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
  DateTimeRange? _dateRange;

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  int _listVersion = 0;

  bool get _isBusy => _isLoading || _isLoadingMore;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory({bool loadMore = false}) async {
    if (_isBusy) return;

    final previous = _response;
    final cursor = loadMore ? previous?.nextCursor : null;

    if (loadMore && cursor == null) return;

    setState(() {
      _hasError = false;

      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _response = null;
        _listVersion++;
      }
    });

    try {
      final page = await ApiService.getAnomalyHistory(
        from: _dateRange?.start,
        to: _dateRange?.end,
        limit: 2,
        cursor: cursor,
      );

      if (!mounted) return;

      final results = <AnomalyResult>[
        if (loadMore && previous != null) ...previous.results,
        ...page.results,
      ];

      setState(() {
        _response = AnomalyHistoryResponse(
          deviceId: page.deviceId,
          returnedCount: results.length,
          results: results,
          nextCursor: page.nextCursor,
        );
      });
    } catch (error) {
      debugPrint('Anomali geçmişi alınamadı: $error');

      if (!mounted) return;

      if (loadMore) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.historyLoadMoreFailed),
          ),
        );
      } else {
        setState(() => _hasError = true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _selectDateRange() async {
    if (_isBusy) return;

    final selected = await showDateRangePicker(
      context: context,
      initialDateRange: _dateRange,
      firstDate: DateTime(2000),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      helpText: AppLocalizations.of(context)!.historyDateRange,
    );

    if (!mounted || selected == null || _isBusy) return;

    setState(() => _dateRange = selected);
    await _loadHistory();
  }

  Future<void> _clearDateRange() async {
    if (_isBusy) return;

    setState(() => _dateRange = null);
    await _loadHistory();
  }

  String _formatTimestamp(String timestamp) {
    final date = DateTime.tryParse(timestamp);

    return date == null
        ? timestamp
        : DateFormat('dd.MM.yyyy HH:mm:ss').format(date.toLocal());
  }

  Widget _buildFilters(AppLocalizations l10n) {
    final range = _dateRange;

    final label = range == null
        ? l10n.historyDateRange
        : '${DateFormat('dd.MM.yyyy').format(range.start)}'
              ' – '
              '${DateFormat('dd.MM.yyyy').format(range.end)}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isBusy ? null : _selectDateRange,
              icon: const Icon(Icons.date_range),
              label: Text(label),
            ),
            if (range != null)
              TextButton(
                onPressed: _isBusy ? null : _clearDateRange,
                child: Text(l10n.historyClearFilter),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyResult anomaly, AppLocalizations l10n) {
    final sensors = anomaly.measurements.keys
        .map((field) => sensorLabel(field, l10n))
        .join(', ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
        title: Text(_formatTimestamp(anomaly.timestamp)),
        subtitle: Text('${l10n.affectedSensors}: $sensors'),
        children: [
          for (final entry in anomaly.measurements.entries)
            ListTile(
              title: Text(sensorLabel(entry.key, l10n)),
              subtitle: Text(
                '${l10n.measurementValue}: ${entry.value.value}\n'
                '${l10n.baselineMedian}: ${entry.value.median}\n'
                'Robust Z-score: ${entry.value.robustZScore}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final response = _response;

    if (_hasError || response == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(l10n.anomalyHistoryLoadFailed),
        ),
      );
    }

    return ListView.builder(
      key: ValueKey(_listVersion),
      padding: const EdgeInsets.all(16),
      itemCount: response.results.length + 2,
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
                Text(l10n.anomalyHistoryCount(response.results.length)),
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

        if (index == response.results.length + 1) {
          if (response.nextCursor == null) {
            return const SizedBox.shrink();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : OutlinedButton(
                      onPressed: () => _loadHistory(loadMore: true),
                      child: Text(l10n.historyLoadMore),
                    ),
            ),
          );
        }

        return _buildAnomalyCard(response.results[index - 1], l10n);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.savedHistoryTab),
        actions: [
          IconButton(
            tooltip: l10n.refreshData,
            onPressed: _isBusy ? null : () => _loadHistory(),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(l10n),
          Expanded(child: _buildContent(l10n)),
        ],
      ),
    );
  }
}
