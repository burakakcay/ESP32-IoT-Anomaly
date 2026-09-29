import 'package:sentinel/l10n/app_localizations.dart';

String sensorLabel(String field, AppLocalizations l10n) {
  return switch (field) {
    'temperature' => l10n.temperature,
    'humidity' => l10n.humidity,
    'accel_x' => l10n.sensorAxisLabel(l10n.acceleration, 'X'),
    'accel_y' => l10n.sensorAxisLabel(l10n.acceleration, 'Y'),
    'accel_z' => l10n.sensorAxisLabel(l10n.acceleration, 'Z'),
    'gyro_x' => l10n.sensorAxisLabel(l10n.gyroscope, 'X'),
    'gyro_y' => l10n.sensorAxisLabel(l10n.gyroscope, 'Y'),
    'gyro_z' => l10n.sensorAxisLabel(l10n.gyroscope, 'Z'),
    _ => field,
  };
}
