import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../stores/theme_state.dart';
import '../theme/xq_typography.dart';
import '../theme/xq_paper_textures.dart';

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

  @override
  void initState() {
    super.initState();
    _date =
        widget.initialDate ?? DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    if (_titleCtrl.text.trim().isEmpty && _contentCtrl.text.trim().isEmpty) {
      return;
    }
    try {
      await Api.saveDiary(
        _date,
        _titleCtrl.text.trim(),
        _contentCtrl.text.trim(),
        null,
      );
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
        });
      } else {
        if (mounted) {
          setState(() {
            _titleCtrl.clear();
            _contentCtrl.clear();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _manualSave() async {
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    try {
      await Api.saveDiary(
        _date,
        _titleCtrl.text.trim(),
        _contentCtrl.text.trim(),
        null,
      );
      if (mounted) {
        setState(() {
          _saving = false;
          _saved = true;
        });
      }
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _saved = false);
      });
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final t = theme;

    return Scaffold(
      // 笔记本纸页背景
      backgroundColor: t.cardColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: t.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '日记',
          style: XqTypography.headlineMedium.copyWith(color: t.textPrimary),
        ),
        actions: [
          if (_saved)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '已保存',
                  style: TextStyle(fontSize: 12, color: t.successColor),
                ),
              ),
            ),
          IconButton(
            icon: _saving
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.accentColor,
                    ),
                  )
                : Icon(Icons.save_outlined, color: t.accentColor),
            onPressed: _saving ? null : _manualSave,
          ),
          IconButton(
            icon: Icon(Icons.search, color: t.textSecondary),
            onPressed: () => _showSearch(context, t),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // 横线纸背景
            Positioned.fill(
              child: CustomPaint(
                painter: LinedPaperPainter(
                  lineColor: t.paperLine,
                  lineSpacing: 28,
                  marginLeft: 40,
                  showMarginLine: false,
                ),
              ),
            ),
            // 内容
            Padding(
              padding: const EdgeInsets.only(
                left: 20,
                right: 16,
                top: 8,
                bottom: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date — 手写体
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          final d = DateTime.parse(
                            _date,
                          ).subtract(const Duration(days: 1));
                          _changeDate(DateFormat('yyyy-MM-dd').format(d));
                        },
                        child: Icon(
                          Icons.chevron_left,
                          color: t.accentColor,
                          size: 22,
                        ),
                      ),
                      GestureDetector(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate:
                                DateTime.tryParse(_date) ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) {
                            _changeDate(DateFormat('yyyy-MM-dd').format(d));
                          }
                        },
                        child: Text(
                          _date,
                          style: XqTypography.headlineSmall.copyWith(
                            color: t.textPrimary,
                            decoration: TextDecoration.underline,
                            decorationColor: t.accentColor.withAlpha(60),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          final d = DateTime.parse(
                            _date,
                          ).add(const Duration(days: 1));
                          if (!d.isAfter(DateTime.now())) {
                            _changeDate(DateFormat('yyyy-MM-dd').format(d));
                          }
                        },
                        child: Icon(
                          Icons.chevron_right,
                          color: t.accentColor,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Title — 手写体
                  TextField(
                    controller: _titleCtrl,
                    style: XqTypography.diaryTitle.copyWith(
                      color: t.textPrimary,
                    ),
                    cursorColor: t.accentColor,
                    cursorWidth: 2.0,
                    decoration: InputDecoration(
                      hintText: '标题...',
                      hintStyle: XqTypography.diaryTitle.copyWith(
                        color: t.textSecondary.withAlpha(100),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Content — 手写体，行高对齐 28px 横线
                  Expanded(
                    child: TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: XqTypography.diaryBody.copyWith(
                        color: t.textPrimary,
                      ),
                      cursorColor: t.accentColor,
                      cursorWidth: 2.0,
                      decoration: InputDecoration(
                        hintText: '今天想写点什么...',
                        hintStyle: XqTypography.diaryBody.copyWith(
                          color: t.textSecondary.withAlpha(80),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  prefixIcon: Icon(Icons.search, color: t.accentColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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

  void _showSearchResult(BuildContext context, List diaries, ThemeState t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: t.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SizedBox(
        height: 300,
        child: diaries.isEmpty
            ? Center(
                child: Text('没有找到日记', style: TextStyle(color: t.textSecondary)),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: diaries.length,
                itemBuilder: (_, i) {
                  final d = diaries[i] as Map<String, dynamic>;
                  return ListTile(
                    title: Text(
                      d['title'] ?? '无标题',
                      style: TextStyle(color: t.textPrimary),
                    ),
                    subtitle: Text(
                      d['date'] ?? '',
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
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
