import 'package:flutter/material.dart';
import 'package:sentinel/models/anomaly.dart';

class AnomalyScreen extends StatelessWidget {
  final AnomalyResponse anomalyResponse;

  const AnomalyScreen({super.key, required this.anomalyResponse});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Anomaliler")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatistic(
                    title: "Anomali",
                    value: anomalyResponse.anomalyReadings.toString(),
                  ),
                  _buildStatistic(
                    title: "Analiz",
                    value: anomalyResponse.analyzedReadings.toString(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          ...anomalyResponse.results.map(
            (anomaly) => _buildAnomalyCard(anomaly),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyResult anomaly) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(anomaly.timestamp),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              "${anomaly.anomalyCount} anomalik sensör",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            ...anomaly.measurements.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text("Robust Z: ${entry.value.robustZScore}"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Column _buildStatistic({required String title, required String value}) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

String _formatTimestamp(String timestamp) {
  final dateTime = DateTime.tryParse(timestamp);

  if (dateTime == null) {
    return timestamp;
  }

  return "${dateTime.day.toString().padLeft(2, '0')}."
      "${dateTime.month.toString().padLeft(2, '0')}."
      "${dateTime.year} "
      "${dateTime.hour.toString().padLeft(2, '0')}:"
      "${dateTime.minute.toString().padLeft(2, '0')}:"
      "${dateTime.second.toString().padLeft(2, '0')}";
}
