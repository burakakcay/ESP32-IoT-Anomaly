import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/widgets/common/status_dot.dart';

class SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String? unit;
  final IconData icon;
  final SensorStatus status;

  const SensorCard({
    super.key,
    required this.title,
    required this.value,
    this.unit,
    required this.icon,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            Center(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: value,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (unit != null)
                      TextSpan(
                        text: " $unit",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const Spacer(),
            Align(
              alignment: Alignment.center,
              child: StatusDot(status: status),
            ),
          ],
        ),
      ),
    );
  }
}
