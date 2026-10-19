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
  bool get _supportsHistory => switch (sensorType) {
    SensorType.temperature ||
    SensorType.humidity ||
    SensorType.acceleration ||
    SensorType.gyroscope => true,
  };

  double? _measurement(SensorData reading) {
    return switch (sensorType) {
      SensorType.temperature => reading.temperature,
      SensorType.humidity => reading.humidity,
      _ => null,
    };
  }

  late DateTime _from;
  late DateTime _to;
  DateTime? _appliedFrom;
  DateTime? _appliedTo;
  DateTime? _chartFrom;
  DateTime? _chartTo;

  List<SensorData> _filteredReadings = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasAppliedFilter = false;
  bool _fitYAxis = false;

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
        _filteredReadings = List<SensorData>.of(readings)
          ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _hasAppliedFilter = true;
        _appliedFrom = from;
        _appliedTo = to;
        _chartFrom = from;
        _chartTo = to;
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

  void _changeChartView({double zoomFactor = 1, double shiftFraction = 0}) {
    if (_appliedFrom == null ||
        _appliedTo == null ||
        _chartFrom == null ||
        _chartTo == null) {
      return;
    }

    final totalMs = _appliedTo!.difference(_appliedFrom!).inMilliseconds;

    final currentMs = _chartTo!.difference(_chartFrom!).inMilliseconds;

    // En fazla bir dakikalık pencereye kadar yaklaş.
    final minimumMs = totalMs < 60000 ? totalMs : 60000;

    final newMs = (currentMs * zoomFactor)
        .round()
        .clamp(minimumMs, totalMs)
        .toInt();

    final currentOffset = _chartFrom!.difference(_appliedFrom!).inMilliseconds;

    // Yakınlaştırırken merkezi koru; oklarla pencereyi kaydır.
    final newOffset =
        (currentOffset + (currentMs - newMs) / 2 + currentMs * shiftFraction)
            .round()
            .clamp(0, totalMs - newMs)
            .toInt();

    setState(() {
      _chartFrom = _appliedFrom!.add(Duration(milliseconds: newOffset));

      _chartTo = _chartFrom!.add(Duration(milliseconds: newMs));
    });
  }

  void _resetChartView() {
    setState(() {
      _chartFrom = _appliedFrom;
      _chartTo = _appliedTo;
    });
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
            FilterChip(
              label: const Text('Y eksenini veriye uydur.'),
              selected: _fitYAxis,
              onSelected: _isLoading
                  ? null
                  : (selected) {
                      setState(() {
                        _fitYAxis = selected;
                      });
                    },
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

    final useFilteredData = _supportsHistory && _hasAppliedFilter;

    final isThreeAxis =
        sensorType == SensorType.acceleration ||
        sensorType == SensorType.gyroscope;

    final validReadings = _filteredReadings.where((reading) {
      if (isThreeAxis) return true;

      return _measurement(reading)?.isFinite ?? false;
    }).toList();

    final chartValues = useFilteredData
        ? isThreeAxis
              ? <double>[]
              : validReadings.map((reading) => _measurement(reading)!).toList()
        : getChartValues();

    final chartTimestamps = useFilteredData
        ? validReadings.map((reading) => reading.timestamp).toList()
        : switch (sensorType) {
            SensorType.temperature => historyService.temperatureTimestamps,
            SensorType.humidity => historyService.humidityTimestamps,
            _ => historyService.timestamps,
          };

    List<double>? axisValues(
      double Function(SensorData) select,
      List<double>? fallback,
    ) {
      if (!useFilteredData) return fallback;
      if (!isThreeAxis) return null;

      return validReadings.map(select).toList();
    }

    final chartValuesX = axisValues(
      (reading) => sensorType == SensorType.acceleration
          ? reading.acceleration.x.toDouble()
          : reading.gyroscope.x.toDouble(),
      getChartValuesX(),
    );

    final chartValuesY = axisValues(
      (reading) => sensorType == SensorType.acceleration
          ? reading.acceleration.y.toDouble()
          : reading.gyroscope.y.toDouble(),
      getChartValuesX(),
    );

    final chartValuesZ = axisValues(
      (reading) => sensorType == SensorType.acceleration
          ? reading.acceleration.z.toDouble()
          : reading.gyroscope.z.toDouble(),
      getChartValuesX(),
    );

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
            if (_supportsHistory) ...[
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

            if (useFilteredData) ...[
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  IconButton(
                    tooltip: "Önceki saatlere kaydır.",
                    onPressed: _isLoading
                        ? null
                        : () => _changeChartView(shiftFraction: -0.25),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  IconButton(
                    tooltip: "Uzaklaştır",
                    onPressed: _isLoading
                        ? null
                        : () => _changeChartView(zoomFactor: 2),
                    icon: const Icon(Icons.remove),
                  ),
                  OutlinedButton(
                    onPressed: _isLoading ? null : _resetChartView,
                    child: const Text('Sıfırla'),
                  ),
                  IconButton(
                    tooltip: 'Yakınlaştır',
                    onPressed: _isLoading
                        ? null
                        : () => _changeChartView(zoomFactor: 0.5),
                    icon: const Icon(Icons.add),
                  ),
                  IconButton(
                    tooltip: 'Sonraki saatlere kaydır',
                    onPressed: _isLoading
                        ? null
                        : () => _changeChartView(shiftFraction: 0.25),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],

            SensorChart(
              sensorType: sensorType,
              values: chartValues,
              timestamps: chartTimestamps,
              rangeStart: useFilteredData ? _chartFrom : null,
              rangeEnd: useFilteredData ? _chartTo : null,
              valuesX: chartValuesX,
              valuesY: chartValuesY,
              valuesZ: chartValuesZ,
              isAcceleration: sensorType == SensorType.acceleration,
              isGyroscope: sensorType == SensorType.gyroscope,
              fitYAxis: _fitYAxis,
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
