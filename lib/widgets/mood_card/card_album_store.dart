import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 卡片册：用户制作过的所有卡片存档（本地资产，竞品抄不走的护城河）
class CardAlbumEntry {
  final String file; // 文件名（位于 documents/cards/ 下）
  final String createdAt; // 制作时间 ISO
  final String date; // 日记日期
  final int moodScore;
  final String templateId;
  final bool square; // 是否方图

  const CardAlbumEntry({
    required this.file,
    required this.createdAt,
    required this.date,
    required this.moodScore,
    required this.templateId,
    required this.square,
  });

  Map<String, dynamic> toJson() => {
        'file': file,
        'createdAt': createdAt,
        'date': date,
        'moodScore': moodScore,
        'templateId': templateId,
        'square': square,
      };

  static CardAlbumEntry fromJson(Map<String, dynamic> j) => CardAlbumEntry(
        file: j['file']?.toString() ?? '',
        createdAt: j['createdAt']?.toString() ?? '',
        date: j['date']?.toString() ?? '',
        moodScore: (j['moodScore'] as num?)?.toInt() ?? 0,
        templateId: j['templateId']?.toString() ?? '',
        square: j['square'] == true,
      );
}

class CardAlbumStore {
  static const _metaFile = 'cards.json';

  static Future<Directory> dir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'cards'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  static Future<File> _metaFileRef() async {
    final d = await dir();
    return File(p.join(d.path, _metaFile));
  }

  static Future<List<CardAlbumEntry>> load() async {
    try {
      final f = await _metaFileRef();
      if (!f.existsSync()) return [];
      final list = (json.decode(await f.readAsString()) as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CardAlbumEntry.fromJson)
          .toList();
      // 清理已不存在的文件对应的条目
      final d = await dir();
      final alive = list
          .where((e) => File(p.join(d.path, e.file)).existsSync())
          .toList();
      return alive;
    } catch (_) {
      return [];
    }
  }

  /// 保存一张卡片进册子；返回失败与否（失败不影响主保存流程）
  static Future<void> archive({
    required String sourceFilePath,
    required String date,
    required int moodScore,
    required String templateId,
    required bool square,
  }) async {
    try {
      final d = await dir();
      final name =
          'card_${DateTime.now().millisecondsSinceEpoch}.png';
      await File(sourceFilePath).copy(p.join(d.path, name));
      final entries = await load();
      entries.insert(
        0,
        CardAlbumEntry(
          file: name,
          createdAt: DateTime.now().toIso8601String(),
          date: date,
          moodScore: moodScore,
          templateId: templateId,
          square: square,
        ),
      );
      final f = await _metaFileRef();
      await f.writeAsString(json.encode(entries.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }

  static Future<void> delete(CardAlbumEntry entry) async {
    try {
      final d = await dir();
      final f = File(p.join(d.path, entry.file));
      if (f.existsSync()) f.deleteSync();
      final entries = await load();
      entries.removeWhere((e) => e.file == entry.file);
      final meta = await _metaFileRef();
      await meta.writeAsString(json.encode(entries.map((e) => e.toJson()).toList()));
    } catch (_) {}
  }
}
