import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';

class SensorChart extends StatelessWidget {
  final List values;
  final List timestamps;

  final List? valuesX;
  final List? valuesY;
  final List? valuesZ;

  final bool isAcceleration;
  final bool isGyroscope;

  const SensorChart({
    super.key,
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
    final List<double> allValues;

    if (isThreeAxis) {
      allValues = [
        ...chartValuesX!.map<double>((e) => e.toDouble()),
        ...chartValuesY!.map<double>((e) => e.toDouble()),
        ...chartValuesZ!.map<double>((e) => e.toDouble()),
      ];
    } else {
      allValues = values.map<double>((e) => e.toDouble()).toList();
    }

    final double minValue = allValues.reduce((a, b) => a < b ? a : b);

    final double maxValue = allValues.reduce((a, b) => a > b ? a : b);

    final range = maxValue - minValue;

    final padding = range == 0 ? 1.0 : range * 0.15;

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
                  minY: minValue - padding,
                  maxY: maxValue + padding,

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: range == 0 ? 0.5 : range / 5,
                    verticalInterval: 5,
                  ),

                  borderData: FlBorderData(show: true),

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
