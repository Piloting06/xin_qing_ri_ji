import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/xq_typography.dart';
import '../theme/xq_hand_drawn.dart';
import '../theme/xq_paper_textures.dart';
import '../theme/xq_decorations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../constants/mood.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';
import '../widgets/mood_card_maker.dart';
import '../widgets/xq_toast.dart';
import 'treehole_page.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});
  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  int _moodScore = 0;
  final _notesCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _editorKey = GlobalKey();
  final _emotionsKey = GlobalKey();
  final Map<int, String> _emotionNotes = {}; // per-emotion independent text
  List<String> _selectedTags = [];
  bool _saving = false;
  bool _saved = false;
  bool _dirty = false;
  bool _hydrating = false;
  List<Map<String, dynamic>> _allMoods = [];
  List<Map<String, dynamic>> _dayMoods = []; // 当天所有记录
  bool _dayMoodsExpanded = false;

  @override
  void initState() {
    super.initState();
    _notesCtrl.addListener(_markDirty);
    _loadDate(context.read<AppState>().selectedDate);
    _loadAllMoods();
  }

  Future<void> _loadAllMoods() async {
    try {
      final data = await Api.getAllMoods();
      if (mounted && data['moods'] != null) {
        setState(
          () => _allMoods = List<Map<String, dynamic>>.from(data['moods']),
        );
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) return;
      if (mounted) XqToast.error(context, '加载心情统计失败：${e.message}');
    } catch (_) {
      if (mounted) XqToast.error(context, '加载心情统计失败，请稍后重试');
    }
  }

  @override
  void dispose() {
    _notesCtrl.removeListener(_markDirty);
    _notesCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (_hydrating || _dirty) return;
    setState(() {
      _dirty = true;
      _saved = false;
    });
  }

  Future<void> _loadDate(String date, {bool showSnack = false}) async {
    _hydrating = true;
    if (mounted) {
      setState(() {
        _moodScore = 0;
        _notesCtrl.clear();
        _emotionNotes.clear();
        _selectedTags = [];
        _dirty = false;
        _saved = false;
        _dayMoods = [];
      });
    }

    try {
      final moods = await Api.getMoodsByDate(date);
      if (!mounted) return;

      setState(() {
        _dayMoods = moods;
        if (moods.isNotEmpty) {
          // 加载最新一条作为当前表单内容
          final latest = moods.last;
          _moodScore = _readMoodScore(latest['emotion_type']);
          _notesCtrl.text = latest['notes'] ?? '';
          if (_moodScore > 0) _emotionNotes[_moodScore] = _notesCtrl.text;
          _selectedTags =
              (latest['emotion_tags'] as String?)
                  ?.split(',')
                  .where((s) => s.isNotEmpty)
                  .toList() ??
              [];
        }
        _dirty = false;
        _saved = false;
      });
      _hydrating = false;

      if (showSnack && mounted) {
        final msg = moods.isEmpty ? '该日期暂无记录' : '已加载 $date 的 ${moods.length} 条记录';
        XqToast.info(context, msg);
      }
    } on ApiException catch (e) {
      _hydrating = false;
      if (e.statusCode == 401) return;
      if (mounted) XqToast.error(context, '加载心情失败：${e.message}');
    } catch (_) {
      _hydrating = false;
      if (mounted) XqToast.error(context, '加载心情失败，请稍后重试');
    }
  }

  void _changeDate(String date, {bool showSnack = false}) {
    context.read<AppState>().setSelectedDate(date);
    _loadDate(date, showSnack: showSnack);
  }

  int _readMoodScore(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  void _scrollToEditor() {
    if (_editorKey.currentContext == null) return;
    Scrollable.ensureVisible(
      _editorKey.currentContext!,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      alignment: 0.3,
    );
  }

  void _scrollToEmotions() {
    if (_emotionsKey.currentContext == null) return;
    Scrollable.ensureVisible(
      _emotionsKey.currentContext!,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: 0.2,
    );
  }

  void _selectMood(int s) {
    setState(() {
      if (s != _moodScore) {
        _emotionNotes[_moodScore] = _notesCtrl.text;
        _moodScore = s;
        _notesCtrl.text = _emotionNotes[s] ?? '';
      } else {
        _emotionNotes[_moodScore] = _notesCtrl.text;
        _moodScore = 0;
      }
      _dirty = true;
      _saved = false;
    });
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    final dt = DateTime.tryParse(createdAt.toString());
    if (dt == null) return '';
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  List<Map<String, String>> get _currentTags => emotionTags[_moodScore] ?? [];

  Future<void> _save() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      final date = context.read<AppState>().selectedDate;
      await Api.saveMood(date, _moodScore, _notesCtrl.text, _selectedTags, []);

      await _loadAllMoods();
      final dayMoods = await Api.getMoodsByDate(date);

      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
          _dirty = false;
          _dayMoods = dayMoods;
        });
        // First save toast
        final prefs = await SharedPreferences.getInstance();
        final hasSaved = prefs.getBool('mood_has_saved') ?? false;
        if (!hasSaved) {
          await prefs.setBool('mood_has_saved', true);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) XqToast.info(context, '试试把心情制成卡片分享给朋友吧 →');
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        XqToast.error(context, '保存失败：${e.message}');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        XqToast.error(context, '保存失败，请检查网络后重试');
      }
    }
  }

  Future<void> _openCardMaker() async {
    final appState = context.read<AppState>();
    String? weatherText, cityName, temperature;
    try {
      final prefs = await SharedPreferences.getInstance();
      final weatherData = prefs.getString('weather_data');
      if (weatherData != null) {
        final d = const JsonDecoder().convert(weatherData);
        final current = d['current'] as Map<String, dynamic>?;
        if (current != null) {
          weatherText = current['weather']?.toString();
          temperature = current['temp_current']?.toString() != null
              ? '${current['temp_current']}°'
              : null;
        }
      }
      cityName = prefs.getString('weather_city')?.toString();
      if (cityName != null && cityName.contains('，')) {
        cityName = cityName.split('，').first;
      }
    } catch (_) {}
    if (!mounted) return;
    await MoodCardMaker.show(
      context,
      date: appState.selectedDate,
      moodLabel: moodLabels[_moodScore] ?? '心情',
      moodScore: _moodScore,
      text: _notesCtrl.text,
      tags: _selectedTags,
      createdAt: DateTime.now().toUtc().toIso8601String(),
      weatherText: weatherText,
      cityName: cityName,
      temperature: temperature,
    );
    if (mounted) setState(() => _saved = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final t = theme; // shorthand

    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            RefreshIndicator(
              onRefresh: () async {
                await _loadAllMoods();
                if (!context.mounted) return;
                final date = context.read<AppState>().selectedDate;
                final dayMoods = await Api.getMoodsByDate(date);
                if (mounted) setState(() => _dayMoods = dayMoods);
              },
              child: ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                // Header
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '今天的心情',
                          style: XqTypography.headlineLarge.copyWith(
                            color: t.textPrimary,
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 6,
                          child: CustomPaint(
                            painter: HandDrawnDividerPainter(
                              inkColor: t.accentColor.withAlpha(60),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Date nav
                    IconButton(
                      icon: Icon(Icons.chevron_left, color: t.accentColor),
                      onPressed: () {
                        final d = DateTime.parse(
                          appState.selectedDate,
                        ).subtract(const Duration(days: 1));
                        _changeDate(DateFormat('yyyy-MM-dd').format(d));
                      },
                    ),
                    GestureDetector(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: context,
                          initialDate:
                              DateTime.tryParse(appState.selectedDate) ??
                              DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) {
                          _changeDate(DateFormat('yyyy-MM-dd').format(d));
                        }
                      },
                      child: Text(
                        appState.selectedDate,
                        style: TextStyle(
                          color: t.textPrimary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: t.accentColor),
                      onPressed: () {
                        final d = DateTime.parse(
                          appState.selectedDate,
                        ).add(const Duration(days: 1));
                        if (!d.isAfter(DateTime.now())) {
                          _changeDate(DateFormat('yyyy-MM-dd').format(d));
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Card preview hero / day summary
                _buildTodayCardPreview(t),
                const SizedBox(height: 16),
                // Recent records - mini cards
                _buildRecentDaysHorizontal(t),
                const SizedBox(height: 16),
                // 4-column emotion pills
                GridView.count(
                  key: _emotionsKey,
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.0,
                  children: List.generate(8, (i) {
                    final s = i + 1;
                    final active = s == _moodScore;
                    final color = Color(moodColors[s]!);
                    return GestureDetector(
                      onTap: () => _selectMood(s),
                      child: AnimatedScale(
                        scale: active ? 1.05 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutQuart,
                        child: Container(
                          decoration: BoxDecoration(
                            color: active
                                ? color.withAlpha(28)
                                : t.surfaceAlpha,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: active
                                  ? color.withAlpha(180)
                                  : t.borderColor.withAlpha(80),
                              width: active ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '${moodEmojis[s]} ${moodLabels[s]}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: active ? color : t.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Emotion tags (dynamic)
                if (_moodScore > 0 && _currentTags.isNotEmpty) ...[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _currentTags.take(8).toList().asMap().entries.map(
                      (entry) {
                        final tag = entry.value;
                        final sel = _selectedTags.contains(tag['id']);
                        return GestureDetector(
                          onTap: () => setState(() {
                            if (sel) {
                              _selectedTags.remove(tag['id']);
                            } else {
                              _selectedTags.add(tag['id']!);
                            }
                            _dirty = true;
                            _saved = false;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? t.accentColor.withAlpha(30)
                                  : t.borderColor.withAlpha(60),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: sel
                                    ? t.accentColor.withAlpha(180)
                                    : t.borderColor.withAlpha(40),
                              ),
                            ),
                            child: Text(
                              '${tag['icon']} ${tag['label']}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: sel
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: sel ? t.accentColor : t.textSecondary,
                              ),
                            ),
                          ),
                        );
                      },
                    ).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Notes — 横线纸风格
                AnimatedContainer(
                  key: _editorKey,
                  duration: const Duration(milliseconds: 180),
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    color: t.cardColor,
                    borderRadius: BorderRadius.circular(
                      XqDecorations.radiusMedium,
                    ),
                    border: Border.all(
                      color: t.borderColor,
                      width: 0.5,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: LinedPaperPainter(
                            lineColor: t.paperLine,
                            lineSpacing: 28,
                            marginLeft: 48,
                          ),
                        ),
                      ),
                      TextField(
                          controller: _notesCtrl,
                          maxLines: 4,
                          style: XqTypography.handwrittenBody.copyWith(
                            color: t.textPrimary,
                          ),
                          cursorColor: t.accentColor,
                          cursorWidth: 2.0,
                          onTap: () => Future.delayed(
                            const Duration(milliseconds: 300),
                            _scrollToEditor,
                          ),
                          decoration: InputDecoration(
                            hintText: _moodScore == 0
                                ? '写点什么吧...'
                                : _placeholderForScore(_moodScore),
                            hintStyle: TextStyle(
                              color: t.textSecondary.withAlpha(100),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                // Inline save bar
                _buildInlineSaveBar(t),
                const SizedBox(height: 16),
                // Treehole link
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TreeholePage(),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.auto_awesome_outlined,
                      size: 16,
                      color: t.textTertiary,
                    ),
                    label: Text(
                      '去树洞说说',
                      style: TextStyle(
                        color: t.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInlineSaveBar(ThemeState t) {
    final status = _saving
        ? '保存中...'
        : _saved
        ? '已保存'
        : _dirty
        ? '有改动未保存'
        : '选择心情或写下文字';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: t.cardColor.withAlpha(245),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderColor),
        boxShadow: XqDecorations.shadowSubtle(dark: t.isDark),
      ),
      child: Row(
        children: [
          Icon(
            _saved ? Icons.check_circle_outline : Icons.edit_note_outlined,
            color: _saved ? t.successColor : t.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          if (_saved) ...[
            // Card maker button (visible after save)
            TextButton.icon(
              onPressed: _openCardMaker,
              icon: Icon(Icons.auto_awesome, size: 16, color: t.gold),
              label: Text(
                '制作卡片',
                style: TextStyle(
                  color: t.gold,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: (_dirty && !_saving) ? _save : null,
              icon: _saving
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: t.textOnAccent,
                      ),
                    )
                  : Icon(_saved ? Icons.check : Icons.save_outlined, size: 18),
              label: Text(_saving ? '保存中' : '保存'),
              style: ElevatedButton.styleFrom(
                backgroundColor: t.accentColor,
                foregroundColor: t.textOnAccent,
                disabledBackgroundColor: t.borderColor,
                disabledForegroundColor: t.textTertiary,
                elevation: 0,
                minimumSize: const Size(100, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTodayCardPreview(ThemeState t) {
    if (_dayMoods.isNotEmpty) return _buildDayMoodsSummary(t);
    // Empty state: card preview hero
    final appState = context.read<AppState>();
    return GestureDetector(
      onTap: _scrollToEmotions,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(XqDecorations.radiusCard),
          border: Border.all(color: t.borderColor.withAlpha(80)),
          boxShadow: XqDecorations.shadowSubtle(dark: t.isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(XqDecorations.radiusCard),
          child: Stack(
            children: [
              // Subtle paper texture
              Positioned.fill(
                child: CustomPaint(
                  painter: LinedPaperPainter(
                    lineColor: t.paperLine.withAlpha(40),
                    lineSpacing: 28,
                    marginLeft: 48,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appState.selectedDate,
                      style: TextStyle(
                        fontSize: 11,
                        color: t.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            '今天还没有心情记录',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '选一个心情，开始记录吧',
                            style: TextStyle(
                              fontSize: 12,
                              color: t.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Spacer(),
                        Text(
                          'SHI QING',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: t.accentColor.withAlpha(60),
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
      ),
    );
  }

  Widget _buildDayMoodsSummary(ThemeState t) {
    if (_dayMoods.isEmpty) return const SizedBox.shrink();
    final latestMood = _dayMoods.last;
    final latestScore = _readMoodScore(latestMood['emotion_type']);
    final latestNotes = latestMood['notes']?.toString() ?? '';
    return AnimatedSize(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.cardColor,
          borderRadius: BorderRadius.circular(XqDecorations.radiusMedium),
          border: Border.all(color: t.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — always visible, clickable to toggle
            GestureDetector(
              onTap: () => setState(() => _dayMoodsExpanded = !_dayMoodsExpanded),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Icon(Icons.today_outlined, size: 16, color: t.accentColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '今天已记 ${_dayMoods.length} 条',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: t.textPrimary,
                      ),
                    ),
                  ),
                  if (!_dayMoodsExpanded && _dayMoods.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '${_dayMoods.length}条',
                        style: TextStyle(fontSize: 11, color: t.textTertiary),
                      ),
                    ),
                  Icon(
                    _dayMoodsExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: t.textTertiary,
                  ),
                ],
              ),
            ),
            // Collapsed: show only latest mood summary
            if (!_dayMoodsExpanded) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Color(moodColors[latestScore] ?? 0xFF90A4AE),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    moodEmojis[latestScore] ?? '',
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      latestNotes.isEmpty ? '(无文字)' : latestNotes,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
            // Expanded: show all moods
            if (_dayMoodsExpanded) ...[
              const SizedBox(height: 8),
              ..._dayMoods.map((m) {
                final score = _readMoodScore(m['emotion_type']);
                final color = Color(moodColors[score] ?? 0xFF90A4AE);
                final notes = m['notes']?.toString() ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        moodEmojis[score] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes.isEmpty ? '(无文字)' : notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: t.textSecondary, fontSize: 12),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _deleteDayMood(m['id'] as int),
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Icon(Icons.close, size: 16, color: t.textTertiary),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _deleteDayMood(int id) async {
    final date = context.read<AppState>().selectedDate;
    // Optimistic: remove from UI immediately
    setState(() => _dayMoods.removeWhere((m) => m['id'] == id));

    bool undone = false;

    // Show undo via a separate mechanism — use ScaffoldMessenger for persistent SnackBar
    final messenger = ScaffoldMessenger.of(context);
    final accentColor = context.read<ThemeState>().accentColor;
    final undoController = messenger.showSnackBar(
      SnackBar(
        content: const Text('已删除心情记录'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: '撤销',
          textColor: accentColor,
          onPressed: () => undone = true,
        ),
      ),
    );

    // Wait for SnackBar to dismiss
    await undoController.closed;

    if (undone) {
      // Restore: re-insert into list and reload
      await _loadAllMoods();
      final dayMoods = await Api.getMoodsByDate(date);
      if (mounted) setState(() => _dayMoods = dayMoods);
      return;
    }

    // Actually delete on server
    try {
      await Api.deleteMood(id);
      await _loadAllMoods();
    } catch (_) {}
  }

  Widget _buildRecentDaysHorizontal(ThemeState t) {
    if (_allMoods.isEmpty) return const SizedBox.shrink();
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final m in _allMoods) {
      final date = m['date']?.toString() ?? '';
      grouped.putIfAbsent(date, () => []).add(m);
    }
    final recentDates = grouped.keys.take(7).toList();
    final appState = context.read<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '最近记录',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recentDates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = recentDates[index];
              final moods = grouped[date]!;
              final latest = moods.last;
              final score = _readMoodScore(latest['emotion_type']);
              final notes = latest['notes']?.toString() ?? '';
              final isToday = date == appState.selectedDate;
              final moodColor = Color(moodColors[score] ?? 0xFF90A4AE);
              return GestureDetector(
                onTap: () {
                  if (isToday) {
                    _changeDate(date);
                    Future.delayed(
                      const Duration(milliseconds: 200),
                      _openCardMaker,
                    );
                  } else {
                    _showDayDetailSheet(date, moods);
                  }
                },
                child: Container(
                  width: 120,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: moodColor.withAlpha(18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isToday
                          ? t.gold.withAlpha(80)
                          : t.borderColor.withAlpha(60),
                      width: isToday ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            date.substring(5), // "MM-DD"
                            style: TextStyle(
                              fontSize: 10,
                              color: t.textTertiary,
                            ),
                          ),
                          if (moods.length > 1) ...[
                            const Spacer(),
                            Text(
                              '${moods.length}',
                              style: TextStyle(
                                fontSize: 9,
                                color: t.accentColor.withAlpha(140),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const Spacer(),
                      Center(
                        child: Text(
                          moodEmojis[score] ?? '',
                          style: const TextStyle(fontSize: 26),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        moodLabels[score] ?? '',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: moodColor.withAlpha(220),
                        ),
                      ),
                      if (notes.isNotEmpty)
                        Text(
                          notes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: t.textTertiary,
                            height: 1.2,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDayDetailSheet(String date, List<Map<String, dynamic>> moods) {
    final theme = context.read<ThemeState>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (ctx, scrollCtrl) => Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$date · ${moods.length}条记录',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: moods.length,
                  itemBuilder: (ctx, i) {
                    final m = moods[i];
                    final score = _readMoodScore(m['emotion_type']);
                    final tags = (m['emotion_tags'] as String?)
                            ?.split(',')
                            .where((s) => s.isNotEmpty)
                            .toList() ??
                        [];
                    return Dismissible(
                      key: ValueKey(m['id']),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: theme.errorColor,
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                        ),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('删除记录'),
                            content: const Text('确定要删除这条心情记录吗？'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('取消'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: Text(
                                  '删除',
                                  style: TextStyle(color: theme.errorColor),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await Api.deleteMood(m['id']);
                        await _loadAllMoods();
                        final dayMoods = await Api.getMoodsByDate(date);
                        if (mounted) setState(() => _dayMoods = dayMoods);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.surfaceAlpha,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  moodEmojis[score] ?? '',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  moodLabels[score] ?? '',
                                  style: TextStyle(
                                    color: theme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTime(m['created_at']),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: tags
                                    .map(
                                      (tag) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.accentColor.withAlpha(15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: theme.accentColor,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                            if ((m['notes']?.toString() ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                m['notes'].toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _placeholderForScore(int score) {
    switch (score) {
      case 1:
        return '太棒了！发生了什么好事呢？';
      case 2:
        return '这样的平静也很珍贵...';
      case 3:
        return '没关系的，把它写下来吧...';
      case 4:
        return '写出来可能会好受一点...';
      case 5:
        return '别担心，我们一起面对...';
      case 6:
        return '累了就休息，不需要理由～';
      case 7:
        return '在期待什么呢？分享一下吧～';
      case 8:
        return '想TA了就说出来吧...';
      default:
        return '今天发生了什么...';
    }
  }
}
