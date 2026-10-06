import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/sensor_history_device.dart';

class VibrationDetailScreen extends StatelessWidget {
  final SensorHistoryService historyService;

  const VibrationDetailScreen({super.key, required this.historyService});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.vibrationHistory)),
      body: ListenableBuilder(
        listenable: historyService,
        builder: (context, _) {
          final history = historyService.history.toList()
            ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final firstValid = history.indexWhere(
            (r) => _valid(r.lastRmsG) || _valid(r.peakG),
          );

          if (firstValid < 0) {
            return Center(child: Text(l10n.noData));
          }

          final lastValid = history.lastIndexWhere(
            (r) => _valid(r.lastRmsG) || _valid(r.peakG),
          );
          // Trim empty edges only; preserve missing readings inside the range.
          final readings = history.sublist(firstValid, lastValid + 1);

          final origin = readings.first.timestamp;
          final span =
              readings.last.timestamp.difference(origin).inMilliseconds /
              1000.0;

          final maxX = span > 0 ? span : 15.0;

          final rmsSpots = _spots(readings, origin, (r) => r.lastRmsG);
          final peakSpots = _spots(readings, origin, (r) => r.peakG);

          var maximum = 0.0;
          for (final reading in readings) {
            for (final value in [reading.lastRmsG, reading.peakG]) {
              if (_valid(value) && value! > maximum) maximum = value;
            }
          }

          final maxY = maximum > 0 ? maximum * 1.15 : 0.01;
          final colors = [
            Theme.of(context).colorScheme.primary,
            Colors.lightBlue,
          ];
          final labels = [l10n.vibrationLastRms, l10n.vibrationIntervalPeak];
          final dateFormat = DateFormat('dd.MM HH:mm:ss');

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.show_chart, color: colors[i]),
                          const SizedBox(width: 8),
                          Text(labels[i]),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 320,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 72,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) => Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Text(
                                  '${value.toStringAsFixed(3)} g',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          fitInsideHorizontally: true,
                          fitInsideVertically: true,
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final time = origin.add(
                                Duration(milliseconds: (spot.x * 1000).round()),
                              );

                              return LineTooltipItem(
                                '${dateFormat.format(time.toLocal())}\n'
                                '${labels[spot.barIndex]}\n'
                                '${spot.y.toStringAsFixed(4)} g',
                                TextStyle(
                                  color: colors[spot.barIndex],
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                      lineBarsData: [
                        for (var i = 0; i < 2; i++)
                          LineChartBarData(
                            spots: i == 0 ? rmsSpots : peakSpots,
                            color: colors[i],
                            barWidth: 2,
                            isCurved: false,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, bar, index) =>
                                  FlDotCirclePainter(
                                    radius: 2,
                                    color: colors[i],
                                    strokeWidth: 0,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Text(dateFormat.format(origin.toLocal())),
                    Text(dateFormat.format(readings.last.timestamp.toLocal())),
                  ],
                ),
                if (readings.any((r) => r.vibrationSaturated == true))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.vibrationSaturationWarning),
                  ),
                if (readings.any((r) => r.vibrationSamplingError == true))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(l10n.vibrationSamplingWarning),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  static bool _valid(double? value) =>
      value != null && value.isFinite && value >= 0;

  static List<FlSpot> _spots(
    List<SensorData> readings,
    DateTime origin,
    double? Function(SensorData) select,
  ) {
    final spots = <FlSpot>[];
    DateTime? previousTime;

    for (final reading in readings) {
      final previous = previousTime;
      if (previous != null &&
          reading.timestamp.difference(previous) >
              const Duration(seconds: 45)) {
        spots.add(FlSpot.nullSpot);
      }

      final value = select(reading);
      spots.add(
        _valid(value)
            ? FlSpot(
                reading.timestamp.difference(origin).inMilliseconds / 1000.0,
                value!,
              )
            : FlSpot.nullSpot,
      );

      previousTime = reading.timestamp;
    }

    return spots;
  }
}
