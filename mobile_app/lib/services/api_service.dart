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

  static Future<List<SensorData>> getReadingsInRange({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!from.isBefore(to)) {
      throw ArgumentError('Başlangıç zamanı bitişten önce olmalıdır.');
    }

    final path = Uri(
      path: '/api/readings/history',
      queryParameters: {
        'fromMs': from.millisecondsSinceEpoch.toString(),
        'toMs': to.millisecondsSinceEpoch.toString(),
      },
    ).toString();

    final response = await _get(path);

    if (response.statusCode != 200) {
      String message = 'Ölçüm geçmişi alınamadı: ${response.statusCode}';

      try {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['error'] is String) {
          message = body['error'] as String;
        }
      } on FormatException {
        message =
            'Sunucu geçerli bir JSON yanıtı döndürmedi: '
            '${response.statusCode}';
      }

      throw Exception(message);
    }
    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
    final readingsJson = jsonData['readings'] as List<dynamic>;

    return readingsJson
        .map(
          (item) => SensorData.fromFirestoreJson(item as Map<String, dynamic>),
        )
        .toList();
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

  static Future<AnomalyHistoryResponse> getAnomalyHistory({
    DateTime? from,
    DateTime? to,
    int limit = 20,
    String? cursor,
    String? sensor,
  }) async {
    String formatDate(DateTime date) {
      final year = date.year.toString().padLeft(4, '0');
      final month = date.month.toString().padLeft(2, '0');
      final day = date.day.toString().padLeft(2, '0');

      return '$year-$month-$day';
    }

    final path = Uri(
      path: '/api/anomalies/history',
      queryParameters: {
        'limit': limit.toString(),
        if (from != null) 'from': formatDate(from),
        if (to != null) 'to': formatDate(to),
        'cursor': ?cursor,
        'sensor': ?sensor,
      },
    ).toString();

    final response = await _get(path, timeout: const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('Anomali geçmişi alınamadı: ${response.statusCode}');
    }

    final jsonData = jsonDecode(response.body) as Map<String, dynamic>;

    return AnomalyHistoryResponse.fromJson(jsonData);
  }
}
