import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../api/api_client.dart';
import '../constants/mood.dart';
import 'diary_page.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';

class MoodPage extends StatefulWidget {
  const MoodPage({super.key});
  @override
  State<MoodPage> createState() => _MoodPageState();
}

class _MoodPageState extends State<MoodPage> {
  int _moodScore = 0;
  final _notesCtrl = TextEditingController();
  final Map<int, String> _emotionNotes = {}; // per-emotion independent text
  List<String> _selectedTags = [];
  List<String> _photos = [];
  bool _saving = false;
  bool _saved = false;
  String? _aiReply;
  String? _poemText;
  String? _poemAuthor;
  bool _loadingAi = false;
  List<Map<String, dynamic>> _allMoods = [];
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadToday();
    _loadAllMoods();
  }

  Future<void> _loadAllMoods() async {
    try {
      final data = await Api.getAllMoods();
      if (mounted && data['moods'] != null) {
        setState(() => _allMoods = List<Map<String, dynamic>>.from(data['moods']));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadToday() async {
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final mood = await Api.getMood(today);
      final prefs = await SharedPreferences.getInstance();
      final photoStr = prefs.getString('photos_$today') ?? '';
      if (mood != null && mounted) {
        setState(() {
          _moodScore = mood['emotion_type'] ?? 0;
          _notesCtrl.text = mood['notes'] ?? '';
          _selectedTags = (mood['emotion_tags'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [];
          _aiReply = mood['ai_response'];
          if (photoStr.isNotEmpty) _photos = photoStr.split('||');
        });
      } else {
        if (mounted && photoStr.isNotEmpty) setState(() => _photos = photoStr.split('||'));
      }
    } catch (_) {}
  }

  List<Map<String, String>> get _currentTags =>
      emotionTags[_moodScore] ?? [];

  Future<String> _persistPhoto(String tempPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!photosDir.existsSync()) photosDir.createSync(recursive: true);
    final name = 'mood_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final dest = p.join(photosDir.path, name);
    await File(tempPath).copy(dest);
    return dest;
  }

  Future<void> _pickPhoto() async {
    if (_photos.length >= 9) return;
    try {
      final img = await _picker.pickImage(
          source: ImageSource.gallery, maxWidth: 1080, imageQuality: 85);
      if (img != null && mounted) {
        final persistentPath = await _persistPhoto(img.path);
        setState(() => _photos.add(persistentPath));
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_moodScore == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个心情～')));
      return;
    }
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      // Fetch AI reply first
      String? aiReply;
      try {
        final aiRes = await Api.aiRespond(_moodScore, _notesCtrl.text, '');
        aiReply = aiRes['reply'];
        if (mounted) setState(() => _aiReply = aiReply);
      } catch (_) {}

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final photosStr = _photos.isNotEmpty ? _photos.join('||') : null;

      await Api.saveMood(today, _moodScore, _notesCtrl.text, _selectedTags, [],
          aiResponse: aiReply);

      // Save photo paths locally
      if (_photos.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('photos_$today', _photos.join('||'));
      }

      if (mounted) {
        setState(() { _saving = false; _saved = true; });
        Future.delayed(const Duration(seconds: 2),
            () { if (mounted) setState(() => _saved = false); });
      }

      // Fetch poem
      try {
        final poem = await Api.matchPoem(_moodScore, '');
        if (poem != null && mounted) {
          setState(() {
            _poemText = poem['quote_line'] ?? poem['content'];
            _poemAuthor = '${poem['poet'] ?? ''} · ${poem['dynasty'] ?? ''}';
          });
        }
      } catch (_) {}
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存失败: $e')));
      }
    }
  }

  Future<void> _fetchAiReply() async {
    setState(() => _loadingAi = true);
    try {
      final res = await Api.aiRespond(_moodScore, _notesCtrl.text, '');
      if (mounted) setState(() => _aiReply = res['reply']);
    } catch (_) {}
    // Fetch matching poem
    try {
      final poem = await Api.matchPoem(_moodScore, '');
      if (poem != null && mounted) {
        setState(() {
          _poemText = poem['quote_line'] ?? poem['content'];
          _poemAuthor = '${poem['poet'] ?? ''} · ${poem['dynasty'] ?? ''}';
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _loadingAi = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final t = theme; // shorthand

    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(children: [
              Text('今天的心情',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary)),
              const Spacer(),
              // Date nav
              IconButton(
                  icon: Icon(Icons.chevron_left, color: t.accentColor),
                  onPressed: () {
                    final d = DateTime.parse(appState.selectedDate)
                        .subtract(const Duration(days: 1));
                    appState.setSelectedDate(DateFormat('yyyy-MM-dd').format(d));
                    _loadToday();
                  }),
              GestureDetector(
                onTap: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(appState.selectedDate) ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now());
                  if (d != null) {
                    appState
                        .setSelectedDate(DateFormat('yyyy-MM-dd').format(d));
                    _loadToday();
                  }
                },
                child: Text(appState.selectedDate,
                    style: TextStyle(
                        color: t.textPrimary,
                        decoration: TextDecoration.underline)),
              ),
              IconButton(
                  icon: Icon(Icons.chevron_right, color: t.accentColor),
                  onPressed: () {
                    final d = DateTime.parse(appState.selectedDate)
                        .add(const Duration(days: 1));
                    if (!d.isAfter(DateTime.now())) {
                      appState.setSelectedDate(
                          DateFormat('yyyy-MM-dd').format(d));
                      _loadToday();
                    }
                  }),
            ]),
            const SizedBox(height: 16),
            // 8 Emotion buttons (2x4)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(8, (i) {
                final s = i + 1;
                final active = s == _moodScore;
                final color = Color(moodColors[s]!);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (!active) {
                      _emotionNotes[_moodScore] = _notesCtrl.text;
                      _moodScore = s;
                      _notesCtrl.text = _emotionNotes[s] ?? '';
                    } else {
                      _emotionNotes[_moodScore] = _notesCtrl.text;
                      _moodScore = 0;
                    }
                    _selectedTags = [];
                  }),
                  child: Container(
                    width: (MediaQuery.of(context).size.width - 48) / 4,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: active
                          ? color.withAlpha(25)
                          : t.surfaceAlpha,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: active ? color : t.borderColor,
                          width: active ? 2 : 1),
                    ),
                    child: Column(children: [
                      Text(moodEmojis[s]!,
                          style: const TextStyle(fontSize: 26)),
                      const SizedBox(height: 4),
                      Text(moodLabels[s]!,
                          style: TextStyle(
                              fontSize: 11,
                              color: active ? color : t.textSecondary)),
                    ]),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            // Emotion tags (dynamic)
            if (_moodScore > 0 && _currentTags.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _currentTags.take(16).map((tag) {
                  final sel = _selectedTags.contains(tag['id']);
                  return GestureDetector(
                    onTap: () => setState(() => sel
                        ? _selectedTags.remove(tag['id'])
                        : _selectedTags.add(tag['id']!)),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel
                            ? t.accentColor.withAlpha(30)
                            : t.surfaceAlpha,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: sel
                                ? t.accentColor
                                : t.borderColor),
                      ),
                      child: Text('${tag['icon']} ${tag['label']}',
                          style: TextStyle(
                              fontSize: 12,
                              color: sel
                                  ? t.accentColor
                                  : t.textSecondary)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
            ],
            // Notes
            Container(
              decoration: BoxDecoration(
                color: t.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: t.borderColor),
              ),
              child: TextField(
                controller: _notesCtrl,
                maxLines: 4,
                style: TextStyle(color: t.textPrimary, fontSize: 15),
                cursorColor: t.accentColor,
                decoration: InputDecoration(
                  hintText: _moodScore == 0
                      ? '今天发生了什么...'
                      : _placeholderForScore(_moodScore),
                  hintStyle: TextStyle(
                      color: t.textSecondary.withAlpha(130)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Photos
            if (_photos.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _photos.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        File(p),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )).toList(),
                ),
              ),
            const SizedBox(height: 8),
            // Photo picker + Save button
            Row(children: [
              IconButton(
                icon: Icon(Icons.add_photo_alternate_outlined,
                    color: t.textSecondary),
                onPressed: _pickPhoto,
                tooltip: '添加照片（仅存本地）',
              ),
              Text('${_photos.length}/9',
                  style: TextStyle(
                      fontSize: 12, color: t.textSecondary)),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saved
                    ? const Icon(Icons.check, size: 20)
                    : const Icon(Icons.save_outlined, size: 20),
                label: Text(_saving ? '保存中...' : (_saved ? '已保存' : '保存心情')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: t.accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ]),
            const SizedBox(height: 16),
            // AI reply + Poem
            if (_aiReply != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: t.surfaceAlpha,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: t.accentColor.withAlpha(40)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💛', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_aiReply!,
                            style: TextStyle(
                                color: t.textPrimary,
                                fontSize: 14, height: 1.6))),
                  ],
                ),
              ),
              if (_poemText != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: t.surfaceAlpha,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: t.accentColor.withAlpha(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('如果${_poemAuthor ?? "古人"}此刻在你身边...',
                          style: TextStyle(
                              fontSize: 11, color: t.textSecondary)),
                      const SizedBox(height: 4),
                      Text(_poemText!,
                          style: TextStyle(
                              color: t.accentColor,
                              fontSize: 15,
                              height: 1.5,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                ),
              ],
            ],
            // Diary entry guide
            if (_saved && _moodScore > 0)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DiaryPage(
                              initialDate: DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now())))),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: t.accentColor.withAlpha(15),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: t.accentColor.withAlpha(40)),
                    ),
                    child: const Text('📔 想展开写一篇日记吗？',
                        style: TextStyle(
                            color: Color(0xFFC4A46C), fontSize: 14)),
                  ),
                ),
              ),
            // Second-tier: suggest white noise for negative emotions
            if (_moodScore >= 3 && _moodScore <= 6 && _aiReply != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6E6480).withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                      '🌿 要不要听一会儿雨声？让心情慢慢平静下来...',
                      style: TextStyle(
                          color: Color(0xFF6E6480), fontSize: 13)),
                ),
              ),
            if (_loadingAi)
              const Padding(
                padding: EdgeInsets.all(12),
                child: LinearProgressIndicator(
                    color: Color(0xFFC4A46C)),
              ),
            const SizedBox(height: 24),
            // Visualization entries — tap to expand
            GestureDetector(
              onTap: () => _showFullChart(t),
              child: _buildChartPreview(t),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showFullPie(t),
              child: _buildPieChart(t),
            ),
            const SizedBox(height: 16),
            _buildMiniTimeline(t),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(ThemeState t) {
    if (_allMoods.isEmpty) return const SizedBox.shrink();
    final counts = <int, int>{};
    for (final m in _allMoods) {
      final s = m['emotion_type'] as int;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b);
    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('情绪分布',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.textPrimary)),
          const SizedBox(height: 12),
          SizedBox(
            height: 130,
            child: PieChart(
              PieChartData(
                sections: counts.entries.map((e) {
                  final color = Color(moodColors[e.key] ?? 0xFF90A4AE);
                  final pct = (e.value / total * 100).toStringAsFixed(1);
                  return PieChartSectionData(
                    color: color,
                    value: e.value.toDouble(),
                    title: '$pct%',
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w600),
                  );
                }).toList(),
                centerSpaceRadius: 22,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Legend
          Wrap(
            spacing: 10,
            runSpacing: 4,
            children: counts.entries.map((e) {
              final color = Color(moodColors[e.key] ?? 0xFF90A4AE);
              return Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 3),
                Text(moodEmojis[e.key] ?? '', style: const TextStyle(fontSize: 12)),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTimeline(ThemeState t) {
    if (_allMoods.isEmpty) return const SizedBox.shrink();
    final recent = _allMoods.take(10).toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('最近记录',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: t.textPrimary)),
          const SizedBox(height: 10),
          ...recent.map((m) {
            final score = m['emotion_type'] as int;
            final color = Color(moodColors[score] ?? 0xFF90A4AE);
            final date = m['date']?.toString() ?? '';
            return GestureDetector(
              onTap: () => _editMoodDay(date, score, m['notes']?.toString() ?? ''),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(width: 3, height: 24,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 10),
                  Text(moodEmojis[score] ?? '',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(date,
                      style: TextStyle(
                          color: t.textSecondary, fontSize: 12)),
                  const Spacer(),
                  Text(m['notes']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: t.textSecondary.withAlpha(150),
                          fontSize: 11)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, size: 14, color: t.textSecondary.withAlpha(80)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChartPreview(ThemeState t) {
    if (_allMoods.isEmpty) return const SizedBox.shrink();
    final moods = _allMoods.reversed.take(14).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (int i = 0; i < moods.length; i++) {
      final s = moods[i]['emotion_type'] as int;
      spots.add(FlSpot(i.toDouble(), moodScoreMap[s] ?? 3));
    }
    final avg = spots.isEmpty ? 0 : spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: t.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('心情曲线',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: t.textPrimary)),
            const Spacer(),
            Text('近${moods.length}天 · 均值${avg.toStringAsFixed(1)}',
                style: TextStyle(fontSize: 11, color: t.textSecondary)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: spots.length < 2
                ? Center(
                    child: Text('记录更多天后会显示曲线',
                        style: TextStyle(
                            color: t.textSecondary, fontSize: 12)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: t.accentColor,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: moods.length <= 7,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                                    radius: 3,
                                    color: t.accentColor,
                                    strokeWidth: 0),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: t.accentColor.withAlpha(15),
                          ),
                        ),
                      ],
                      minY: 0.5,
                      maxY: 5.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  String _placeholderForScore(int score) {
    switch (score) {
      case 1: return '太棒了！发生了什么好事呢？';
      case 2: return '这样的平静也很珍贵...';
      case 3: return '没关系的，把它写下来吧...';
      case 4: return '写出来可能会好受一点...';
      case 5: return '别担心，我们一起面对...';
      case 6: return '累了就休息，不需要理由～';
      case 7: return '在期待什么呢？分享一下吧～';
      case 8: return '想TA了就说出来吧...';
      default: return '今天发生了什么...';
    }
  }

  void _showFullChart(ThemeState t) {
    if (_allMoods.isEmpty) return;
    final moods = _allMoods.reversed.toList();
    final spots = <FlSpot>[];
    final labels = <int, String>{};
    for (int i = 0; i < moods.length; i++) {
      final s = moods[i]['emotion_type'] as int;
      spots.add(FlSpot(i.toDouble(), moodScoreMap[s] ?? 3));
      labels[i] = moods[i]['date']?.toString().substring(5) ?? '';
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 420,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                Text('心情曲线',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: t.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 20, 16),
                child: spots.length < 2
                    ? Center(child: Text('记录更多天后会显示曲线', style: TextStyle(color: t.textSecondary)))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            horizontalInterval: 1,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (v) => FlLine(
                                color: t.borderColor, strokeWidth: 0.5),
                          ),
                          titlesData: FlTitlesData(
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: (moods.length / 5).ceilToDouble().clamp(1, 10),
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= moods.length) return const SizedBox.shrink();
                                  return Text(labels[idx] ?? '',
                                      style: TextStyle(fontSize: 9, color: t.textSecondary));
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 28,
                                interval: 1,
                                getTitlesWidget: (v, _) => Text(
                                    ['', '😄', '😊', '😢', '😠', '😰', '😴', '🥰', '💭'][v.toInt().clamp(1, 8)],
                                    style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: spots,
                              isCurved: true,
                              color: t.accentColor,
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: moods.length <= 30,
                                getDotPainter: (spot, _, __, ___) =>
                                    FlDotCirclePainter(radius: 3, color: t.accentColor, strokeWidth: 0),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: t.accentColor.withAlpha(15),
                              ),
                            ),
                          ],
                          minY: 0.5,
                          maxY: 5.5,
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipItems: (spots) => spots.map((s) {
                                final idx = s.spotIndex;
                                final mood = moods[idx];
                                return LineTooltipItem(
                                  '${moodEmojis[mood['emotion_type']]}\n${mood['date']}',
                                  TextStyle(color: t.textPrimary, fontSize: 12),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _showFullPie(ThemeState t) {
    if (_allMoods.isEmpty) return;
    final counts = <int, int>{};
    for (final m in _allMoods) {
      final s = m['emotion_type'] as int;
      counts[s] = (counts[s] ?? 0) + 1;
    }
    final total = counts.values.fold(0, (a, b) => a + b);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: t.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          height: 440,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Row(children: [
                Text('情绪分布',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: t.textPrimary)),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: t.textSecondary, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ]),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 180,
              child: PieChart(
                PieChartData(
                  sections: counts.entries.map((e) {
                    final color = Color(moodColors[e.key] ?? 0xFF90A4AE);
                    final pct = (e.value / total * 100).toStringAsFixed(1);
                    return PieChartSectionData(
                      color: color,
                      value: e.value.toDouble(),
                      title: '$pct%',
                      radius: 60,
                      titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                  centerSpaceRadius: 30,
                  sectionsSpace: 3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Detailed legend with counts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: counts.entries.map((e) {
                  final color = Color(moodColors[e.key] ?? 0xFF90A4AE);
                  final emoji = moodEmojis[e.key] ?? '?';
                  final pct = (e.value / total * 100).toStringAsFixed(1);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(children: [
                      Container(width: 12, height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text(emoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(child: Text('${e.value}次', style: TextStyle(color: t.textPrimary, fontSize: 14))),
                      Text('$pct%', style: TextStyle(color: t.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Text('共 $total 条记录', style: TextStyle(color: t.textSecondary, fontSize: 12)),
          ]),
        ),
      ),
    );
  }

  void _editMoodDay(String date, int score, String notes) {
    HapticFeedback.lightImpact();
    setState(() {
      _moodScore = score;
      _emotionNotes[score] = notes;
      _notesCtrl.text = notes;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已加载 $date 的心情，可以修改后重新保存'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
