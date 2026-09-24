import 'package:flutter/material.dart';
import 'package:sentinel/core/theme/app_colors.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';

class AiAnalysisCard extends StatelessWidget {
  final AiAnomalyResponse? response;
  final bool isLoading;
  final bool hasError;

  const AiAnalysisCard({
    super.key,
    required this.response,
    required this.isLoading,
    required this.hasError,
  });

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return AppColors.critical;
      case 'high':
        return AppColors.high;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.normal;
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aiAnalysis = response?.aiAnalysis;

    if (isLoading || hasError || aiAnalysis == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isLoading ? l10n.aiAnalysisLoading : l10n.aiAnalysisFailed,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _severityIcon(aiAnalysis.severity),
                  color: _severityColor(aiAnalysis.severity),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.aiAnalysis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(aiAnalysis.summary),
            if (aiAnalysis.possibleCause != null) ...[
              const SizedBox(height: 12),
              Text(
                l10n.possibleCause,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(aiAnalysis.possibleCause!),
            ],
            if (aiAnalysis.affectedSensors.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                l10n.affectedSensors,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(aiAnalysis.affectedSensors.join(', ')),
            ],
          ],
        ),
      ),
    );
  }
}
