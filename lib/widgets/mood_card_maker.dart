import 'xq_toast.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';

class MoodCardMaker extends StatefulWidget {
  final String date;
  final String moodLabel;
  final int moodScore;
  final String text;
  final List<String> tags;
  final ThemeState theme;
  final String? createdAt;
  final String? weatherText;
  final String? cityName;
  final String? temperature;

  const MoodCardMaker({
    super.key,
    required this.date,
    required this.moodLabel,
    required this.moodScore,
    required this.text,
    required this.tags,
    required this.theme,
    this.createdAt,
    this.weatherText,
    this.cityName,
    this.temperature,
  });

  static Future<T?> show<T>(
    BuildContext context, {
    required String date,
    required String moodLabel,
    required int moodScore,
    required String text,
    required List<String> tags,
    String? createdAt,
    String? weatherText,
    String? cityName,
    String? temperature,
  }) {
    final t = context.read<ThemeState>();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MoodCardMaker(
        date: date,
        moodLabel: moodLabel,
        moodScore: moodScore,
        text: text,
        tags: tags,
        theme: t,
        createdAt: createdAt,
        weatherText: weatherText,
        cityName: cityName,
        temperature: temperature,
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
  bool _editMode = false;
  bool _squareCard = false; // false=圆角(温润), true=方形(方寸)

  // Edit options
  String _dateStyle = 'cn_full'; // cn_full | en_full | slash | dot
  String _watermark = 'en'; // cn | en | sq | sqrj | xiaoqing
  String _username = '';
  int? _overrideMoodScore;
  final List<String> _overrideTags = [];
  bool _showEmojiPicker = false;
  bool _showTagPicker = false;

  static const _cardThemes = ['warm', 'dark', 'mint', 'blush'];
  static const _allMoodEmojis = {1: '🎉', 2: '😌', 3: '😔', 4: '😤', 5: '😰', 6: '😴', 7: '🌟', 8: '💭'};
  static const _allMoodLabels = {1: '开心', 2: '平静', 3: '低落', 4: '生气', 5: '焦虑', 6: '疲惫', 7: '期待', 8: '想念'};
  static const _allTags = [
    '达成目标', '学习进步', '运动健身', '美食享受', '旅行出游',
    '朋友聚会', '家人陪伴', '独处时光', '工作顺利', '创作表达',
    '自然风景', '音乐电影', '购物开心', '睡眠充足', '小确幸',
  ];

  int get _activeMoodScore => _overrideMoodScore ?? widget.moodScore;
  List<String> get _activeTags => _overrideTags.isNotEmpty ? _overrideTags : widget.tags;

  String get _formattedDate {
    final d = DateTime.tryParse(widget.date) ?? DateTime.now();
    final weekdays = ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'];
    final enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final enMonths = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return switch (_dateStyle) {
      'en_full' => '${enMonths[d.month]} ${d.day}, ${d.year} ${enWeekdays[d.weekday - 1]}',
      'slash' => '${d.month}/${d.day}',
      'dot' => '${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}',
      _ => '${d.year}年${d.month}月${d.day}日 ${weekdays[d.weekday - 1]}',
    };
  }

  @override
  void initState() {
    super.initState();
    _cardTheme = widget.theme.themeMode;
  }

  Color get _bgColor {
    switch (_cardTheme) {
      case 'dark':
        return const Color(0xFF0E1222);
      case 'mint':
        return const Color(0xFFDDEBE3);
      case 'blush':
        return const Color(0xFFF2DED8);
      default:
        return const Color(0xFFFAF4EC);
    }
  }

  Color get _accentColor {
    switch (_cardTheme) {
      case 'dark':
        return const Color(0xFFB9B8FF);
      case 'mint':
        return const Color(0xFF4D8C7A);
      case 'blush':
        return const Color(0xFFC4707A);
      default:
        return const Color(0xFFB8782C);
    }
  }

  Color get _textColor {
    return _cardTheme == 'dark'
        ? const Color(0xFFF4F0E7)
        : const Color(0xFF2F2118);
  }

  String get _themeLabel => switch (_cardTheme) {
    'dark' => 'NIGHT NOTE',
    'mint' => 'MINT NOTE',
    'blush' => 'BLUSH NOTE',
    _ => 'SUNLIT NOTE',
  };

  Widget _buildCard() {
    final hasWeather =
        widget.weatherText != null && widget.weatherText!.isNotEmpty;

    final br = _squareCard ? 0.0 : 20.0;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(br),
        border: Border.all(
          color: _accentColor.withAlpha(_cardTheme == 'dark' ? 34 : 22),
          width: 0.5,
        ),
        boxShadow: XqDecorations.shadowStrong(),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(br),
        child: Stack(
          children: [
            SizedBox(
              height: 216,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(
                  children: [
                    // Top bar: date + theme branding
                    Row(
                      children: [
                        Text(
                          _formattedDate,
                          style: TextStyle(
                            color: _textColor.withAlpha(140),
                            fontSize: 11,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _themeLabel,
                          style: TextStyle(
                            color: _accentColor.withAlpha(95),
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),

                    if (hasWeather) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 9,
                            color: _accentColor.withAlpha(150),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${widget.weatherText}${widget.cityName != null ? "  ${widget.cityName}" : ""}${widget.temperature != null ? " · ${widget.temperature}" : ""}',
                              style: TextStyle(
                                color: _textColor.withAlpha(150),
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 4),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentColor.withAlpha(
                              _cardTheme == 'dark' ? 24 : 16,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: _accentColor.withAlpha(30),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            'MOOD',
                            style: TextStyle(
                              color: _accentColor.withAlpha(145),
                              fontSize: 7.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _moodEnglishFor(_activeMoodScore),
                          style: TextStyle(
                            color: _accentColor.withAlpha(118),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Expanded(
                      child: Center(
                        child: Text(
                          widget.text.isNotEmpty ? widget.text : '写点什么吧',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: widget.text.isNotEmpty
                                ? _textColor
                                : _textColor.withAlpha(60),
                            fontSize: widget.text.isNotEmpty ? 14.8 : 13.4,
                            height: 1.46,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),

                    // Tags + watermark row
                    Row(
                      children: [
                        if (_activeTags.isNotEmpty)
                          Expanded(
                            child: Text(
                              _activeTags.take(3).join(' · '),
                              style: TextStyle(
                                color: _accentColor.withAlpha(96),
                                fontSize: 9,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (_activeTags.isEmpty) const Spacer(),
                        if (_watermark == 'cn')
                          Text(
                            '拾晴日记',
                            style: TextStyle(
                              color: _accentColor.withAlpha(82),
                              fontSize: 8.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.15,
                            ),
                          )
                        else if (_watermark == 'en')
                          Text(
                            'SHI QING',
                            style: TextStyle(
                              color: _accentColor.withAlpha(82),
                              fontSize: 8.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.15,
                            ),
                          )
                        else if (_watermark == 'sq')
                          Text(
                            'sq.',
                            style: TextStyle(
                              color: _accentColor.withAlpha(82),
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          )
                        else if (_watermark == 'sqrj')
                          Text(
                            's q r j',
                            style: TextStyle(
                              color: _accentColor.withAlpha(82),
                              fontSize: 8.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          )
                        else if (_watermark == 'xiaoqing')
                          Text(
                            '小晴',
                            style: TextStyle(
                              color: _accentColor.withAlpha(82),
                              fontSize: 8.2,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.15,
                            ),
                          ),
                        if (_username.isNotEmpty) ...[
                          if (_activeTags.isNotEmpty || _watermark.isNotEmpty)
                            const SizedBox(width: 8),
                          Text(
                            _username,
                            style: TextStyle(
                              color: _accentColor.withAlpha(70),
                              fontSize: 8,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            if (_cardTheme == 'warm') _WarmOverlay(),
            if (_cardTheme == 'dark') _DarkOverlay(),
            if (_cardTheme == 'mint') _MintOverlay(),
            if (_cardTheme == 'blush') _BlushOverlay(accent: _accentColor),
          ],
        ),
      ),
    );
  }

  String _moodEnglishFor(int score) => switch (score) {
    1 => 'JOY',
    2 => 'CALM',
    3 => 'LOW',
    4 => 'ANGER',
    5 => 'ANXIETY',
    6 => 'TIRED',
    7 => 'HOPE',
    8 => 'MISSING',
    _ => 'MOOD',
  };

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(
        p.join(
          dir.path,
          'mood_card_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await Gal.putImage(file.path);
      if (mounted) {
        XqToast.success(context, '卡片已保存到相册');
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) XqToast.error(context, '保存失败');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    try {
      final boundary =
          _repaintKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'mood_card_share.png'));
      await file.writeAsBytes(byteData.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
              '拾晴日记 · ${widget.date}\n${widget.moodLabel} — ${widget.text.isNotEmpty ? widget.text : "记录天气，也记录你"}',
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {}
  }

  Widget _buildEditRow(String label, List<Widget> chips) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.theme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: chips.isNotEmpty
              ? Row(children: chips.map((c) => Padding(padding: const EdgeInsets.only(right: 6), child: c)).toList())
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildChip(String text, String value) {
    bool isActive = false;
    if (value == 'cn_full' || value == 'en_full' || value == 'slash' || value == 'dot') {
      isActive = _dateStyle == value;
    } else if (value == 'cn' || value == 'en' || value == 'sq' || value == 'sqrj' || value == 'xiaoqing') {
      isActive = _watermark == value;
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (value == 'cn_full' || value == 'en_full' || value == 'slash' || value == 'dot') {
            _dateStyle = value;
          } else if (value == 'cn' || value == 'en' || value == 'sq' || value == 'sqrj' || value == 'xiaoqing') {
            _watermark = value;
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? _accentColor.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? _accentColor : widget.theme.borderColor,
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? _accentColor : widget.theme.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _themeDot(String mode) {
    final active = _cardTheme == mode;
    final dotColors = switch (mode) {
      'dark' => [
        const Color(0xFF32376E),
        const Color(0xFF1B1F3B),
        const Color(0xFF0E1222),
      ],
      'mint' => [
        const Color(0xFF4D8C7A),
        const Color(0xFFA8D5C0),
        const Color(0xFFDDEBE3),
      ],
      'blush' => [
        const Color(0xFFC4707A),
        const Color(0xFFE7C0B8),
        const Color(0xFFF2DED8),
      ],
      _ => [
        const Color(0xFFB8782C),
        const Color(0xFFE2C99E),
        const Color(0xFFFAF4EC),
      ],
    };
    return GestureDetector(
      onTap: () => setState(() => _cardTheme = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        width: active ? 48 : 44,
        height: active ? 48 : 44,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(colors: dotColors),
          boxShadow: active
              ? [BoxShadow(color: dotColors[0].withAlpha(80), blurRadius: 10)]
              : null,
          border: Border.all(
            color: widget.theme.cardColor,
            width: active ? 3 : 2,
          ),
        ),
        child: active
            ? const Center(
                child: Icon(Icons.check, size: 18, color: Colors.white),
              )
            : null,
      ),
    );
  }

  Widget _buildStyleToggle(ThemeState theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildStylePill(theme, '温润', false),
        const SizedBox(width: 8),
        _buildStylePill(theme, '方寸', true),
      ],
    );
  }

  Widget _buildStylePill(ThemeState theme, String label, bool square) {
    final isActive = _squareCard == square;
    return GestureDetector(
      onTap: () => setState(() => _squareCard = square),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _accentColor.withAlpha(22) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isActive ? _accentColor.withAlpha(120) : theme.borderColor,
            width: isActive ? 1.2 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? _accentColor : theme.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sheetTheme = widget.theme;
    final screenHeight = MediaQuery.of(context).size.height;
    final sheetHeight = _editMode ? screenHeight * 0.85 : screenHeight * 0.72;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: sheetHeight,
      decoration: BoxDecoration(
        color: sheetTheme.cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetTheme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    '制成一张卡片',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: sheetTheme.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: () => setState(() => _editMode = !_editMode),
                    icon: Icon(
                      _editMode ? Icons.check : Icons.edit_outlined,
                      color: _editMode ? _accentColor : sheetTheme.textSecondary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                SizedBox(
                  width: 48,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: sheetTheme.textSecondary,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _editMode ? '编辑卡片内容' : '点击色块切换风格',
              style: TextStyle(color: sheetTheme.textTertiary, fontSize: 12),
            ),
            const SizedBox(height: 12),

            // Theme picker (non-edit mode)
            if (!_editMode) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _cardThemes.map(_themeDot).toList(),
              ),
              const SizedBox(height: 10),
              _buildStyleToggle(sheetTheme),
            ],

            // Edit panel (scrollable when expanded)
            if (_editMode)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _buildStyleToggle(sheetTheme),
                      const SizedBox(height: 10),
                      // Date format
                      _buildEditRow('日期格式', [
                        _buildChip('2026年5月28日', 'cn_full'),
                        _buildChip('May 28', 'en_full'),
                        _buildChip('5/28', 'slash'),
                        _buildChip('05.28', 'dot'),
                      ]),
                      const SizedBox(height: 10),
                      // Watermark
                      _buildEditRow('水印', [
                        _buildChip('拾晴日记', 'cn'),
                        _buildChip('SHI QING', 'en'),
                        _buildChip('s q r j', 'sqrj'),
                        _buildChip('小晴', 'xiaoqing'),
                      ]),
                      const SizedBox(height: 10),
                      // Username
                      _buildEditRow('用户名', []),
                      const SizedBox(height: 4),
                      TextField(
                        onChanged: (v) => setState(() => _username = v),
                        style: TextStyle(color: sheetTheme.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          labelText: '用户名',
                          hintText: '可选，留空则不显示',
                          labelStyle: TextStyle(color: sheetTheme.textTertiary, fontSize: 12),
                          hintStyle: TextStyle(color: sheetTheme.textTertiary, fontSize: 12),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(XqDecorations.radiusSmall),
                            borderSide: BorderSide(color: sheetTheme.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(XqDecorations.radiusSmall),
                            borderSide: BorderSide(color: sheetTheme.borderColor),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Emoji picker (mutually exclusive with tag picker)
                      GestureDetector(
                        onTap: () => setState(() {
                          _showEmojiPicker = !_showEmojiPicker;
                          if (_showEmojiPicker) _showTagPicker = false;
                        }),
                        child: _buildEditRow('情绪', [
                          Text(
                            '${_allMoodEmojis[_activeMoodScore] ?? ''} ${_allMoodLabels[_activeMoodScore] ?? ''}',
                            style: TextStyle(color: _accentColor, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                          Icon(_showEmojiPicker ? Icons.expand_less : Icons.expand_more, size: 18, color: sheetTheme.textTertiary),
                        ]),
                      ),
                      if (_showEmojiPicker) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: _allMoodEmojis.entries.map((e) {
                            final isActive = e.key == _activeMoodScore;
                            return GestureDetector(
                              onTap: () => setState(() {
                                _overrideMoodScore = e.key;
                                _showEmojiPicker = false;
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isActive ? _accentColor.withAlpha(20) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive ? _accentColor : sheetTheme.borderColor,
                                    width: isActive ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Text('${e.value} ${_allMoodLabels[e.key]}', style: const TextStyle(fontSize: 12)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 10),
                      // Tag picker (mutually exclusive with emoji picker)
                      GestureDetector(
                        onTap: () => setState(() {
                          _showTagPicker = !_showTagPicker;
                          if (_showTagPicker) _showEmojiPicker = false;
                        }),
                        child: _buildEditRow('标签', [
                          Text(
                            _activeTags.isEmpty ? '点击选择' : _activeTags.take(2).join(' · '),
                            style: TextStyle(
                              color: _activeTags.isEmpty ? sheetTheme.textTertiary : _accentColor,
                              fontSize: 12,
                            ),
                          ),
                          Icon(_showTagPicker ? Icons.expand_less : Icons.expand_more, size: 18, color: sheetTheme.textTertiary),
                        ]),
                      ),
                      if (_showTagPicker) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _allTags.map((tag) {
                            final isActive = _overrideTags.contains(tag);
                            return GestureDetector(
                              onTap: () => setState(() {
                                if (isActive) {
                                  _overrideTags.remove(tag);
                                } else {
                                  _overrideTags.add(tag);
                                }
                              }),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isActive ? _accentColor.withAlpha(20) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isActive ? _accentColor : sheetTheme.borderColor,
                                    width: isActive ? 1.2 : 0.8,
                                  ),
                                ),
                                child: Text(tag, style: TextStyle(fontSize: 11, color: isActive ? _accentColor : sheetTheme.textSecondary)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 10),

            // Card preview (fixed height, not Expanded)
            SizedBox(
              height: 216,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RepaintBoundary(key: _repaintKey, child: _buildCard()),
              ),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: Column(
                children: [
                  Container(
                    height: 1,
                    color: sheetTheme.borderColor.withAlpha(80),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('保存到相册'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accentColor,
                              side: BorderSide(
                                color: _accentColor.withAlpha(120),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _share,
                            icon: const Icon(Icons.share_rounded, size: 18),
                            label: const Text('分享给朋友'),
                            style: FilledButton.styleFrom(
                              backgroundColor: _accentColor,
                              foregroundColor: _cardTheme == 'dark'
                                  ? const Color(0xFF1B1F3B)
                                  : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
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

// ── Theme overlays ──

class _WarmOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PaperGrainPainter())),
            Positioned.fill(child: CustomPaint(painter: _SunlitMarkPainter())),
          ],
        ),
      ),
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(42);
    final paint = Paint()..color = const Color(0xFFB8782C).withAlpha(6);
    for (int i = 0; i < 200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), rng.nextDouble() * 0.8 + 0.2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SunlitMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..color = const Color(0xFFE7B45C).withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCircle(
          center: Offset(size.width - 34, 34),
          radius: 28.0 + i * 10,
        ),
        math.pi * 0.6,
        math.pi * 0.8,
        false,
        glow,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DarkOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0, -0.82),
                    radius: 1.15,
                    colors: [
                      const Color(0xFFFFD54F).withAlpha(12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: CustomPaint(painter: _StarDotsPainter())),
            Positioned.fill(
              child: CustomPaint(painter: _ConstellationPainter()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(123);
    final paint = Paint()..color = Colors.white.withAlpha(24);
    for (int i = 0; i < 42; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height * 0.72;
      final r = rng.nextDouble() * 0.6 + 0.2;
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConstellationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final points = [
      Offset(size.width - 88, 38),
      Offset(size.width - 64, 52),
      Offset(size.width - 42, 34),
    ];
    final line = Paint()
      ..color = Colors.white.withAlpha(18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    final dot = Paint()..color = Colors.white.withAlpha(38);
    for (var i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], line);
    }
    for (final p in points) {
      canvas.drawCircle(p, 1.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MintOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(painter: _BotanicalLinePainter()),
      ),
    );
  }
}

class _BotanicalLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF4D8C7A).withAlpha(34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    final stem = Path()
      ..moveTo(28, size.height - 24)
      ..quadraticBezierTo(34, size.height - 62, 22, size.height - 96);
    canvas.drawPath(stem, paint);
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(32, size.height - 62),
        width: 18,
        height: 8,
      ),
      math.pi,
      math.pi,
      false,
      paint,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(20, size.height - 82),
        width: 16,
        height: 7,
      ),
      0,
      math.pi,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BlushOverlay extends StatelessWidget {
  final Color accent;
  const _BlushOverlay({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _VelvetNoisePainter(accent: accent)),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _PostmarkPainter(accent: accent)),
            ),
          ],
        ),
      ),
    );
  }
}

class _VelvetNoisePainter extends CustomPainter {
  final Color accent;
  _VelvetNoisePainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(87);
    final area = size.width * size.height;
    final count = (area * 0.08).toInt();
    for (int i = 0; i < count; i++) {
      if (rng.nextDouble() > 0.5) continue;
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.2;
      canvas.drawCircle(Offset(x, y), r, Paint()..color = accent.withAlpha(3));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PostmarkPainter extends CustomPainter {
  final Color accent;
  _PostmarkPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent.withAlpha(30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    final center = Offset(size.width - 34, size.height - 34);
    canvas.drawCircle(center, 18, paint);
    canvas.drawLine(
      Offset(center.dx - 24, center.dy - 4),
      Offset(center.dx + 24, center.dy - 4),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - 22, center.dy + 5),
      Offset(center.dx + 20, center.dy + 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
