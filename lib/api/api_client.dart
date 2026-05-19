import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/keys.dart';

class Api {
  static const String baseUrl = 'http://114.55.138.55:8888/api';
  static const Duration timeout = Duration(seconds: 15);
  static void Function()? onUnauthorized;
  static bool _notifyingUnauthorized = false;

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final prefs = await SharedPreferences.getInstance();
      final t = prefs.getString(StorageKeys.token) ?? '';
      if (t.isNotEmpty) headers['Authorization'] = 'Bearer $t';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    if (res.statusCode == 401) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.token);
      await prefs.remove(StorageKeys.phone);
      await prefs.remove(StorageKeys.username);
      await prefs.remove(StorageKeys.displayName);
      if (!_notifyingUnauthorized) {
        _notifyingUnauthorized = true;
        onUnauthorized?.call();
      }
      throw ApiException('登录已过期，请重新登录', 401);
    }
    if (res.statusCode >= 400) {
      String msg = '请求失败';
      try {
        final body = json.decode(res.body);
        if (body is Map && body['message'] != null) msg = body['message'];
      } catch (_) {}
      throw ApiException(msg, res.statusCode);
    }
    if (res.body.isEmpty) return {};
    return Map<String, dynamic>.from(json.decode(res.body));
  }

  // ── Auth ──
  static Future<Map<String, dynamic>> register(
    String phone,
    String password, {
    String? questionType,
    String? question,
    String? answer,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/register'),
          headers: await _headers(auth: false),
          body: json.encode({
            'phone': phone,
            'password': password,
            'security_question_type': questionType,
            'security_question': question,
            'security_answer': answer,
          }),
        )
        .timeout(timeout);
    final data = await _handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      await prefs.setString(StorageKeys.phone, phone);
      if (data['display_name'] != null) {
        await prefs.setString(StorageKeys.displayName, data['display_name']);
      }
      _notifyingUnauthorized = false;
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/login'),
          headers: await _headers(auth: false),
          body: json.encode({'phone': phone, 'password': password}),
        )
        .timeout(timeout);
    final data = await _handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      await prefs.setString(StorageKeys.phone, phone);
      if (data['display_name'] != null) {
        await prefs.setString(StorageKeys.displayName, data['display_name']);
      }
      _notifyingUnauthorized = false;
    }
    return data;
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/change-password'),
          headers: await _headers(),
          body: json.encode({
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<void> deleteAccount() async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/delete-account'),
          headers: await _headers(),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final res = await http
        .post(
          Uri.parse('$baseUrl/auth/change-username'),
          headers: await _headers(),
          body: json.encode({'username': name}),
        )
        .timeout(timeout);
    await _handle(res);
    await prefs.setString(StorageKeys.displayName, name);
  }

  // ── Weather ──
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> reverseWeatherLocation(
    double lat,
    double lon,
  ) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/weather/reverse?lat=$lat&lon=$lon'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> searchWeather(String query) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/weather/search?q=${Uri.encodeComponent(query)}'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getLocation() async {
    final res = await http
        .get(Uri.parse('$baseUrl/weather/location'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Mood ──
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
          Uri.parse('$baseUrl/mood'),
          headers: await _headers(),
          body: json.encode(body),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>?> getMood(String date) async {
    final res = await http
        .get(Uri.parse('$baseUrl/mood?date=$date'), headers: await _headers())
        .timeout(timeout);
    try {
      return await _handle(res);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAllMoods() async {
    final res = await http
        .get(Uri.parse('$baseUrl/mood/all'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Diary ──
  static Future<Map<String, dynamic>> saveDiary(
    String date,
    String title,
    String content,
    int? moodId,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/diary'),
          headers: await _headers(),
          body: json.encode({
            'date': date,
            'title': title,
            'content': content,
            'mood_id': moodId,
          }),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>?> getDiary(String date) async {
    final res = await http
        .get(Uri.parse('$baseUrl/diary?date=$date'), headers: await _headers())
        .timeout(timeout);
    try {
      return await _handle(res);
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> searchDiary(String query) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/diary/search?q=$query'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Checkin ──
  static Future<Map<String, dynamic>> checkin() async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/checkin'),
          headers: await _headers(),
          body: '{}',
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getCheckinStatus() async {
    final res = await http
        .get(Uri.parse('$baseUrl/checkin/status'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getTodayCard() async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/checkin/card/today'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Friends ──
  static Future<Map<String, dynamic>> addFriend(String phone) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/friends/add'),
          headers: await _headers(),
          body: json.encode({'phone': phone}),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> searchUser(String query) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/friends/search?q=${Uri.encodeComponent(query)}'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getFriendRequests() async {
    final res = await http
        .get(Uri.parse('$baseUrl/friends/requests'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<void> respondFriend(
    int id,
    String status, {
    bool canViewMood = false,
  }) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/friends/respond'),
          headers: await _headers(),
          body: json.encode({
            'id': id,
            'status': status,
            'can_view_mood': canViewMood,
          }),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<Map<String, dynamic>> getFriendList() async {
    final res = await http
        .get(Uri.parse('$baseUrl/friends/list'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<void> deleteFriend(int friendId) async {
    final res = await http
        .delete(
          Uri.parse('$baseUrl/friends/$friendId'),
          headers: await _headers(),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<void> sendFriendNote(int friendId, String content) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/friends/$friendId/note'),
          headers: await _headers(),
          body: json.encode({'content': content}),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<Map<String, dynamic>> getFriendMood(int friendId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/friends/$friendId/mood'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getMoodComments(int moodId) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/friends/moods/$moodId/comments'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<void> postMoodComment(int moodId, String content) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/friends/moods/$moodId/comments'),
          headers: await _headers(),
          body: json.encode({'content': content}),
        )
        .timeout(timeout);
    await _handle(res);
  }

  // ── Treehole ──
  static Future<Map<String, dynamic>> getTreeholeMessages({
    int page = 1,
  }) async {
    final res = await http
        .get(
          Uri.parse('$baseUrl/treehole?page=$page'),
          headers: await _headers(),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<void> postTreehole(String content) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/treehole'),
          headers: await _headers(),
          body: json.encode({'content': content}),
        )
        .timeout(timeout);
    await _handle(res);
  }

  static Future<Map<String, dynamic>> interactTreehole(
    int messageId,
    String type,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/treehole/$messageId/interact'),
          headers: await _headers(),
          body: json.encode({'interaction_type': type}),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Treehole comments ──
  static Future<Map<String, dynamic>> getTreeholeComments(int messageId) async {
    final res = await http
        .get(Uri.parse('$baseUrl/treehole/$messageId/comments'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> postTreeholeComment(
    int messageId,
    String content,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/treehole/$messageId/comments'),
          headers: await _headers(),
          body: json.encode({'content': content}),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  // ── Capsule ──
  static Future<Map<String, dynamic>> createCapsule(
    String content,
    String openDate,
  ) async {
    final res = await http
        .post(
          Uri.parse('$baseUrl/capsule'),
          headers: await _headers(),
          body: json.encode({'content': content, 'open_date': openDate}),
        )
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> getCapsuleList() async {
    final res = await http
        .get(Uri.parse('$baseUrl/capsule/list'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }

  static Future<Map<String, dynamic>> openCapsule(int id) async {
    final res = await http
        .get(Uri.parse('$baseUrl/capsule/$id'), headers: await _headers())
        .timeout(timeout);
    return await _handle(res);
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);
  @override
  String toString() => message;
}
