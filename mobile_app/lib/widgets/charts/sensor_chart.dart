import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_type.dart';
import 'package:sentinel/l10n/app_localizations.dart';

class SensorChart extends StatelessWidget {
  final SensorType sensorType;
  final List values;

  final List timestamps;

  final List? valuesX;
  final List? valuesY;
  final List? valuesZ;

  final bool isAcceleration;
  final bool isGyroscope;

  const SensorChart({
    super.key,

    required this.sensorType,
    required this.values,
    required this.timestamps,

    this.valuesX,
    this.valuesY,
    this.valuesZ,

    this.isAcceleration = false,
    this.isGyroscope = false,
  });

  List<double> _convertAccelerationToG(List values) {
    const double sensitivity = 16384.0;

    return values
        .map<double>((value) => value.toDouble() / sensitivity)
        .toList();
  }

  List<double> _convertGyroscopeToDps(List values) {
    const double sensitivity = 131.0;

    return values
        .map<double>((value) => value.toDouble() / sensitivity)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isThreeAxis = valuesX != null && valuesY != null && valuesZ != null;

    final chartValuesX = isAcceleration && valuesX != null
        ? _convertAccelerationToG(valuesX!)
        : isGyroscope && valuesX != null
        ? _convertGyroscopeToDps(valuesX!)
        : valuesX;

    final chartValuesY = isAcceleration && valuesY != null
        ? _convertAccelerationToG(valuesY!)
        : isGyroscope && valuesY != null
        ? _convertGyroscopeToDps(valuesY!)
        : valuesY;

    final chartValuesZ = isAcceleration && valuesZ != null
        ? _convertAccelerationToG(valuesZ!)
        : isGyroscope && valuesZ != null
        ? _convertGyroscopeToDps(valuesZ!)
        : valuesZ;

    final chartLength = isThreeAxis ? valuesX!.length : values.length;

    if (isThreeAxis
        ? valuesX!.isEmpty || valuesY!.isEmpty || valuesZ!.isEmpty
        : values.isEmpty) {
      return SizedBox(height: 250, child: Center(child: Text(l10n.noData)));
    }

    final (minY, maxY, horizontalInterval) = switch (sensorType) {
      SensorType.temperature => (10.0, 60.0, 5.0),
      SensorType.humidity => (20.0, 80.0, 10.0),
      SensorType.acceleration => (-2.0, 2.0, 0.5),
      SensorType.gyroscope => (-250.0, 250.0, 50.0),
    };

    return SizedBox(
      height: 360,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 4, right: 12),
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: (chartLength - 1).toDouble(),
                  minY: minY,
                  maxY: maxY,

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: horizontalInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.white.withValues(alpha: 0.12),
                        strokeWidth: 1,
                        dashArray: [6, 6],
                      );
                    },
                  ),

                  borderData: FlBorderData(show: true),

                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      getTooltipItems: (touchedSpots) {
                        const axisNames = ['X', 'Y', 'Z'];

                        return touchedSpots.asMap().entries.map((entry) {
                          final spot = entry.value;
                          final time = timestamps[spot.spotIndex];

                          final formattedTime =
                              "${time.hour.toString().padLeft(2, '0')}:"
                              "${time.minute.toString().padLeft(2, '0')}:"
                              "${time.second.toString().padLeft(2, '0')}";

                          final formattedValue = switch (sensorType) {
                            SensorType.temperature =>
                              '${spot.y.toStringAsFixed(1)} °C',
                            SensorType.humidity =>
                              '${spot.y.toStringAsFixed(1)} %',
                            SensorType.acceleration =>
                              '${spot.y.toStringAsFixed(2)} g',
                            SensorType.gyroscope =>
                              '${spot.y.toStringAsFixed(1)} °/s',
                          };

                          final axisLabel = isThreeAxis
                              ? '${axisNames[spot.barIndex]}: '
                              : '';

                          final valueColor =
                              spot.bar.color ?? Colors.cyanAccent;

                          if (entry.key == 0) {
                            return LineTooltipItem(
                              formattedTime,
                              const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: '\n$axisLabel$formattedValue',
                                  style: TextStyle(
                                    color: valueColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            );
                          }

                          return LineTooltipItem(
                            '$axisLabel$formattedValue',
                            TextStyle(
                              color: valueColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),

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
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          final yLabel = isAcceleration
                              ? '${value.toStringAsFixed(2)} g'
                              : isGyroscope
                              ? '${value.toStringAsFixed(1)} °/s'
                              : value.toStringAsFixed(1);

                          return Text(
                            yLabel,
                            style: const TextStyle(fontSize: 11),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: chartLength <= 6 ? 1 : (chartLength - 1) / 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();

                          if (index < 0 || index >= timestamps.length) {
                            return const SizedBox.shrink();
                          }

                          final time = timestamps[index];

                          return Text(
                            "${time.hour.toString().padLeft(2, '0')}:"
                            "${time.minute.toString().padLeft(2, '0')}:"
                            "${time.second.toString().padLeft(2, '0')}",
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: isThreeAxis
                      ? [
                          _buildLine(chartValuesX!, Colors.red),
                          _buildLine(chartValuesY!, Colors.green),
                          _buildLine(chartValuesZ!, Colors.blue),
                        ]
                      : [_buildLine(values)],
                ),
              ),
            ),
          ),

          if (isThreeAxis) ...[const SizedBox(height: 12), _buildLegend()],
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List values, [Color? color]) {
    return LineChartBarData(
      color: color,
      barWidth: 2,
      isCurved: true,
      curveSmoothness: 0.15,
      dotData: const FlDotData(show: false),
      spots: List.generate(
        values.length,
        (index) => FlSpot(index.toDouble(), values[index].toDouble()),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildLegendItem('X', Colors.red),
        const SizedBox(width: 20),
        _buildLegendItem('Y', Colors.green),
        const SizedBox(width: 20),
        _buildLegendItem('Z', Colors.blue),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
