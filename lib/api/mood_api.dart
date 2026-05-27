import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class MoodApi {
  static Future<Map<String, dynamic>> saveMood(
    String date,
    int score,
    String text,
    List<String> tags,
    List<String> activities,
  ) async {
    final body = <String, dynamic>{
      'date': date,
      'emotion_type': score,
      'emotion_tags': tags.join(','),
      'notes': text,
    };
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/mood'),
          headers: await ApiBase.headers(),
          body: json.encode(body),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  /// 获取某天所有心情记录
  static Future<List<Map<String, dynamic>>> getMoodsByDate(String date) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/mood?date=$date'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    final data = await ApiBase.handle(res);
    return List<Map<String, dynamic>>.from(data['moods'] ?? []);
  }

  /// 获取所有心情记录
  static Future<Map<String, dynamic>> getAllMoods() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/mood/all'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  /// 删除单条心情记录
  static Future<void> deleteMood(int id) async {
    final res = await http
        .delete(
          Uri.parse('${ApiBase.baseUrl}/mood/$id'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }
}
