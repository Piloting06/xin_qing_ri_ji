import 'xq_toast.dart';
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
import '../constants/mood.dart';

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
  late String _cardTheme;

  static const _cardThemes = ['warm', 'dark', 'mint', 'blush'];

  @override
  void initState() {
    super.initState();
    _cardTheme = widget.theme.themeMode;
  }

  Color get _bgColor {
    switch (_cardTheme) {
      case 'dark': return const Color(0xFF0E1222);
      case 'mint': return const Color(0xFFDDEBE3);
      case 'blush': return const Color(0xFFF2DED8);
      default: return const Color(0xFFFAF4EC);
    }
  }

  Color get _accentColor {
    switch (_cardTheme) {
      case 'dark': return const Color(0xFFB9B8FF);
      case 'mint': return const Color(0xFF4D8C7A);
      case 'blush': return const Color(0xFFC4707A);
      default: return const Color(0xFFB8782C);
    }
  }

  Color get _textColor {
    return _cardTheme == 'dark' ? const Color(0xFFF4F0E7) : const Color(0xFF2F2118);
  }

  String get _moodEmoji => moodEmojis[widget.moodScore] ?? '😌';

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
      if (mounted) XqToast.success(context, '卡片已保存到相册');
    } catch (_) {
      if (mounted) XqToast.error(context, '保存失败');
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

  Widget _themeDot(String mode) {
    final active = _cardTheme == mode;
    final dotColors = switch (mode) {
      'dark' => [const Color(0xFF32376E), const Color(0xFF1B1F3B), const Color(0xFF0E1222)],
      'mint' => [const Color(0xFF4D8C7A), const Color(0xFFA8D5C0), const Color(0xFFDDEBE3)],
      'blush' => [const Color(0xFFC4707A), const Color(0xFFE7C0B8), const Color(0xFFF2DED8)],
      _ => [const Color(0xFFB8782C), const Color(0xFFE2C99E), const Color(0xFFFAF4EC)],
    };
    return GestureDetector(
      onTap: () => setState(() => _cardTheme = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: active ? 44 : 34,
        height: active ? 44 : 34,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: dotColors),
          boxShadow: active ? [BoxShadow(color: dotColors[0].withAlpha(80), blurRadius: 10)] : null,
          border: Border.all(color: widget.theme.cardColor, width: active ? 3 : 2),
        ),
        child: active ? const Center(child: Icon(Icons.check, size: 18, color: Colors.white)) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emoji = _moodEmoji;
    final sheetTheme = widget.theme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.78,
      decoration: BoxDecoration(
        color: sheetTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: sheetTheme.borderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 10),
            Text('制成一张卡片', style: TextStyle(color: sheetTheme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('点击色块切换风格', style: TextStyle(color: sheetTheme.textTertiary, fontSize: 12)),
            const SizedBox(height: 12),

            // Theme picker
            Row(mainAxisAlignment: MainAxisAlignment.center, children: _cardThemes.map(_themeDot).toList()),

            const SizedBox(height: 16),

            // Card preview — card stays compact, everything fits inside
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RepaintBoundary(
                  key: _repaintKey,
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: _bgColor,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withAlpha(50), blurRadius: 24, offset: const Offset(0, 10))],
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 16, 22, 12),
                        child: Column(
                          children: [
                            // Top bar
                            Row(
                              children: [
                                Text(widget.date, style: TextStyle(color: _textColor.withAlpha(140), fontSize: 11)),
                                const Spacer(),
                                Icon(Icons.wb_sunny_outlined, size: 10, color: _accentColor.withAlpha(70)),
                                const SizedBox(width: 3),
                                Text('XINQING RIJI', style: TextStyle(color: _accentColor.withAlpha(80), fontSize: 8, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Emoji + label (compact)
                            Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 24)),
                                const SizedBox(width: 8),
                                Text(widget.moodLabel, style: TextStyle(color: _textColor, fontSize: 16, fontWeight: FontWeight.w700)),
                                if (widget.tags.isNotEmpty) ...[
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      widget.tags.take(3).join(' · '),
                                      style: TextStyle(color: _accentColor, fontSize: 10),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Text content — THIS is the main element
                            if (widget.text.isNotEmpty)
                              Expanded(
                                child: Center(
                                  child: Text(
                                    widget.text,
                                    style: TextStyle(color: _textColor, fontSize: 15, height: 1.6),
                                    textAlign: TextAlign.center,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: Center(
                                  child: Text('写点什么吧', style: TextStyle(color: _textColor.withAlpha(80), fontSize: 13)),
                                ),
                              ),

                            // Bottom watermark
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('心晴日记', style: TextStyle(color: _accentColor.withAlpha(80), fontSize: 9)),
                                const SizedBox(width: 6),
                                Text('记录天气，也记录你', style: TextStyle(color: _textColor.withAlpha(50), fontSize: 8)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  Container(height: 1, color: sheetTheme.borderColor.withAlpha(80)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('保存到相册'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: BorderSide(color: _accentColor.withAlpha(120)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _share,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('分享给朋友'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: _cardTheme == 'dark' ? const Color(0xFF1B1F3B) : Colors.white,
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
          ],
        ),
      ),
    );
  }
}
