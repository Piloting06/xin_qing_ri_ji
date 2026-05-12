import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../constants/mood.dart';
import '../stores/theme_state.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});
  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  String _searchError = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final f = await Api.getFriendList();
      final r = await Api.getFriendRequests();
      if (mounted) {
        setState(() {
          _friends = List<Map<String, dynamic>>.from(f['friends'] ?? []);
          _requests = List<Map<String, dynamic>>.from(r['requests'] ?? []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() { _searchResults = []; _searchError = ''; });
      return;
    }
    setState(() => _searching = true);
    try {
      // Search by phone — backend returns user info if exists
      final data = await Api.searchUser(q.trim());
      if (mounted) {
        setState(() {
          _searchResults = data['users'] is List
              ? List<Map<String, dynamic>>.from(data['users'])
              : [];
          _searchError = _searchResults.isEmpty ? '未找到该用户' : '';
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _searchResults = []; _searchError = '搜索失败'; _searching = false; });
      }
    }
  }

  Future<void> _addFriend(String phone) async {
    try {
      await Api.addFriend(phone);
      _searchCtrl.clear();
      setState(() => _searchResults = []);
      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('好友请求已发送'),
                duration: Duration(seconds: 1)));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)));
      }
    } catch (_) {}
  }

  Future<void> _respond(int id, String status,
      {bool canView = false}) async {
    try {
      await Api.respondFriend(id, status, canViewMood: canView);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final t = theme;

    return Scaffold(
      backgroundColor: t.backgroundColor,
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFFC4A46C)))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('友人',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: t.textPrimary)),
                    const SizedBox(height: 14),
                    // Search bar
                    Container(
                      decoration: BoxDecoration(
                        color: t.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: t.borderColor),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 12),
                        Icon(Icons.search, size: 20, color: t.textSecondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            onChanged: _onSearch,
                            style: TextStyle(color: t.textPrimary, fontSize: 14),
                            cursorColor: t.accentColor,
                            decoration: InputDecoration(
                              hintText: '搜索手机号添加好友...',
                              hintStyle: TextStyle(color: t.textSecondary.withAlpha(130), fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.close, size: 18, color: t.textSecondary),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchResults = []);
                            },
                          ),
                      ]),
                    ),
                    // Search results
                    if (_searching)
                      const Padding(padding: EdgeInsets.all(16), child: LinearProgressIndicator(color: Color(0xFFC4A46C))),
                    if (_searchError.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(_searchError, style: TextStyle(color: t.textSecondary, fontSize: 13)),
                      ),
                    ..._searchResults.map((u) => Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: t.cardColor,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: t.borderColor),
                          ),
                          child: Row(children: [
                            Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: t.accentColor.withAlpha(25)),
                                child: Icon(Icons.person, color: t.accentColor, size: 22)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(u['display_name'] ?? u['phone'] ?? '',
                                    style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w500)),
                                Text(u['phone'] ?? '',
                                    style: TextStyle(color: t.textSecondary, fontSize: 12)),
                              ]),
                            ),
                            GestureDetector(
                              onTap: () => _addFriend(u['phone'] ?? ''),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: t.accentColor,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Text('添加', style: TextStyle(color: Colors.white, fontSize: 13)),
                              ),
                            ),
                          ]),
                        )),
                    const SizedBox(height: 16),
                    // Friend requests
                    if (_requests.isNotEmpty) ...[
                      Text('好友请求',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textSecondary)),
                      const SizedBox(height: 6),
                      ..._requests.map((r) => Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                                color: t.cardColor,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: t.borderColor)),
                            child: Row(children: [
                              Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFC4A46C).withAlpha(25)),
                                  child: const Icon(Icons.person_add, color: Color(0xFFC4A46C), size: 18)),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text(r['username'] ?? r['phone'] ?? '',
                                      style: TextStyle(color: t.textPrimary))),
                              TextButton(
                                  onPressed: () => _respond(r['id'], '1', canView: true),
                                  child: const Text('同意', style: TextStyle(color: Color(0xFF7B9E7B), fontSize: 13))),
                              TextButton(
                                  onPressed: () => _respond(r['id'], '-1'),
                                  child: const Text('拒绝', style: TextStyle(color: Color(0xFFD4837A), fontSize: 13))),
                            ]),
                          )),
                      const SizedBox(height: 12),
                    ],
                    // Friend list
                    if (_friends.isEmpty)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('还没有好友，搜手机号添加吧～',
                            style: TextStyle(color: t.textSecondary)),
                      ))
                    else ...[
                      Text('${_friends.length} 位好友',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.textSecondary)),
                      const SizedBox(height: 6),
                      ..._friends.map((f) => _FriendItem(friend: f, theme: t)),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FriendItem extends StatelessWidget {
  final Map<String, dynamic> friend;
  final ThemeState theme;
  const _FriendItem({required this.friend, required this.theme});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    final name = friend['username'] ?? friend['phone'] ?? '好友';
    final mood = friend['latest_mood'] as int?;
    final moodEmoji = moodEmojis[mood] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderColor),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: t.accentColor.withAlpha(25),
          ),
          child: Center(
            child: Text(moodEmoji.isNotEmpty ? moodEmoji : '👤',
                style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: TextStyle(color: t.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
            if (friend['signature'] != null)
              Text(friend['signature'] ?? '',
                  style: TextStyle(color: t.textSecondary, fontSize: 12)),
          ]),
        ),
        Icon(Icons.chevron_right, color: t.textSecondary.withAlpha(100), size: 20),
      ]),
    );
  }
}
