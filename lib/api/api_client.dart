// Re-export all modules for backward compatibility.
export 'api_base.dart' show ApiException;
export 'auth_api.dart';
export 'weather_api.dart';
export 'mood_api.dart';
export 'social_api.dart';
export 'content_api.dart';
export 'city_api.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_api.dart';
import 'weather_api.dart';
import 'mood_api.dart';
import 'social_api.dart';
import 'content_api.dart';
import 'city_api.dart';
import 'api_base.dart';

/// Facade that preserves the original `Api` static-method surface.
/// All calls delegate to the corresponding module class.
class Api {
  /// Forward the callbacks so existing wiring keeps working.
  static String get baseUrl => ApiBase.baseUrl;
  static Duration get timeout => ApiBase.timeout;
  static void Function()? get onUnauthorized => ApiBase.onUnauthorized;
  static set onUnauthorized(void Function()? fn) => ApiBase.onUnauthorized = fn;
  static void Function()? get onAuthenticated => ApiBase.onAuthenticated;
  static set onAuthenticated(void Function()? fn) =>
      ApiBase.onAuthenticated = fn;

  // ── Auth ──
  static Future<Map<String, dynamic>> register(
    String phone,
    String password, {
    String? questionType,
    String? question,
    String? answer,
  }) =>
      AuthApi.register(
        phone,
        password,
        questionType: questionType,
        question: question,
        answer: answer,
      );

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) =>
      AuthApi.login(phone, password);

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) =>
      AuthApi.changePassword(oldPassword, newPassword);

  static Future<void> deleteAccount() => AuthApi.deleteAccount();

  static Future<void> sendSmsCode(String phone) =>
      AuthApi.sendSmsCode(phone);

  static Future<void> resetPassword(
    String phone,
    String code,
    String newPassword,
  ) =>
      AuthApi.resetPassword(phone, code, newPassword);

  static Future<void> updateDisplayName(String name) =>
      AuthApi.updateDisplayName(name);

  static Future<void> sendEmailCode(String email) =>
      AuthApi.sendEmailCode(email);

  static Future<Map<String, dynamic>> emailRegister(
    String email,
    String password,
    String code,
  ) =>
      AuthApi.emailRegister(email, password, code);

  static Future<Map<String, dynamic>> emailLogin(
    String email,
    String password,
  ) =>
      AuthApi.emailLogin(email, password);

  static Future<Map<String, dynamic>> bindEmail(
    String email,
    String code,
  ) =>
      AuthApi.bindEmail(email, code);

  static Future<Map<String, dynamic>> getProfile() => AuthApi.getProfile();

  static Future<void> logout() => AuthApi.logout();

  // ── Weather ──
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) =>
      WeatherApi.getWeather(lat, lon);

  static Future<Map<String, dynamic>> getLocation() => WeatherApi.getLocation();

  static Future<void> sendWeatherFeedback({
    required String type,
    required String weather,
    required String temp,
    required String city,
    String note = '',
  }) =>
      WeatherApi.sendWeatherFeedback(
        type: type,
        weather: weather,
        temp: temp,
        city: city,
        note: note,
      );

  // ── Mood ──
  static Future<Map<String, dynamic>> saveMood(
    String date,
    int score,
    String text,
    List<String> tags,
    List<String> activities,
  ) =>
      MoodApi.saveMood(date, score, text, tags, activities);

  static Future<List<Map<String, dynamic>>> getMoodsByDate(String date) =>
      MoodApi.getMoodsByDate(date);

  static Future<Map<String, dynamic>> getAllMoods() => MoodApi.getAllMoods();

  static Future<void> deleteMood(int id) => MoodApi.deleteMood(id);

  // ── Social ──
  static Future<Map<String, dynamic>> checkin() => SocialApi.checkin();

  static Future<Map<String, dynamic>> getCheckinStatus() =>
      SocialApi.getCheckinStatus();

  static Future<Map<String, dynamic>> getTodayCard() =>
      SocialApi.getTodayCard();

  static Future<Map<String, dynamic>> addFriend(String phone) =>
      SocialApi.addFriend(phone);

  static Future<Map<String, dynamic>> searchUser(String query) =>
      SocialApi.searchUser(query);

  static Future<Map<String, dynamic>> getFriendRequests() =>
      SocialApi.getFriendRequests();

  static Future<void> respondFriend(
    int id,
    String status, {
    bool canViewMood = false,
  }) =>
      SocialApi.respondFriend(id, status, canViewMood: canViewMood);

  static Future<Map<String, dynamic>> getFriendList() =>
      SocialApi.getFriendList();

  static Future<void> deleteFriend(int friendId) =>
      SocialApi.deleteFriend(friendId);

  static Future<void> sendFriendNote(int friendId, String content) =>
      SocialApi.sendFriendNote(friendId, content);

  static Future<Map<String, dynamic>> getFriendMood(int friendId) =>
      SocialApi.getFriendMood(friendId);

  static Future<Map<String, dynamic>> getMoodComments(int moodId) =>
      SocialApi.getMoodComments(moodId);

  static Future<void> postMoodComment(int moodId, String content) =>
      SocialApi.postMoodComment(moodId, content);

  // ── Content (Treehole + Capsule) ──
  static Future<Map<String, dynamic>> getTreeholeMessages({int page = 1}) =>
      ContentApi.getTreeholeMessages(page: page);

  static Future<void> postTreehole(String content) =>
      ContentApi.postTreehole(content);

  static Future<Map<String, dynamic>> interactTreehole(
    int messageId,
    String type,
  ) =>
      ContentApi.interactTreehole(messageId, type);

  static Future<Map<String, dynamic>> getTreeholeComments(int messageId) =>
      ContentApi.getTreeholeComments(messageId);

  static Future<Map<String, dynamic>> postTreeholeComment(
    int messageId,
    String content,
  ) =>
      ContentApi.postTreeholeComment(messageId, content);

  static Future<Map<String, dynamic>> deleteTreehole(int messageId) =>
      ContentApi.deleteTreehole(messageId);

  static Future<Map<String, dynamic>> createCapsule(
    String content,
    String openDate,
  ) =>
      ContentApi.createCapsule(content, openDate);

  static Future<Map<String, dynamic>> getCapsuleList() =>
      ContentApi.getCapsuleList();

  static Future<Map<String, dynamic>> openCapsule(int id) =>
      ContentApi.openCapsule(id);

  static Future<Map<String, dynamic>> deleteCapsule(int capsuleId) =>
      ContentApi.deleteCapsule(capsuleId);

  // ── City ──
  static Future<Map<String, dynamic>> getCityStats() => CityApi.getCityStats();

  static Future<Map<String, dynamic>> getCityComments(
    String cityCode, {
    int page = 1,
  }) =>
      CityApi.getCityComments(cityCode, page: page);

  static Future<Map<String, dynamic>> postCityComment(
    String cityCode,
    String content,
  ) =>
      CityApi.postCityComment(cityCode, content);

  static Future<Map<String, dynamic>> likeCityComment(int commentId) =>
      CityApi.likeCityComment(commentId);

  static Future<Map<String, dynamic>> deleteCityComment(int commentId) =>
      CityApi.deleteCityComment(commentId);

  static Future<Map<String, dynamic>> getCityReplies(int commentId) =>
      CityApi.getCityReplies(commentId);

  static Future<Map<String, dynamic>> postCityReply(
    int commentId,
    String content,
  ) =>
      CityApi.postCityReply(commentId, content);

  // ── Feedback ──
  static Future<void> sendFeedback(String content) async {
    final res = await http.post(
      Uri.parse('${ApiBase.baseUrl}/feedback'),
      headers: await ApiBase.headers(),
      body: json.encode({'content': content}),
    );
    await ApiBase.handle(res);
  }
}
