import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:sentinel/core/constants/api_constants.dart';
import 'package:sentinel/models/sensor_data.dart';

class SensorService {
  static final String _baseUrl = ApiConstants.baseUrl;

  Future<SensorData> fetchSensorData() async {
    final response = await http.get(Uri.parse('$_baseUrl/sensor'));

    if (response.statusCode != 200) {
      throw Exception('Sensör verisi alınamadı.');
    }

    final json = jsonDecode(response.body);

    return SensorData.fromJson(json);
  }
}
