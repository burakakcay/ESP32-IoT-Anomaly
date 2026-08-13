import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/core/enums/sensor_type.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/screens/anomaly_screen.dart';
import 'package:sentinel/screens/sensor_detail_screen.dart';
import 'package:sentinel/services/api_service.dart';
import 'package:sentinel/services/sensor_history_device.dart';
// import 'package:sentinel/services/sensor_service.dart';
import 'package:sentinel/widgets/cards/acceleration_card.dart';
import 'package:sentinel/widgets/cards/anomaly_card.dart';
import 'package:sentinel/widgets/cards/device_info_card.dart';
import 'package:sentinel/widgets/cards/gyroscope_card.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // ==========================================================
  // Services
  // ==========================================================

  // final SensorService _sensorService = SensorService();
  final SensorHistoryService _historyService = SensorHistoryService();

  void _openSensorDetail(SensorType type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SensorDetailScreen(
          sensorType: type,
          historyService: _historyService,
        ),
      ),
    );
  }

  // ==========================================================
  // State Variables
  // ==========================================================

  SensorData? _sensorData;
  Timer? _refreshTimer;
  Timer? _anomalyTimer;

  bool _isConnected = false;
  int _packetCount = 0;

  // ==========================================================
  // Lifecycle Methods
  // ==========================================================
  @override
  void initState() {
    super.initState();

    _fetchSensorData();

    _fetchAnomalies();

    // _refreshTimer = Timer.periodic(
    //   const Duration(seconds: 2),
    //   (_) => _fetchSensorData(),
    // );

    // _anomalyTimer = Timer.periodic(
    //   const Duration(seconds: 10),
    //   (_) => _fetchAnomalies(),
    // );
  }

  // ==========================================================
  // Data Loading
  // ==========================================================
  Future<void> _fetchSensorData() async {
    try {
      final data = await ApiService.getLatestSensorData();

      if (!mounted) return;

      setState(() {
        _sensorData = data;
        _isConnected = true;
        _packetCount++;
      });
    } catch (e) {
      debugPrint("Sensör verisi okunamadı: $e");
    }
  }

  // ==========================================================
  // Anomaly Data
  // ==========================================================

  AnomalyResponse? _anomalyResponse;

  AnomalyResult? get _latestAnomaly {
    if (_anomalyResponse == null || _anomalyResponse!.results.isEmpty) {
      return null;
    }

    return _anomalyResponse!.results.last;
  }

  Future<void> _fetchAnomalies() async {
    try {
      final data = await ApiService.getAnomalies();

      for (final result in data.results) {
        debugPrint(
          "${result.timestamp} | "
          "Anomali sayısı: ${result.anomalyCount}",
        );
      }

      if (!mounted) return;

      setState(() {
        _anomalyResponse = data;
      });
    } catch (e) {
      debugPrint("Anomali verileri alınamadı: $e");
    }
  }

  String? get _latestAnomalyTime {
    final anomaly = _latestAnomaly;

    if (anomaly == null) {
      return null;
    }

    final dateTime = DateTime.tryParse(anomaly.timestamp);

    if (dateTime == null) {
      return anomaly.timestamp;
    }

    return "${dateTime.day.toString().padLeft(2, '0')}."
        "${dateTime.month.toString().padLeft(2, '0')}."
        "${dateTime.year} "
        "${dateTime.hour.toString().padLeft(2, '0')}:"
        "${dateTime.minute.toString().padLeft(2, '0')}:"
        "${dateTime.second.toString().padLeft(2, '0')}";
  }

  // ==========================================================
  // UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: const Text("Sentinel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DeviceInfoCard(
              deviceId: _sensorData?.deviceId ?? "ESP32_Node_001",
              lastUpdate: _sensorData?.timestamp ?? DateTime.now(),
              isConnected: _isConnected,
              packetCount: _packetCount,
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.95,
              children: [
                SensorCard(
                  title: l10n.temperature,
                  value: _sensorData == null
                      ? "--"
                      : _sensorData!.temperature.toStringAsFixed(1),
                  unit: "°C",
                  icon: Icons.thermostat,
                  status: _sensorData == null
                      ? SensorStatus.normal
                      : SensorStatusHelper.getTemperatureStatus(
                          _sensorData!.temperature,
                        ),
                  onTap: () => _openSensorDetail(SensorType.temperature),
                ),

                SensorCard(
                  title: l10n.humidity,
                  value: _sensorData == null
                      ? "--"
                      : _sensorData!.humidity.toStringAsFixed(1),
                  unit: "%",
                  icon: Icons.water_drop,
                  status: _sensorData == null
                      ? SensorStatus.normal
                      : SensorStatusHelper.getHumidityStatus(
                          _sensorData!.humidity,
                        ),
                  onTap: () => _openSensorDetail(SensorType.humidity),
                ),

                AccelerationCard(
                  acceleration: _sensorData?.acceleration,
                  onTap: () => _openSensorDetail(SensorType.acceleration),
                ),

                GyroscopeCard(
                  gyroscope: _sensorData?.gyroscope,
                  onTap: () => _openSensorDetail(SensorType.gyroscope),
                ),
              ],
            ),

            const SizedBox(height: 16),

            AnomalyCard(
              anomalyResponse: _anomalyResponse,
              latestAnomaly: _latestAnomaly,
              latestAnomalyTime: _latestAnomalyTime,
              onTap: _anomalyResponse == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              AnomalyScreen(anomalyResponse: _anomalyResponse!),
                        ),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _anomalyTimer?.cancel();
    super.dispose();
  }
}
