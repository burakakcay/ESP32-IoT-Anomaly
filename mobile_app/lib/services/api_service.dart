import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sentinel/models/sensor_data.dart';
import 'package:sentinel/services/auth_service.dart';

import '../models/anomaly.dart';
import 'package:sentinel/core/constants/api_constants.dart';

class ApiService {
  static Future<({List<SensorData> readings, AnomalyResponse anomalies})>
  getDashboardData() async {
    final response = await _get(
      '/api/dashboard',
      timeout: const Duration(seconds: 60),
    );

    if (response.statusCode != 200) {
      throw Exception('Dashboard verileri alınamadı: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final readingsJson = jsonData['readings'] as List<dynamic>;

    final readings = readingsJson
        .map(
          (item) => SensorData.fromFirestoreJson(item as Map<String, dynamic>),
        )
        .toList()
        .reversed
        .toList();

    final anomalies = AnomalyResponse.fromJson(
      jsonData['anomalies'] as Map<String, dynamic>,
    );

    return (readings: readings, anomalies: anomalies);
  }

  static Future<http.Response> _get(
    String path, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    return (() async {
      final token = await AuthService.getIdToken();
      return http.get(
        Uri.parse('${ApiConstants.nodeBaseUrl}$path'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
    })().timeout(timeout);
  }

  static Future<SensorData> getLatestSensorData() async {
    final response = await _get('/api/readings/latest');

    if (response.statusCode != 200) {
      throw Exception('Son sensör verisi alınamadı: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

    return SensorData.fromFirestoreJson(jsonData);
  }

  static Future<AnomalyResponse> getAnomalies() async {
    final response = await _get('/api/anomalies');

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return AnomalyResponse.fromJson(jsonData);
    } else {
      throw Exception('Anomali verileri alınamadı: ${response.statusCode}');
    }
  }

  static Future<AiAnomalyResponse> getAiAnomalies() async {
    final response = await _get(
      '/api/anomalies/ai',
      timeout: const Duration(seconds: 60),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      return AiAnomalyResponse.fromJson(jsonData);
    }

    throw Exception('Ai anomali verileri alınamadı: ${response.statusCode}');
  }
}
