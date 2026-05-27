import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class CityApi {
  static Future<Map<String, dynamic>> getCityStats() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/city/stats'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getCityComments(
    String cityCode, {
    int page = 1,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/city/comments?city=$cityCode&page=$page'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> postCityComment(
    String cityCode,
    String content,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/city/comments'),
          headers: await ApiBase.headers(),
          body: json.encode({'city_code': cityCode, 'content': content}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> likeCityComment(int commentId) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/city/comments/$commentId/like'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> deleteCityComment(int commentId) async {
    final res = await http
        .delete(
          Uri.parse('${ApiBase.baseUrl}/city/comments/$commentId'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getCityReplies(int commentId) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/city/comments/$commentId/replies'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> postCityReply(
    int commentId,
    String content,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/city/comments/$commentId/replies'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }
}
