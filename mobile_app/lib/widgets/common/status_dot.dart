/// Sensör durumunu renkli bir nokta ve isteğe bağlı etiketle gösterir.
library;

import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/core/theme/app_colors.dart';
import 'package:sentinel/l10n/app_localizations.dart';

class StatusDot extends StatelessWidget {
  final SensorStatus status;
  final bool showLabel;
  final String? label;

  const StatusDot({
    super.key,
    required this.status,
    this.showLabel = true,
    this.label,
  });

  Color get statusColor {
    switch (status) {
      case SensorStatus.normal:
        return AppColors.normal;
      case SensorStatus.warning:
        return AppColors.warning;
      case SensorStatus.danger:
        return AppColors.high;
      case SensorStatus.critical:
        return AppColors.critical;
    }
  }

  String statusText(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    switch (status) {
      case SensorStatus.normal:
        return l10n.normal;

      case SensorStatus.warning:
        return l10n.warning;

      case SensorStatus.danger:
        return l10n.high;

      case SensorStatus.critical:
        return l10n.critical;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),

        if (showLabel) ...[
          const SizedBox(width: 8),

          Text(
            label ?? statusText(context),
            style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }
}
