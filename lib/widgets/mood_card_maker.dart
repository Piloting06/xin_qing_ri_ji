import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

class MoodCardMaker extends StatefulWidget {
  final String date;
  final String moodLabel;
  final int moodScore;
  final String text;
  final List<String> tags;
  final ThemeState theme;

  const MoodCardMaker({
    super.key,
    required this.date,
    required this.moodLabel,
    required this.moodScore,
    required this.text,
    required this.tags,
    required this.theme,
  });

  static void show(BuildContext context, {
    required String date, required String moodLabel, required int moodScore,
    required String text, required List<String> tags,
  }) {
    final theme = ThemeState();
    // read from context instead
    final t = context.read<ThemeState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodCardMaker(
        date: date, moodLabel: moodLabel, moodScore: moodScore,
        text: text, tags: tags, theme: t,
      ),
    );
  }

  @override
  State<MoodCardMaker> createState() => _MoodCardMakerState();
}

class _MoodCardMakerState extends State<MoodCardMaker> {
  final _repaintKey = GlobalKey();
  bool _saving = false;

  Color get _bgColor {
    switch (widget.theme.themeMode) {
      case 'dark': return const Color(0xFF0E1222);
      case 'mint': return const Color(0xFFDDEBE3);
      case 'blush': return const Color(0xFFEFE1DD);
      default: return const Color(0xFFFFF5E8);
    }
  }

  Color get _accentColor {
    switch (widget.theme.themeMode) {
      case 'dark': return const Color(0xFFB9B8FF);
      case 'mint': return const Color(0xFF4D8C7A);
      case 'blush': return const Color(0xFFB87A75);
      default: return const Color(0xFFB8782C);
    }
  }

  Color get _textColor {
    switch (widget.theme.themeMode) {
      case 'dark': return const Color(0xFFF4F0E7);
      default: return const Color(0xFF2F2118);
    }
  }

  String get _moodEmoji {
    if (widget.moodScore >= 80) return '😊';
    if (widget.moodScore >= 60) return '😌';
    if (widget.moodScore >= 40) return '😐';
    if (widget.moodScore >= 20) return '😢';
    return '😞';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'mood_card_${DateTime.now().millisecondsSinceEpoch}.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Gal.putImage(file.path);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('卡片已保存到相册'), duration: Duration(seconds: 2)),
        );
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('保存失败')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'mood_card_share.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path)],
        text: '心晴日记 · ${widget.date}\n${widget.moodLabel} — ${widget.text.isNotEmpty ? widget.text : "记录天气，也记录你"}',
      ));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _moodEmoji;
    return Container(
      decoration: BoxDecoration(
        color: widget.theme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: widget.theme.borderColor, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 12),
              Text('制成一张卡片', style: TextStyle(color: widget.theme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              // Card preview
              RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: _bgColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top: date + watermark
                          Row(
                            children: [
                              Text(widget.date, style: TextStyle(color: _textColor.withAlpha(160), fontSize: 12)),
                              const Spacer(),
                              Icon(Icons.wb_sunny_outlined, size: 14, color: _accentColor.withAlpha(120)),
                              const SizedBox(width: 4),
                              Text('XINQING RIJI', style: TextStyle(color: _accentColor.withAlpha(100), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                            ],
                          ),
                          const Spacer(),
                          // Center: emoji + mood
                          Row(
                            children: [
                              Text(emoji, style: const TextStyle(fontSize: 48)),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(widget.moodLabel, style: TextStyle(color: _textColor, fontSize: 22, fontWeight: FontWeight.w800)),
                                    if (widget.tags.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(widget.tags.take(3).join(' · '), style: TextStyle(color: _accentColor, fontSize: 12)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          // Text content
                          if (widget.text.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(widget.text, style: TextStyle(color: _textColor.withAlpha(200), fontSize: 13, height: 1.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                          const Spacer(),
                          // Bottom watermark
                          Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined, size: 10, color: _accentColor.withAlpha(80)),
                              const SizedBox(width: 4),
                              Text('心晴日记', style: TextStyle(color: _accentColor.withAlpha(100), fontSize: 10)),
                              const Spacer(),
                              Text('记录天气，也记录你', style: TextStyle(color: _textColor.withAlpha(80), fontSize: 9)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.download, size: 18),
                        label: const Text('保存'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accentColor,
                          side: BorderSide(color: _accentColor.withAlpha(100)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 46,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _share,
                        icon: const Icon(Icons.share, size: 18),
                        label: const Text('分享'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _accentColor,
                          foregroundColor: _bgColor.computeLuminance() > 0.5 ? const Color(0xFF222222) : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
