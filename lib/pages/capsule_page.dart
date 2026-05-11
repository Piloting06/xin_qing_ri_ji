import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../api/api_client.dart';
import '../stores/theme_state.dart';

class CapsulePage extends StatefulWidget {
  const CapsulePage({super.key});
  @override
  State<CapsulePage> createState() => _CapsulePageState();
}

class _CapsulePageState extends State<CapsulePage> {
  List<Map<String, dynamic>> _capsules = [];
  bool _loading = true;
  final _contentCtrl = TextEditingController();
  int _days = 3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await Api.getCapsuleList();
      if (mounted) {
        setState(() {
          _capsules = List<Map<String, dynamic>>.from(data['capsules'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty) return;
    final openDate = DateTime.now().add(Duration(days: _days));
    final dateStr = DateFormat('yyyy-MM-dd').format(openDate);
    try {
      await Api.createCapsule(text, dateStr);
      _contentCtrl.clear();
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('胶囊已封存 ✉️'),
                duration: Duration(seconds: 1)));
        _load();
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)));
      }
    } catch (_) {}
  }

  Future<void> _open(int id, int index) async {
    final capsule = _capsules[index];
    if (capsule['is_opened'] == 1) {
      _showContent(capsule);
      return;
    }
    // Check if it's time to open
    final openDate = DateTime.tryParse(capsule['open_date'] ?? '');
    if (openDate != null && openDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${DateFormat('M月d日').format(openDate)} 才能打开哦～')));
      return;
    }
    try {
      HapticFeedback.heavyImpact();
      final data = await Api.openCapsule(id);
      if (mounted) {
        _showContent(Map<String, dynamic>.from(data));
        _load();
      }
    } catch (_) {}
  }

  void _showContent(Map<String, dynamic> c) {
    showDialog(
        context: context,
        builder: (ctx) {
          final theme = Provider.of<ThemeState>(ctx, listen: false);
          return AlertDialog(
            backgroundColor: theme.cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('💌 时光胶囊', style: TextStyle(color: theme.accentColor)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['content'] ?? '',
                    style: TextStyle(color: theme.textPrimary, fontSize: 16, height: 1.6)),
                const SizedBox(height: 12),
                Text('封存于 ${c['created_at'] ?? c['open_date'] ?? ''}',
                    style: TextStyle(color: theme.textSecondary, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('关闭', style: TextStyle(color: Color(0xFFA09888)))),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final t = theme;

    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFC4A46C)))
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('← 返回',
                          style: TextStyle(color: Color(0xFFC4A46C))),
                    ),
                    const SizedBox(width: 16),
                    Text('时光胶囊',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: t.textPrimary)),
                  ]),
                  const SizedBox(height: 20),
                  // Create capsule
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: t.cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: t.borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('给未来的自己写一句话...',
                            style: TextStyle(fontSize: 13, color: t.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _contentCtrl,
                          maxLines: 3,
                          style: TextStyle(color: t.textPrimary, fontSize: 15),
                          cursorColor: t.accentColor,
                          decoration: InputDecoration(
                            hintText: '3天后的我想对自己说...',
                            hintStyle: TextStyle(color: t.textSecondary.withAlpha(130)),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(children: [
                          Text('封存时间：', style: TextStyle(color: t.textSecondary, fontSize: 13)),
                          _dayBtn(3),
                          _dayBtn(7),
                          const Spacer(),
                          ElevatedButton(
                              onPressed: _create,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: t.accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: const Text('封存 ✉️')),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Capsule list
                  if (_capsules.isEmpty)
                    Center(
                        child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Text('还没有时光胶囊\n写一句话给未来的自己吧',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: t.textSecondary)),
                    )),
                  ..._capsules.map((c) {
                    final isOpen = c['is_opened'] == 1;
                    final openDate = c['open_date'] ?? '';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isOpen ? t.surfaceAlpha : t.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.borderColor),
                      ),
                      child: ListTile(
                        leading: Text(isOpen ? '💌' : '✉️', style: const TextStyle(fontSize: 24)),
                        title: Text(
                            isOpen ? '已开启' : '$openDate 开启',
                            style: TextStyle(color: t.textPrimary, fontSize: 14)),
                        subtitle: isOpen && c['content'] != null
                            ? Text(c['content'].toString(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: t.textSecondary, fontSize: 12))
                            : null,
                        trailing: const Icon(Icons.chevron_right, color: Color(0xFF787060)),
                        onTap: () => _open(c['id'], _capsules.indexOf(c)),
                      ),
                    );
                  }),
                  const SizedBox(height: 60),
                ],
              ),
      ),
    );
  }

  Widget _dayBtn(int days) {
    final active = _days == days;
    return GestureDetector(
      onTap: () => setState(() => _days = days),
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFC4A46C).withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? const Color(0xFFC4A46C) : const Color(0xFF4A4440)),
        ),
        child: Text('${days}天后',
            style: TextStyle(
                color: active ? const Color(0xFFC4A46C) : const Color(0xFF8C8C8C),
                fontSize: 12)),
      ),
    );
  }
}
