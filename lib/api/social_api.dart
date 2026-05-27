import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class SocialApi {
  // ── Checkin ──
  static Future<Map<String, dynamic>> checkin() async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/checkin'),
          headers: await ApiBase.headers(),
          body: '{}',
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getCheckinStatus() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/checkin/status'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getTodayCard() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/checkin/card/today'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  // ── Friends ──
  static Future<Map<String, dynamic>> addFriend(String phone) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/friends/add'),
          headers: await ApiBase.headers(),
          body: json.encode({'phone': phone}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> searchUser(String query) async {
    final res = await http
        .get(
          Uri.parse(
            '${ApiBase.baseUrl}/friends/search?q=${Uri.encodeComponent(query)}',
          ),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/friends/requests'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> respondFriend(
    int id,
    String status, {
    bool canViewMood = false,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/friends/respond'),
          headers: await ApiBase.headers(),
          body: json.encode({
            'id': id,
            'status': status,
            'can_view_mood': canViewMood,
          }),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getFriendList() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/friends/list'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> deleteFriend(int friendId) async {
    final res = await http
        .delete(
          Uri.parse('${ApiBase.baseUrl}/friends/$friendId'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<void> sendFriendNote(int friendId, String content) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/friends/$friendId/note'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getFriendMood(int friendId) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/friends/$friendId/mood'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getMoodComments(int moodId) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/friends/moods/$moodId/comments'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> postMoodComment(int moodId, String content) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/friends/moods/$moodId/comments'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }
}
