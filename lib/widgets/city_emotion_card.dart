import 'dart:io';
import 'dart:ui' as ui;
import '../utils/time_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../stores/map_state.dart';
import '../stores/theme_state.dart';
import '../utils/helpers.dart';

class CityEmotionCard extends StatefulWidget {
  final String cityCode;

  const CityEmotionCard({super.key, required this.cityCode});

  @override
  State<CityEmotionCard> createState() => _CityEmotionCardState();
}

class _CityEmotionCardState extends State<CityEmotionCard> {
  final _repaintKey = GlobalKey();
  final _commentCtrl = TextEditingController();
  bool _posting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final map = context.watch<MapState>();
    final theme = context.watch<ThemeState>();
    final city = MapState.allCityList.cast<CityData?>().firstWhere(
          (c) => c?.code == widget.cityCode,
          orElse: () => null,
        );
    if (city == null) return const SizedBox.shrink();

    final mood = map.cityMood(widget.cityCode);
    final count = map.cityCommentCount(widget.cityCode);
    final comments = map.comments;
    final canPost = map.canPost;

    return RepaintBoundary(
      key: _repaintKey,
      child: Container(
        decoration: BoxDecoration(
          color: theme.isDark ? const Color(0xFF0A1628) : theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.textSecondary.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // City emotion header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    city.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: _moodColor(mood).withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _moodLabel(mood),
                      style: TextStyle(
                        color: _moodColor(mood),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${city.province} · $count 人留下足迹',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12),
                  ),

                  // Featured comment
                  if (comments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardColor.withAlpha(theme.isDark ? 60 : 180),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.borderColor.withAlpha(60)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.format_quote, size: 20, color: _moodColor(mood)),
                          const SizedBox(height: 8),
                          Text(
                            '"${comments.first['content'] ?? ''}"',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontSize: 15,
                              height: 1.5,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Actions
                  Row(
                    children: [
                      if (canPost)
                        Expanded(
                          child: _actionButton(
                            label: '写下一笔足迹',
                            icon: Icons.edit_note_rounded,
                            color: _moodColor(mood),
                            onTap: () => _showCommentInput(context, map),
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _actionButton(
                          label: '分享这张卡片',
                          icon: Icons.share_rounded,
                          color: theme.accentColor,
                          onTap: () => _shareCard(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: theme.borderColor.withAlpha(60), height: 1),
            const SizedBox(height: 8),

            // Comment list
            if (map.commentLoading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '还没有足迹，做第一个说话的人吧',
                  style: TextStyle(color: theme.textSecondary, fontSize: 13),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: comments.length + (map.commentHasMore ? 1 : 0),
                  itemBuilder: (context, i) {
                    if (i >= comments.length) {
                      map.loadMoreComments();
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                      );
                    }
                    final c = comments[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _moodColor(mood).withAlpha(20),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.person_outline, size: 16, color: _moodColor(mood).withAlpha(150)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c['content'] ?? '',
                                  style: TextStyle(color: theme.textPrimary, fontSize: 14, height: 1.4),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _formatTime(c['created_at']?.toString()),
                                      style: TextStyle(color: theme.textTertiary, fontSize: 11),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => map.likeComment(readInt(c['id']) ?? 0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.favorite_border, size: 12, color: c['liked'] == true ? Colors.red : theme.textTertiary),
                                          const SizedBox(width: 2),
                                          Text('${readInt(c['likes']) ?? 0}', style: TextStyle(color: theme.textTertiary, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
          ],
        ),
      ),
    );
  }

  void _showCommentInput(BuildContext context, MapState map) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.watch<ThemeState>().isDark ? const Color(0xFF0A1628) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('写下足迹', style: TextStyle(color: context.watch<ThemeState>().textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              TextField(
                controller: _commentCtrl,
                autofocus: true,
                maxLength: 200,
                style: TextStyle(color: context.watch<ThemeState>().textPrimary),
                decoration: InputDecoration(
                  hintText: '说点什么...',
                  hintStyle: TextStyle(color: context.watch<ThemeState>().textTertiary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: context.watch<ThemeState>().cardColor,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _posting ? null : () async {
                  setState(() => _posting = true);
                  final result = await map.postComment(_commentCtrl.text.trim());
                  setState(() => _posting = false);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
                  }
                },
                child: Text(_posting ? '发送中...' : '提交足迹'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareCard() async {
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final pngBytes = byteData.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/city_card_${widget.cityCode}.png');
      await file.writeAsBytes(pngBytes);

      await Gal.putImageBytes(pngBytes);
      // Share directly, no SnackBar (which would be hidden behind BottomSheet)
      Share.shareXFiles([XFile(file.path)]);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('分享失败，请稍后重试')),
        );
      }
    }
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Color _moodColor(String? mood) {
    return switch (mood) {
      'warm' => const Color(0xFFF5A623),
      'sad' => const Color(0xFF5B8FB9),
      'anxious' => const Color(0xFF9B72CF),
      'calm' => const Color(0xFF6ABF8A),
      'excited' => const Color(0xFFFF6B35),
      _ => const Color(0xFF5B8FB9),
    };
  }

  String _moodLabel(String? mood) {
    return switch (mood) {
      'warm' => '今晚偏温暖',
      'sad' => '今晚有点低落',
      'anxious' => '一丝焦虑',
      'calm' => '安静如常',
      'excited' => '今晚很兴奋',
      _ => '等待第一个说话的人',
    };
  }

  String _formatTime(String? iso) => TimeUtils.relative(iso);
}
