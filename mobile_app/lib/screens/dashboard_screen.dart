import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:sentinel/core/enums/sensor_status.dart';
import 'package:sentinel/core/enums/sensor_type.dart';
import 'package:sentinel/core/helpers/sensor_status_helper.dart';
import 'package:sentinel/l10n/app_localizations.dart';
import 'package:sentinel/models/anomaly.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/screens/anomaly_screen.dart';
import 'package:sentinel/screens/sensor_detail_screen.dart';
import 'package:sentinel/services/api_service.dart';
import 'package:sentinel/services/auth_service.dart';
import 'package:sentinel/services/sensor_history_device.dart';
import 'package:sentinel/widgets/cards/acceleration_card.dart';
import 'package:sentinel/widgets/cards/anomaly_card.dart';
import 'package:sentinel/widgets/cards/device_info_card.dart';
import 'package:sentinel/widgets/cards/gyroscope_card.dart';
import 'package:sentinel/widgets/cards/sensor_card.dart';
import 'package:sentinel/core/enums/device_connection_status.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Hizmetler

  bool _isSigningOut = false;

  Future<void> _signOut() async {
    if (_isSigningOut) return;

    setState(() => _isSigningOut = true);

    try {
      await AuthService.signOut();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.signOutFailed)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

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

  DeviceConnectionStatus _statusForError(Object error) {
    if (error is http.ClientException || error is TimeoutException) {
      return DeviceConnectionStatus.serverUnavailable;
    }

    return DeviceConnectionStatus.dataError;
  }

  // Durum değişkenleri

  SensorData? _sensorData;
  Timer? _refreshTimer;
  bool _isFetching = false;

  DeviceConnectionStatus _connectionStatus = DeviceConnectionStatus.checking;

  // Yaşam döngüsü
  @override
  void initState() {
    super.initState();

    _fetchDashboardData();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _sensorData == null ? _fetchDashboardData() : _fetchSensorData(),
    );
  }

  // Veri yükleme
  Future<void> _fetchDashboardData() async {
    if (_isFetching) return;
    _isFetching = true;
    setState(() => _connectionStatus = DeviceConnectionStatus.checking);

    try {
      final data = await ApiService.getDashboardData();

      if (data.readings.isEmpty) {
        throw Exception("Sensör geçmişi bulunamadı.");
      }

      if (!mounted) return;

      for (final reading in data.readings) {
        _historyService.add(reading);
      }

      final latestReading = data.readings.last;

      final isRecentReading =
          DateTime.now().difference(latestReading.timestamp) <=
          const Duration(seconds: 45);

      setState(() {
        _sensorData = latestReading;
        _connectionStatus = isRecentReading
            ? DeviceConnectionStatus.online
            : DeviceConnectionStatus.stale;
        _anomalyResponse = data.anomalies;
      });
    } catch (e, stackTrace) {
      debugPrint("Dashboard verileri alınamadı: $e");
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _connectionStatus = _statusForError(e);
      });
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _fetchSensorData() async {
    if (_isFetching) return;
    _isFetching = true;
    try {
      final data = await ApiService.getLatestSensorData();

      if (!mounted) return;

      final isRecentReading =
          DateTime.now().difference(data.timestamp) <=
          const Duration(seconds: 45);

      setState(() {
        _sensorData = data;
        _connectionStatus = isRecentReading
            ? DeviceConnectionStatus.online
            : DeviceConnectionStatus.stale;
      });

      _historyService.add(data);
    } catch (e) {
      debugPrint("Sensör verisi okunamadı: $e");

      if (!mounted) return;

      setState(() {
        _connectionStatus = _statusForError(e);
      });
    } finally {
      _isFetching = false;
    }
  }

  // Anomali verileri

  AnomalyResponse? _anomalyResponse;

  AnomalyResult? get _latestAnomaly {
    if (_anomalyResponse == null || _anomalyResponse!.results.isEmpty) {
      return null;
    }

    return _anomalyResponse!.results.last;
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

  // Kullanıcı arayüzü

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName),
        actions: [
          IconButton(
            tooltip: l10n.signOutButton,
            onPressed: _isSigningOut ? null : _signOut,
            icon: _isSigningOut
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DeviceInfoCard(
              deviceId: _sensorData?.deviceId ?? "ESP32_Node_001",
              lastUpdate: _sensorData?.timestamp,
              connectionStatus: _connectionStatus,
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
                  value: _sensorData?.temperature?.toStringAsFixed(1) ?? "--",
                  unit: "°C",
                  icon: Icons.thermostat,
                  status: _sensorData?.temperature == null
                      ? SensorStatus.normal
                      : SensorStatusHelper.getTemperatureStatus(
                          _sensorData!.temperature!,
                        ),
                  onTap: () => _openSensorDetail(SensorType.temperature),
                ),

                SensorCard(
                  title: l10n.humidity,
                  value: _sensorData?.humidity?.toStringAsFixed(1) ?? "--",
                  unit: "%",
                  icon: Icons.water_drop,
                  status: _sensorData?.humidity == null
                      ? SensorStatus.normal
                      : SensorStatusHelper.getHumidityStatus(
                          _sensorData!.humidity!,
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
    super.dispose();
  }
}
