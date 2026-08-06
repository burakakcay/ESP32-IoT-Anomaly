import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/sensor_service.dart';
import 'package:sentinel/widgets/cards/device_info_card.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SensorService _sensorService = SensorService();

  SensorData? sensorData;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadSensor();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => loadSensor(),
    );
  }

  Future<void> loadSensor() async {
    try {
      final data = await _sensorService.fetchSensorData();

      if (!mounted) return;
      setState(() {
        sensorData = data;
      });
    } catch (e) {
      debugPrint("Sensör verisi alınamadı: $e");
    }
  }

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
              deviceId: sensorData?.deviceId ?? "ESP32_Node_001",
              lastUpdate: sensorData?.timestamp ?? DateTime.now(),
              isConnected: true,
            ),

            const SizedBox(height: 16),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                SensorCard(
                  title: l10n.temperature,
                  value: sensorData == null
                      ? "--"
                      : sensorData!.temperature.toStringAsFixed(1),
                  unit: "°C",
                  icon: Icons.thermostat,
                  status: SensorStatus.normal,
                ),
                SensorCard(
                  title: l10n.humidity,
                  value: sensorData == null
                      ? "--"
                      : sensorData!.humidity.toStringAsFixed(1),
                  unit: "%",
                  icon: Icons.water_drop,
                  status: SensorStatus.normal,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
