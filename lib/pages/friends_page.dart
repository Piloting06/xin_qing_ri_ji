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
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
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

  Future<void> _addFriend() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    try {
      await Api.addFriend(phone);
      _phoneCtrl.clear();
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
                    const SizedBox(height: 16),
                    // Add friend
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(
                              color: t.textPrimary, fontSize: 14),
                          cursorColor: t.accentColor,
                          decoration: InputDecoration(
                            hintText: '输入好友手机号...',
                            hintStyle: TextStyle(
                                color: t.textSecondary
                                    .withAlpha(130)),
                            border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                        14)),
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                          onPressed: _addFriend,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: t.accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(14))),
                          child: const Text('添加')),
                    ]),
                    const SizedBox(height: 16),
                    // Requests
                    if (_requests.isNotEmpty) ...[
                      Text('好友请求',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: t.textSecondary)),
                      ..._requests.map((r) => Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                                color: t.cardColor,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                    color: t.borderColor)),
                            child: Row(children: [
                              Expanded(
                                  child: Text(
                                      r['username'] ?? r['phone'] ?? '',
                                      style: TextStyle(
                                          color:
                                              t.textPrimary))),
                              TextButton(
                                  onPressed: () =>
                                      _respond(r['id'], '1',
                                          canView: true),
                                  child: const Text('同意',
                                      style: TextStyle(
                                          color: Color(
                                              0xFF7B9E7B)))),
                              TextButton(
                                  onPressed: () =>
                                      _respond(r['id'], '-1'),
                                  child: const Text('拒绝',
                                      style: TextStyle(
                                          color: Color(
                                              0xFFD4837A)))),
                            ]),
                          )),
                      const SizedBox(height: 16),
                    ],
                    // Friend list
                    if (_friends.isEmpty)
                      Center(
                          child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Text('还没有好友，搜手机号添加吧～',
                            style: TextStyle(
                                color: t.textSecondary)),
                      )),
                    ..._friends.map((f) => _FriendCard(
                        friend: f, theme: t)),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }
}

class _FriendCard extends StatefulWidget {
  final Map<String, dynamic> friend;
  final ThemeState theme;
  const _FriendCard({required this.friend, required this.theme});
  @override
  State<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends State<_FriendCard> {
  List<Map<String, dynamic>>? _moods;
  bool _loadingMoods = false;

  Future<void> _viewMoods() async {
    setState(() => _loadingMoods = true);
    try {
      final data =
          await Api.getFriendMood(widget.friend['friend_id']);
      if (mounted) {
        setState(() {
          _moods = List<Map<String, dynamic>>.from(data['moods'] ?? []);
          _loadingMoods = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _loadingMoods = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMoods = false);
    }
  }

  String _comfortText(int? score) {
    switch (score) {
      case 1: return '为这份开心点个赞吧～🎉';
      case 2: return '这份平静也很珍贵呢～';
      case 3: return '安慰下你朋友呀～🤍';
      case 4: return '有人陪着，气就消得快点吧～🌿';
      case 5: return '也许TA需要一个温暖的回应～💛';
      case 6: return '你的一句关心，TA会很暖的～🫂';
      case 7: return '一起期待这份美好吧～✨';
      case 8: return '给TA送一个云拥抱吧～☁️';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final f = widget.friend;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: t.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.borderColor),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.accentColor.withAlpha(30)),
                  child: Icon(Icons.person,
                      color: t.accentColor, size: 20)),
              const SizedBox(width: 10),
              Text(
                  f['username'] ?? f['phone'] ?? '好友',
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary)),
              const Spacer(),
              TextButton(
                  onPressed: _moods == null ? _viewMoods : null,
                  child: Text(
                      _moods != null ? '已加载' : '查看心情',
                      style: const TextStyle(
                          color: Color(0xFFC4A46C),
                          fontSize: 12))),
            ]),
            if (_loadingMoods)
              const LinearProgressIndicator(
                  color: Color(0xFFC4A46C)),
            if (_moods != null) ...[
              const SizedBox(height: 8),
              ..._moods!.map((m) {
                final score = m['emotion_type'] as int?;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Text(moodEmojis[score] ?? '',
                        style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(m['date'] ?? '',
                        style: TextStyle(
                            fontSize: 12,
                            color: t.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(
                            m['notes']?.toString() ?? '',
                            maxLines: 1,
                            overflow:
                                TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: t.textSecondary
                                    .withAlpha(150)))),
                  ]),
                );
              }),
              if (_moods!.isNotEmpty)
                Text(
                    _comfortText(
                        _moods!.first['emotion_type'] as int?),
                    style: const TextStyle(
                        color: Color(0xFFC4A46C),
                        fontSize: 12,
                        fontStyle: FontStyle.italic)),
            ],
          ]),
    );
  }
}
