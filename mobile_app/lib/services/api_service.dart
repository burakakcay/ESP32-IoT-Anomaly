import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sentinel/models/sensor_data.dart';

import '../models/anomaly.dart';
import 'package:sentinel/core/constants/api_constants.dart';

class ApiService {
  static Future<SensorData> getLatestSensorData() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.nodeBaseUrl}/api/readings'),
    );

    if (response.statusCode != 200) {
      throw Exception('Sensör verileri alınamadı: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body);

    if (jsonData is! List || jsonData.isEmpty) {
      throw Exception('Sensör verisi bulunamadı.');
    }

    return SensorData.fromFirestoreJson(jsonData.first as Map<String, dynamic>);
  }

  static Future<AnomalyResponse> getAnomalies() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.nodeBaseUrl}/api/anomalies'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      return AnomalyResponse.fromJson(jsonData);
    } else {
      throw Exception('Anomali verileri alınamadı: ${response.statusCode}');
    }
  }
}
