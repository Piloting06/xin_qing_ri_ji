import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../constants/mood.dart';

class MoodCardShare {
  static Future<String?> generateAndSave(
    BuildContext context, {
    required String date,
    required String weather,
    required String temp,
    required int moodScore,
    required String note,
    required int weatherCode,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, 400, 560));
    final emoji = moodEmojis[moodScore] ?? '';

    Color bg, accent, text, sub;
    if (weatherCode <= 1) {
      bg = const Color(0xFFFFF8E1);
      accent = const Color(0xFF8B7355);
    } else if (weatherCode >= 51 && weatherCode <= 55 || weatherCode == 80) {
      bg = const Color(0xFFE8ECF4);
      accent = const Color(0xFF5B7FA5);
    } else if (weatherCode >= 61 && weatherCode <= 65) {
      bg = const Color(0xFFF0F4FF);
      accent = const Color(0xFF7B8D9E);
    } else if (weatherCode == 95) {
      bg = const Color(0xFF2A2830);
      accent = const Color(0xFFFFD54F);
    } else if (weatherCode == 45) {
      bg = const Color(0xFFECF0F1);
      accent = const Color(0xFF8C9EA8);
    } else {
      bg = const Color(0xFFF5F0E8);
      accent = const Color(0xFF8B7355);
    }
    final isDark = weatherCode == 95;
    text = isDark ? Colors.white : const Color(0xFF3D3228);
    sub = isDark ? const Color(0xFFB0A898) : const Color(0xFF8C7E6F);

    // Background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(0, 0, 400, 560),
        const Radius.circular(24),
      ),
      Paint()..color = bg,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(6, 6, 388, 548),
        const Radius.circular(20),
      ),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = accent.withAlpha(60),
    );

    // Date
    _drawText(canvas, date, const Offset(200, 45), sub, 13, TextAlign.center);
    // Weather + temp
    final wt = temp.isNotEmpty ? '$weather  $temp°' : weather;
    _drawText(
      canvas,
      wt,
      const Offset(200, 72),
      accent,
      15,
      TextAlign.center,
      bold: true,
    );

    // Emoji
    _drawText(
      canvas,
      emoji,
      const Offset(200, 130),
      text,
      56,
      TextAlign.center,
    );

    _drawMultiline(canvas, note, Rect.fromLTWH(40, 175, 320, 160), text, 17);

    canvas.drawLine(
      const Offset(180, 375),
      const Offset(220, 375),
      Paint()
        ..color = accent.withAlpha(60)
        ..strokeWidth = 1,
    );

    // Footer
    _drawText(
      canvas,
      '— 心晴日记 —',
      Offset(200, 510),
      sub,
      11,
      TextAlign.center,
      bold: false,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(400, 560);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final dir = await getApplicationDocumentsDirectory();
    final cardDir = Directory(p.join(dir.path, 'cards'));
    if (!cardDir.existsSync()) cardDir.createSync(recursive: true);
    final path = p.join(cardDir.path, 'mood_${date.replaceAll('-', '')}.png');
    await File(path).writeAsBytes(byteData.buffer.asUint8List());
    return path;
  }

  static void _drawText(
    Canvas canvas,
    String text,
    Offset center,
    Color color,
    double size,
    TextAlign align, {
    bool bold = false,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: align,
              fontSize: size,
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          )
          ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Arial'))
          ..addText(text);
    final paragraph = builder.build()
      ..layout(const ui.ParagraphConstraints(width: 380));
    final dx = align == TextAlign.center
        ? center.dx - paragraph.width / 2
        : center.dx;
    canvas.drawParagraph(
      paragraph,
      Offset(dx, center.dy - paragraph.height / 2),
    );
  }

  static void _drawMultiline(
    Canvas canvas,
    String text,
    Rect rect,
    Color color,
    double size, {
    bool italic = false,
  }) {
    final builder =
        ui.ParagraphBuilder(
            ui.ParagraphStyle(
              textAlign: TextAlign.center,
              fontSize: size,
              fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            ),
          )
          ..pushStyle(ui.TextStyle(color: color, fontFamily: 'Arial'))
          ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: rect.width));
    canvas.drawParagraph(paragraph, Offset(rect.left, rect.top));
  }
}
