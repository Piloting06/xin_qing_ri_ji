import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/theme_state.dart';

class TreeholePage extends StatefulWidget {
  const TreeholePage({super.key});
  @override
  State<TreeholePage> createState() => _TreeholePageState();
}

class _TreeholePageState extends State<TreeholePage> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  int _page = 1;
  final _msgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await Api.getTreeholeMessages(page: _page);
      if (mounted) {
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _post() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    try {
      await Api.postTreehole(text);
      _msgCtrl.clear();
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('留言成功 🌳'),
              duration: Duration(seconds: 1)));
      _load();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)));
    } catch (_) {}
  }

  Future<void> _interact(int id, String type) async {
    try {
      await Api.interactTreehole(id, type);
      HapticFeedback.lightImpact();
      setState(() {
        final idx = _messages.indexWhere((m) => m['id'] == id);
        if (idx >= 0) {
          final key = type == 'cloud_hug' ? 'cloud_hugs' : 'cloud_coffees';
          _messages[idx][key] = (_messages[idx][key] ?? 0) + 1;
        }
      });
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message),
              duration: const Duration(seconds: 1)));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final t = theme;

    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(children: [
              Text('树洞',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: t.textPrimary)),
              const SizedBox(width: 8),
              Text('这里很安全，没有人知道你是谁',
                  style: TextStyle(fontSize: 12, color: t.textSecondary)),
              const Spacer(),
              IconButton(
                  icon: Icon(Icons.refresh, color: t.accentColor, size: 22),
                  onPressed: () { _page = 1; _load(); }),
            ]),
          ),
          // Messages
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFFC4A46C)))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _messages.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                  child: Text('还没有留言，来做第一个吧 🌱',
                                      style: TextStyle(
                                          color: t.textSecondary))),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16),
                            itemCount: _messages.length,
                            itemBuilder: (_, i) {
                              final m = _messages[i];
                              final isOwn =
                                  m['is_own'] == true;
                              return Container(
                                margin:
                                    const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: t.cardColor,
                                  borderRadius:
                                      BorderRadius.circular(14),
                                  border: Border.all(
                                      color: t.borderColor),
                                ),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Row(children: [
                                        const Text('🕊️',
                                            style: TextStyle(
                                                fontSize: 16)),
                                        if (isOwn)
                                          Padding(
                                            padding: const EdgeInsets
                                                .only(left: 6),
                                            child: Container(
                                                width: 4,
                                                height: 4,
                                                decoration: BoxDecoration(
                                                    shape: BoxShape
                                                        .circle,
                                                    color: t
                                                        .accentColor)),
                                          ),
                                      ]),
                                      const SizedBox(height: 8),
                                      Text(m['content'] ?? '',
                                          style: TextStyle(
                                              color:
                                                  t.textPrimary,
                                              fontSize: 14,
                                              height: 1.5)),
                                      const SizedBox(height: 10),
                                      Row(children: [
                                        _actionBtn(
                                            '☁️ ${m['cloud_hugs'] ?? 0}',
                                            () => _interact(
                                                m['id'],
                                                'cloud_hug')),
                                        const SizedBox(width: 16),
                                        _actionBtn(
                                            '☕ ${m['cloud_coffees'] ?? 0}',
                                            () => _interact(
                                                m['id'],
                                                'cloud_coffee')),
                                      ]),
                                    ]),
                              );
                            },
                          ),
                  ),
          ),
          // Post input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: t.cardColor,
              border: Border(
                  top: BorderSide(color: t.borderColor)),
            ),
            child: SafeArea(
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _msgCtrl,
                    maxLength: 200,
                    style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 14),
                    cursorColor: t.accentColor,
                    decoration: InputDecoration(
                      hintText: '说点什么...（每天3条）',
                      hintStyle: TextStyle(
                          color: t.textSecondary
                              .withAlpha(130)),
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(
                                  14)),
                      contentPadding: const EdgeInsets
                          .symmetric(
                          horizontal: 14,
                          vertical: 10),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.send_rounded,
                      color: t.accentColor),
                  onPressed: _post,
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Text(label,
          style: const TextStyle(
              color: Color(0xFFA09888), fontSize: 12)),
    );
  }
}
