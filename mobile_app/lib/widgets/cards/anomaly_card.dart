import 'package:flutter/material.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';

class AnomalyCard extends StatelessWidget {
  final AnomalyResponse? anomalyResponse;
  final AnomalyResult? latestAnomaly;
  final String? latestAnomalyTime;
  final VoidCallback? onTap;

  const AnomalyCard({
    super.key,
    required this.anomalyResponse,
    this.latestAnomaly,
    this.latestAnomalyTime,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final response = anomalyResponse;
    final l10n = AppLocalizations.of(context)!;

    final bool hasAnomaly = response != null && response.anomalyReadings > 0;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    response == null
                        ? Icons.hourglass_empty
                        : hasAnomaly
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l10n.anomalyStatus,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (response == null)
                Text(l10n.anomalyDataLoading)
              else if (!hasAnomaly)
                Text(l10n.systemNormal)
              else ...[
                Text(
                  l10n.anomaliesDetected(response.anomalyReadings),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                Text(l10n.measurementsAnalyzed(response.analyzedReadings)),

                if (latestAnomaly != null) ...[
                  const SizedBox(height: 8),
                  Text("${l10n.latestAnomaly}: ${latestAnomalyTime ?? '--'}"),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
