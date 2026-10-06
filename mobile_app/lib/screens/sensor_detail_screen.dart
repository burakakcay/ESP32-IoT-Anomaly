import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_type.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/services/sensor_history_device.dart';
import 'package:sentinel/widgets/charts/sensor_chart.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/api_service.dart';

class SensorDetailScreen extends StatefulWidget {
  final SensorType sensorType;
  final SensorHistoryService historyService;

  const SensorDetailScreen({
    super.key,
    required this.sensorType,
    required this.historyService,
  });

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  SensorType get sensorType => widget.sensorType;
  SensorHistoryService get historyService => widget.historyService;

  late DateTime _from;
  late DateTime _to;

  List<SensorData> _filteredReadings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAppliedFilter = false;

  @override
  void initState() {
    super.initState();

    _to = DateTime.now();
    _from = _to.subtract(const Duration(hours: 1));
  }

  Future<void> _loadFilteredReadings() async {
    if (_isLoading) return;

    if (!_from.isBefore(_to)) {
      setState(() {
        _errorMessage = 'Başlangıç zamanı bitişten önce olmalıdır.';
      });
      return;
    }

    final from = _from;
    final to = _to;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final readings = await ApiService.getReadingsInRange(from: from, to: to);

      if (!mounted) return;

      setState(() {
        _filteredReadings = readings;
        _hasAppliedFilter = true;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final current = isStart ? _from : _to;

    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );

    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      if (isStart) {
        _from = selected;
      } else {
        _to = selected;
      }

      _errorMessage = null;
    });
  }

  Widget _buildDateFilter() {
    final material = MaterialLocalizations.of(context);

    String formatDateTime(DateTime value) {
      final date = material.formatShortDate(value);
      final time = material.formatTimeOfDay(
        TimeOfDay.fromDateTime(value),
        alwaysUse24HourFormat: true,
      );

      return '$date $time';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _isLoading ? null : () => _pickDateTime(isStart: true),
              icon: const Icon(Icons.calendar_today),
              label: Text('Başlangıç: ${formatDateTime(_from)}'),
            ),
            OutlinedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () => _pickDateTime(isStart: false),
              icon: const Icon(Icons.calendar_today),
              label: Text('Bitiş: ${formatDateTime(_to)}'),
            ),
            FilledButton(
              onPressed: _isLoading ? null : _loadFilteredReadings,
              child: const Text('Uygula'),
            ),
          ],
        ),
        if (_isLoading) ...[
          const SizedBox(height: 12),
          const LinearProgressIndicator(),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }

  String getTitle(AppLocalizations l10n) {
    switch (sensorType) {
      case SensorType.temperature:
        return l10n.temperature;
      case SensorType.humidity:
        return l10n.humidity;
      case SensorType.acceleration:
        return l10n.acceleration;
      case SensorType.gyroscope:
        return l10n.gyroscope;
    }
  }

  List<double> getChartValues() {
    switch (sensorType) {
      case SensorType.temperature:
        return historyService.temperatures;

      case SensorType.humidity:
        return historyService.humidities;

      case SensorType.acceleration:
      case SensorType.gyroscope:
        return [];
    }
  }

  List<double>? getChartValuesX() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationX
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeX
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  List<double>? getChartValuesY() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationY
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeY
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  List<double>? getChartValuesZ() {
    switch (sensorType) {
      case SensorType.acceleration:
        return historyService.accelerationZ
            .map((value) => value.toDouble())
            .toList();
      case SensorType.gyroscope:
        return historyService.gyroscopeZ
            .map((value) => value.toDouble())
            .toList();
      case SensorType.temperature:
      case SensorType.humidity:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final useFilteredData =
        sensorType == SensorType.temperature && _hasAppliedFilter;

    final validReadings = _filteredReadings
        .where((reading) => reading.temperature != null)
        .toList();

    final chartValues = useFilteredData
        ? validReadings.map((reading) => reading.temperature!).toList()
        : getChartValues();

    final chartTimestamps = useFilteredData
        ? validReadings.map((reading) => reading.timestamp).toList()
        : switch (sensorType) {
            SensorType.temperature => historyService.temperatureTimestamps,
            SensorType.humidity => historyService.humidityTimestamps,
            _ => historyService.timestamps,
          };

    final double? min = chartValues.isEmpty
        ? null
        : chartValues.reduce((a, b) => a < b ? a : b);

    final double? max = chartValues.isEmpty
        ? null
        : chartValues.reduce((a, b) => a > b ? a : b);

    final double? average = chartValues.isEmpty
        ? null
        : chartValues.fold<double>(0, (sum, value) => sum + value) /
              chartValues.length;

    final unit = sensorType == SensorType.temperature ? "°C" : "%";

    return Scaffold(
      appBar: AppBar(title: Text(getTitle(l10n))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (sensorType == SensorType.temperature) ...[
              _buildDateFilter(),
              const SizedBox(height: 24),
            ],

            Icon(sensorType.icon, size: 72),

            const SizedBox(height: 24),

            Text(
              sensorType.getTitle(l10n),
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            if (sensorType == SensorType.temperature ||
                sensorType == SensorType.humidity)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatistic(
                        title: l10n.minimum,
                        value: min,
                        unit: unit,
                      ),
                      _buildStatistic(
                        title: l10n.average,
                        value: average,
                        unit: unit,
                      ),
                      _buildStatistic(
                        title: l10n.maximum,
                        value: max,
                        unit: unit,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            SensorChart(
              sensorType: sensorType,
              values: chartValues,
              timestamps: chartTimestamps,
              valuesX: getChartValuesX(),
              valuesY: getChartValuesY(),
              valuesZ: getChartValuesZ(),
              isAcceleration: sensorType == SensorType.acceleration,
              isGyroscope: sensorType == SensorType.gyroscope,
            ),
          ],
        ),
      ),
    );
  }
}

Column _buildStatistic({
  required String title,
  double? value,
  required String unit,
}) {
  return Column(
    children: [
      Text(title, style: const TextStyle(fontSize: 14)),
      const SizedBox(height: 4),
      Text(
        value == null ? "--" : "${value.toStringAsFixed(1)} $unit",
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ],
  );
}
