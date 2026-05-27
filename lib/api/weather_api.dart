import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class WeatherApi {
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/weather?lat=$lat&lon=$lon'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getLocation() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/weather/location'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> sendWeatherFeedback({
    required String type,
    required String weather,
    required String temp,
    required String city,
    String note = '',
  }) async {
    try {
      await http
          .post(
            Uri.parse('${ApiBase.baseUrl}/weather/feedback'),
            headers: await ApiBase.headers(),
            body: json.encode({
              'type': type,
              'weather': weather,
              'temp': temp,
              'city': city,
              'note': note,
            }),
          )
          .timeout(ApiBase.timeout);
    } catch (_) {}
  }
}
