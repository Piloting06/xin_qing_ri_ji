import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_base.dart';

class ContentApi {
  // ── Treehole ──
  static Future<Map<String, dynamic>> getTreeholeMessages({
    int page = 1,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/treehole?page=$page'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<void> postTreehole(String content) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/treehole'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content}),
        )
        .timeout(ApiBase.timeout);
    await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> interactTreehole(
    int messageId,
    String type,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/treehole/$messageId/interact'),
          headers: await ApiBase.headers(),
          body: json.encode({'interaction_type': type}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getTreeholeComments(
    int messageId,
  ) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/treehole/$messageId/comments'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> postTreeholeComment(
    int messageId,
    String content,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/treehole/$messageId/comments'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> deleteTreehole(int messageId) async {
    final res = await http
        .delete(
          Uri.parse('${ApiBase.baseUrl}/treehole/$messageId'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  // ── Capsule ──
  static Future<Map<String, dynamic>> createCapsule(
    String content,
    String openDate,
  ) async {
    final res = await http
        .post(
          Uri.parse('${ApiBase.baseUrl}/capsule'),
          headers: await ApiBase.headers(),
          body: json.encode({'content': content, 'open_date': openDate}),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> getCapsuleList() async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/capsule/list'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> openCapsule(int id) async {
    final res = await http
        .get(
          Uri.parse('${ApiBase.baseUrl}/capsule/$id'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }

  static Future<Map<String, dynamic>> deleteCapsule(int capsuleId) async {
    final res = await http
        .delete(
          Uri.parse('${ApiBase.baseUrl}/capsule/$capsuleId'),
          headers: await ApiBase.headers(),
        )
        .timeout(ApiBase.timeout);
    return await ApiBase.handle(res);
  }
}
