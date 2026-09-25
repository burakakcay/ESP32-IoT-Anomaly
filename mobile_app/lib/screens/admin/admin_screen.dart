import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentinel/data/demo_devices.dart';
import 'package:sentinel/models/device_summary.dart';
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/screens/admin/admin_anomalies_screen.dart';
import 'package:sentinel/screens/admin/admin_overview_screen.dart';
import 'package:sentinel/screens/admin/admin_shell.dart';
import 'package:sentinel/screens/admin/demo_devices_screen.dart';
import 'package:sentinel/screens/admin/devices_screen.dart';
import 'package:sentinel/screens/dashboard_screen.dart';
import 'package:sentinel/services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _selectedIndex = 0;
  SensorData? _lastReading;
  Timer? _refreshTimer;

  bool _isFetching = false;
  bool _isDetailOpen = false;

  @override
  void initState() {
    super.initState();
    _refreshDevices();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshDevices(),
    );
  }

  Future<void> _refreshDevices() async {
    if (_isFetching || _isDetailOpen) return;

    _isFetching = true;

    try {
      final reading = await ApiService.getLatestSensorData();

      if (!mounted) return;

      setState(() {
        _lastReading = reading;
      });
    } catch (error) {
      debugPrint('Cihaz özeti alınamadı: $error');

      // Son ölçümü korur; zaman ilerledikçe güncellik yeniden hesaplanır.
      if (!mounted) return;
      setState(() {});
    } finally {
      _isFetching = false;
    }
  }

  void _onReadingUpdated(SensorData reading) {
    if (!mounted) return;

    setState(() {
      _lastReading = reading;
    });
  }

  Future<void> _openDevice(DeviceSummary device) async {
    if (_isDetailOpen) return;

    _isDetailOpen = true;

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => device.isDemo
              ? DemoDevicesScreen(device: device)
              : DashboardScreen(
                  title: device.id,
                  onReadingUpdated: _onReadingUpdated,
                ),
        ),
      );
    } finally {
      _isDetailOpen = false;

      if (mounted) {
        _refreshDevices();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = [
      DeviceSummary(
        id: _lastReading?.deviceId ?? 'ESP32_Sensor_Node_001',
        lastReading: _lastReading,
      ),
      ...createDemoDevices(DateTime.now()),
    ];

    return AdminShell(
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) {
        setState(() => _selectedIndex = index);
      },
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          AdminOverviewScreen(devices: devices),
          DevicesScreen(devices: devices, onDeviceSelected: _openDevice),
          if (_selectedIndex == 2)
            const AdminAnomaliesScreen()
          else
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
