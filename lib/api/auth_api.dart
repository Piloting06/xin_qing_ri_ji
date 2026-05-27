import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/keys.dart';
import 'api_base.dart';

class AuthApi {
  static Future<Map<String, dynamic>> register(
    String phone,
    String password, {
    String? questionType,
    String? question,
    String? answer,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/register'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({
            'phone': phone,
            'password': password,
            'security_question_type': questionType,
            'security_question': question,
            'security_answer': answer,
          }),
        )
        .timeout(ApiBase.timeout);
    final data = await ApiBase.handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      await prefs.setString(StorageKeys.phone, phone);
      if (data['display_name'] != null) {
        await prefs.setString(StorageKeys.displayName, data['display_name']);
      }
      ApiBase.resetUnauthorizedFlag();
      ApiBase.onAuthenticated?.call();
    }
    return data;
  }

  static Future<Map<String, dynamic>> login(
    String phone,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/login'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({'phone': phone, 'password': password}),
        )
        .timeout(ApiBase.timeout);
    final data = await ApiBase.handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      await prefs.setString(StorageKeys.phone, phone);
      if (data['display_name'] != null) {
        await prefs.setString(StorageKeys.displayName, data['display_name']);
      }
      ApiBase.resetUnauthorizedFlag();
      ApiBase.onAuthenticated?.call();
    }
    return data;
  }

  static Future<void> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/change-password'),
          headers: await ApiBase.headers(),
          body: json.encode({
            'old_password': oldPassword,
            'new_password': newPassword,
          }),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<void> deleteAccount() async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/delete-account'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<void> sendSmsCode(String phone) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/send-sms-code'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({'phone': phone}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<void> resetPassword(
    String phone,
    String code,
    String newPassword,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/reset-password'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({
            'phone': phone,
            'code': code,
            'new_password': newPassword,
          }),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/change-username'),
          headers: await ApiBase.headers(),
          body: json.encode({'username': name}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
    await prefs.setString(StorageKeys.displayName, name);
  }

  static Future<void> sendEmailCode(String email) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/send-email-code'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({'email': email}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> emailRegister(
    String email,
    String password,
    String code,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/email-register'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({
            'email': email,
            'password': password,
            'code': code,
          }),
        )
        .timeout(ApiBase.timeout);
    final data = await ApiBase.handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      if (data['display_name'] != null) {
        await prefs.setString(StorageKeys.displayName, data['display_name']);
      }
      ApiBase.resetUnauthorizedFlag();
      ApiBase.onAuthenticated?.call();
    }
    return data;
  }

  static Future<Map<String, dynamic>> emailLogin(
    String email,
    String password,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/email-login'),
          headers: await ApiBase.headers(auth: false),
          body: json.encode({'email': email, 'password': password}),
        )
        .timeout(ApiBase.timeout);
    final data = await ApiBase.handle(res);
    if (data['token'] != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(StorageKeys.token, data['token']);
      ApiBase.resetUnauthorizedFlag();
      ApiBase.onAuthenticated?.call();
    }
    return data;
  }

  static Future<Map<String, dynamic>> bindEmail(
    String email,
    String code,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/auth/bind-email'),
          headers: await ApiBase.headers(),
          body: json.encode({'email': email, 'code': code}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/auth/profile'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.token);
    await prefs.remove(StorageKeys.phone);
    await prefs.remove(StorageKeys.username);
    await prefs.remove(StorageKeys.displayName);
  }
}
