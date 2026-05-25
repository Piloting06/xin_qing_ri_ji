import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../utils/helpers.dart';

import '../api/api_client.dart';
import '../services/notification_service.dart';
import '../stores/theme_state.dart';
import '../theme/xq_typography.dart';
import '../widgets/ink_writing_loader.dart';

class CapsulePage extends StatefulWidget {
  final int? initialCapsuleId;

  const CapsulePage({super.key, this.initialCapsuleId});

  @override
  State<CapsulePage> createState() => _CapsulePageState();
}

class _CapsulePageState extends State<CapsulePage> {
  List<Map<String, dynamic>> _capsules = [];
  bool _loading = true;
  bool _creating = false;
  bool _initialHandled = false;
  String? _error;
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
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data = await Api.getCapsuleList();
      if (mounted) {
        setState(() {
          _capsules = List<Map<String, dynamic>>.from(data['capsules'] ?? []);
          _loading = false;
        });
      }
      _maybeOpenInitialCapsule();
    } on ApiException catch (e) {
      if (e.statusCode == 401) return;
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '胶囊加载失败，请重试';
        });
      }
    }
  }

  void _maybeOpenInitialCapsule() {
    if (_initialHandled || widget.initialCapsuleId == null || !mounted) return;
    _initialHandled = true;
    Map<String, dynamic>? capsule;
    for (final item in _capsules) {
      if (readInt(item['id']) == widget.initialCapsuleId) {
        capsule = item;
        break;
      }
    }
    if (capsule == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('这张提醒卡对应的胶囊暂时没找到')),
      );
      return;
    }
    final targetCapsule = capsule;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _open(targetCapsule, fromReminder: true);
      }
    });
  }

  Future<void> _create() async {
    final text = _contentCtrl.text.trim();
    if (text.isEmpty || _creating) return;
    if (text.length > 500) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('内容最多 500 字')));
      return;
    }
    setState(() => _creating = true);
    final openDate = DateTime.now().add(Duration(days: _days));
    final dateStr = DateFormat('yyyy-MM-dd').format(openDate);
    try {
      final data = await Api.createCapsule(text, dateStr);
      final capsuleId = readInt(data['id']);
      var reminderReady = false;
      if (capsuleId != null) {
        reminderReady = await NotificationService.scheduleCapsuleReminder(
          capsuleId: capsuleId,
          openDate: data['open_date']?.toString() ?? dateStr,
          preview: _notificationPreview(text),
        );
      }
      _contentCtrl.clear();
      HapticFeedback.mediumImpact();
      if (mounted) {
        if (reminderReady) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _days == 1 ? '胶囊已封存，明天会提醒你' : '胶囊已封存，到时会提醒你回来打开'
              ),
            ),
          );
        } else {
          _showReminderHelp();
        }
      }
      await _load();
    } on ApiException catch (e) {
      if (e.statusCode == 401) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('创建失败，请稍后重试')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _open(
    Map<String, dynamic> capsule, {
    bool fromReminder = false,
  }) async {
    final id = readInt(capsule['id']);
    if (id == null) return;
    if (_isOpened(capsule)) {
      _showContent(capsule, fromReminder: fromReminder);
      return;
    }
    final openDate = DateTime.tryParse(capsule['open_date']?.toString() ?? '');
    if (openDate != null && openDate.isAfter(_today())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${DateFormat('M月d日').format(openDate)} 才能打开')),
      );
      return;
    }
    try {
      HapticFeedback.heavyImpact();
      final data = await Api.openCapsule(id);
      if (mounted) {
        _showContent(Map<String, dynamic>.from(data), fromReminder: fromReminder);
        await _load();
      }
    } on ApiException catch (e) {
      if (e.statusCode == 401) return;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('打开失败，请稍后重试')));
      }
    }
  }

  void _showReminderHelp() {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Provider.of<ThemeState>(ctx, listen: false);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: Text('胶囊已封存', style: TextStyle(color: theme.textPrimary)),
          content: Text(
            '提醒卡暂时没能安排上。\n\n'
            '如果你用的是 OPPO 或 vivo 手机，可以检查这几个设置：\n'
            '1. 系统设置 → 应用 → 心晴日记 → 通知 → 打开\n'
            '2. 系统设置 → 应用 → 心晴日记 → 电池 → 不优化\n'
            '3. 系统设置 → 应用 → 心晴日记 → 自启动 → 打开\n\n'
            '设置好后，下次创建胶囊就能正常提醒啦。',
            style: TextStyle(color: theme.textSecondary, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  void _showContent(
    Map<String, dynamic> capsule, {
    bool fromReminder = false,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Provider.of<ThemeState>(ctx, listen: false);
        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.borderColor),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      fromReminder
                          ? Icons.notifications_active_outlined
                          : Icons.mark_email_read_outlined,
                      color: theme.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      fromReminder ? '提醒你打开的胶囊' : '来自过去的自己',
                      style: XqTypography.headlineSmall.copyWith(
                        color: theme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  capsule['content']?.toString() ?? '',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '封存于 ${_shortDate(capsule['created_at'])}',
                  style: TextStyle(color: theme.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('收好'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      body: SafeArea(
        child: _loading
            ? Center(child: InkWritingLoader(inkColor: theme.gold, size: 40))
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _topBar(theme),
                    const SizedBox(height: 16),
                    _createCard(theme),
                    const SizedBox(height: 20),
                    if (_error != null)
                      _errorCard(theme)
                    else
                      _capsuleList(theme),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar(ThemeState theme) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: theme.textPrimary,
            size: 20,
          ),
        ),
        Expanded(
          child: Text(
            '时光胶囊',
            textAlign: TextAlign.center,
            style: XqTypography.headlineMedium.copyWith(
              color: theme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 48),
      ],
    );
  }

  Widget _createCard(ThemeState theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: theme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(theme.isDark ? 28 : 8),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '写给未来的自己',
            style: XqTypography.headlineSmall.copyWith(
              color: theme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '封存后到期前不能打开，现在可以自由选几天后再见。',
            style: TextStyle(color: theme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _contentCtrl,
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            style: TextStyle(color: theme.textPrimary, fontSize: 15),
            cursorColor: theme.accentColor,
            decoration: InputDecoration(
              hintText: '未来的我，想对你说...',
              hintStyle: TextStyle(color: theme.textSecondary.withAlpha(150)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              counterStyle: TextStyle(color: theme.textSecondary, fontSize: 11),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '$_days 天后打开',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('M月d日').format(
                  DateTime.now().add(Duration(days: _days)),
                ),
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: theme.accentColor,
              inactiveTrackColor: theme.borderColor,
              thumbColor: theme.accentColor,
            ),
            child: Slider(
              min: 1,
              max: 30,
              divisions: 29,
              value: _days.toDouble(),
              onChanged: (value) => setState(() => _days = value.round()),
            ),
          ),
          Row(
            children: [
              Text('1天后', style: TextStyle(color: theme.textTertiary, fontSize: 11)),
              const Spacer(),
              Text('3天', style: TextStyle(color: _days == 3 ? theme.accentColor : theme.textTertiary, fontSize: 11, fontWeight: _days == 3 ? FontWeight.w700 : FontWeight.w400)),
              const Spacer(),
              Text('7天', style: TextStyle(color: _days == 7 ? theme.accentColor : theme.textTertiary, fontSize: 11, fontWeight: _days == 7 ? FontWeight.w700 : FontWeight.w400)),
              const Spacer(),
              Text('14天', style: TextStyle(color: _days == 14 ? theme.accentColor : theme.textTertiary, fontSize: 11, fontWeight: _days == 14 ? FontWeight.w700 : FontWeight.w400)),
              const Spacer(),
              Text('30天后', style: TextStyle(color: _days == 30 ? theme.accentColor : theme.textTertiary, fontSize: 11, fontWeight: _days == 30 ? FontWeight.w700 : FontWeight.w400)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.surfaceAlpha,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notifications_active_outlined, color: theme.gold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '到了那天，我们会用一张提醒卡把你带回来。点开卡片，就能直接进入这颗胶囊。',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 12,
                      height: 1.45,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _creating ? null : _create,
              icon: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline, size: 18),
              label: Text(_creating ? '封存中' : '确认封存'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.accentColor,
                foregroundColor: theme.textOnAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(ThemeState theme) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: theme.errorColor),
          const SizedBox(height: 10),
          Text(_error!, style: TextStyle(color: theme.textPrimary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: _load, child: const Text('重试')),
        ],
      ),
    );
  }

  Widget _capsuleList(ThemeState theme) {
    if (_capsules.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.borderColor),
        ),
        child: Text(
          '还没有时光胶囊。',
          textAlign: TextAlign.center,
          style: TextStyle(color: theme.textSecondary),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '胶囊时间线',
          style: XqTypography.labelLarge.copyWith(color: theme.textSecondary),
        ),
        const SizedBox(height: 10),
        ..._capsules.map((c) => _capsuleCard(c, theme)),
      ],
    );
  }

  Widget _capsuleCard(Map<String, dynamic> capsule, ThemeState theme) {
    final opened = _isOpened(capsule);
    final openDate = DateTime.tryParse(capsule['open_date']?.toString() ?? '');
    final canOpen = !opened && openDate != null && !openDate.isAfter(_today());
    final daysLeft = openDate?.difference(_today()).inDays;
    final content = capsule['content']?.toString() ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _open(capsule),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: canOpen
                  ? theme.accentColor.withAlpha(140)
                  : theme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color:
                      (opened || canOpen ? theme.accentColor : theme.textTertiary)
                          .withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  opened
                      ? Icons.mark_email_read_outlined
                      : canOpen
                      ? Icons.lock_open_outlined
                      : Icons.lock_clock_outlined,
                  color: opened || canOpen
                      ? theme.accentColor
                      : theme.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opened
                          ? '已打开'
                          : canOpen
                          ? '可以打开了'
                          : '${DateFormat('M月d日').format(openDate ?? DateTime.now())} 可打开',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opened
                          ? (content.isEmpty ? '内容已开启' : content)
                          : canOpen
                          ? '点开看看过去的自己说了什么'
                          : '还剩 ${daysLeft == null ? '--' : daysLeft.clamp(1, 999)} 天',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.textTertiary, size: 20),
              if (opened)
                GestureDetector(
                  onTap: () => _deleteCapsule(capsule),
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(Icons.delete_outline, color: theme.errorColor.withAlpha(160), size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCapsule(Map<String, dynamic> capsule) async {
    final theme = context.read<ThemeState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text('撤回内容', style: TextStyle(color: theme.textPrimary)),
        content: const Text('确定删除这颗已打开的胶囊吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消', style: TextStyle(color: theme.textSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('删除', style: TextStyle(color: Color(0xFFD9706A)))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Api.deleteCapsule(capsule['id'] as int);
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('删除失败，请重试')));
    }
  }

  bool _isOpened(Map<String, dynamic> capsule) {
    final value = capsule['is_opened'];
    return value == true || value == 1 || value == '1';
  }

  DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _shortDate(dynamic value) {
    final text = value?.toString() ?? '';
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  String _notificationPreview(String text) {
    final cleaned = text.replaceAll('\n', ' ').trim();
    if (cleaned.length <= 36) return cleaned;
    return '${cleaned.substring(0, 36)}…';
  }
}

