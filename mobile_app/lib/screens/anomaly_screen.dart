import 'package:flutter/material.dart';
import 'package:sentinel/models/anomaly.dart';
import 'package:sentinel/services/api_service.dart';
import 'package:sentinel/widgets/cards/ai_analysis_card.dart';

class AnomalyScreen extends StatefulWidget {
  final AnomalyResponse anomalyResponse;

  const AnomalyScreen({super.key, required this.anomalyResponse});

  @override
  State<AnomalyScreen> createState() => _AnomalyScreenState();
}

class _AnomalyScreenState extends State<AnomalyScreen> {
  AiAnomalyResponse? _aiAnomalyResponse;

  @override
  void initState() {
    super.initState();
    _fetchAiAnomalies();
  }

  Future<void> _fetchAiAnomalies() async {
    try {
      final data = await ApiService.getAiAnomalies();

      if (!mounted) return;

      setState(() {
        _aiAnomalyResponse = data;
      });
    } catch (e) {
      debugPrint('AI anomali verileri alınamadı: $e');
    }
  }
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
                    value: widget.anomalyResponse.anomalyReadings.toString(),
                  ),
                  _buildStatistic(
                    title: "Analiz",
                    value: widget.anomalyResponse.analyzedReadings.toString(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          AiAnalysisCard(response: _aiAnomalyResponse),

          const SizedBox(height: 16),

          ...widget.anomalyResponse.results.reversed.map(
            (anomaly) => _buildAnomalyCard(anomaly),
          ),
        ],
      ),
    );
  }

  Widget _buildAnomalyCard(AnomalyResult anomaly) {
    final affectedSensors = anomaly.measurements.keys.join(', ');

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
            const SizedBox(height: 12),
            Text(
              '${anomaly.anomalyCount} sensörde olağan dışı değişim tespit edildi.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Etkilenen sensörler: $affectedSensors'),
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
