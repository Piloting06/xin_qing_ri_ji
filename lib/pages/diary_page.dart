import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../stores/app_state.dart';
import '../stores/theme_state.dart';

class DiaryPage extends StatefulWidget {
  final String? initialDate;
  const DiaryPage({super.key, this.initialDate});
  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  String _date = '';
  bool _saving = false;
  bool _saved = false;
  int? _diaryId;

  @override
  void initState() {
    super.initState();
    _date = widget.initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
    _load();
    _titleCtrl.addListener(_onChange);
    _contentCtrl.addListener(_onChange);
  }

  Timer? _autoSaveTimer;
  void _onChange() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 800), _autoSave);
  }

  Future<void> _autoSave() async {
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) return;
    try {
      await Api.saveDiary(_date, _titleCtrl.text.trim(), _contentCtrl.text.trim(), null);
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final diary = await Api.getDiary(_date);
      if (diary != null && mounted) {
        setState(() {
          _titleCtrl.text = diary['title'] ?? '';
          _contentCtrl.text = diary['content'] ?? '';
          _diaryId = diary['id'];
        });
      } else {
        if (mounted) {
          setState(() { _titleCtrl.clear(); _contentCtrl.clear(); _diaryId = null; });
        }
      }
    } catch (_) {}
  }

  Future<void> _manualSave() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await Api.saveDiary(_date, _titleCtrl.text.trim(), _contentCtrl.text.trim(), null);
      if (mounted) setState(() { _saving = false; _saved = true; });
      Future.delayed(const Duration(seconds: 2),
          () { if (mounted) setState(() => _saved = false); });
    } catch (e) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final appState = context.watch<AppState>();
    final t = theme;

    return Scaffold(
      backgroundColor: t.backgroundColor,
      appBar: AppBar(
        backgroundColor: t.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: t.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('日记',
            style: TextStyle(color: t.textPrimary, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: t.textSecondary),
            onPressed: () => _showSearch(context, t),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date
              Row(children: [
                IconButton(
                    icon: Icon(Icons.chevron_left, color: t.accentColor, size: 22),
                    onPressed: () {
                      final d = DateTime.parse(_date).subtract(const Duration(days: 1));
                      _changeDate(DateFormat('yyyy-MM-dd').format(d));
                    }),
                GestureDetector(
                  onTap: () async {
                    final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now());
                    if (d != null) _changeDate(DateFormat('yyyy-MM-dd').format(d));
                  },
                  child: Text(_date,
                      style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 16,
                          decoration: TextDecoration.underline)),
                ),
                IconButton(
                    icon: Icon(Icons.chevron_right, color: t.accentColor, size: 22),
                    onPressed: () {
                      final d = DateTime.parse(_date).add(const Duration(days: 1));
                      if (!d.isAfter(DateTime.now())) {
                        _changeDate(DateFormat('yyyy-MM-dd').format(d));
                      }
                    }),
                const Spacer(),
                if (_saved) const Text('✅ 已保存', style: TextStyle(fontSize: 12, color: Color(0xFF7B9E7B))),
              ]),
              const SizedBox(height: 12),
              // Title
              TextField(
                controller: _titleCtrl,
                style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w600),
                cursorColor: t.accentColor,
                decoration: InputDecoration(
                  hintText: '标题...',
                  hintStyle: TextStyle(
                      color: t.textSecondary.withAlpha(130)),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 8),
              // Content
              Expanded(
                child: TextField(
                  controller: _contentCtrl,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 15,
                      height: 1.8),
                  cursorColor: t.accentColor,
                  decoration: InputDecoration(
                    hintText: '今天想写点什么...',
                    hintStyle: TextStyle(
                        color: t.textSecondary.withAlpha(100)),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeDate(String d) {
    _autoSaveTimer?.cancel();
    _autoSave();
    setState(() => _date = d);
    _load();
  }

  void _showSearch(BuildContext context, ThemeState t) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: t.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                style: TextStyle(color: t.textPrimary),
                decoration: InputDecoration(
                  hintText: '搜索日记...',
                  prefixIcon:
                      Icon(Icons.search, color: t.accentColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onSubmitted: (q) async {
                  Navigator.pop(ctx);
                  if (q.trim().isNotEmpty) {
                    final res = await Api.searchDiary(q);
                    // Show result in a simple dialog
                    if (ctx.mounted) {
                      _showSearchResult(context, res['diaries'] ?? [], t);
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSearchResult(
      BuildContext context, List diaries, ThemeState t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SizedBox(
        height: 300,
        child: diaries.isEmpty
            ? Center(
                child: Text('没有找到日记',
                    style: TextStyle(color: t.textSecondary)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: diaries.length,
                itemBuilder: (_, i) {
                  final d = diaries[i] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(d['title'] ?? '无标题',
                        style: TextStyle(color: t.textPrimary)),
                    subtitle: Text(d['date'] ?? '',
                        style: TextStyle(
                            color: t.textSecondary, fontSize: 12)),
                    onTap: () {
                      Navigator.pop(context);
                      _changeDate(d['date']);
                    },
                  );
                },
              ),
      ),
    );
  }
}
