import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../stores/theme_state.dart';

class WeatherFeedbackBar extends StatefulWidget {
  final String weatherText;
  final int? currentTemp;
  final int? high;
  final int? low;
  final String cityName;

  const WeatherFeedbackBar({
    super.key,
    required this.weatherText,
    this.currentTemp,
    this.high,
    this.low,
    required this.cityName,
  });

  @override
  State<WeatherFeedbackBar> createState() => _WeatherFeedbackBarState();
}

class _WeatherFeedbackBarState extends State<WeatherFeedbackBar> {
  bool _submitted = false;

  void _submitAccurate() {
    if (_submitted) return;
    setState(() => _submitted = true);
    Api.sendWeatherFeedback(
      type: '准确',
      weather: widget.weatherText,
      temp: '${widget.currentTemp ?? "--"}° / ${widget.low ?? "--"}° ~ ${widget.high ?? "--"}°',
      city: widget.cityName,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('感谢反馈！'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showInaccurateSheet() {
    if (_submitted) return;
    final theme = context.read<ThemeState>();
    String? selectedReason;
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: theme.borderColor, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),
                Text('哪里不准确？', style: TextStyle(color: theme.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: ['偏冷', '偏热', '降雨不准', '风速不准', '天气类型不符', '其他'].map((r) =>
                  GestureDetector(
                    onTap: () => setSheetState(() => selectedReason = selectedReason == r ? null : r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selectedReason == r ? theme.accentColor.withAlpha(30) : theme.cardElevated,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: selectedReason == r ? theme.accentColor : theme.borderColor.withAlpha(100)),
                      ),
                      child: Text(r, style: TextStyle(color: selectedReason == r ? theme.accentColor : theme.textPrimary, fontSize: 12)),
                    ),
                  ),
                ).toList()),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 2,
                  style: TextStyle(color: theme.textPrimary, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: '补充说明（选填）',
                    hintStyle: TextStyle(color: theme.textTertiary, fontSize: 13),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: theme.borderColor)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity, height: 46,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _submitted = true);
                      Api.sendWeatherFeedback(
                        type: selectedReason ?? '不准确',
                        weather: widget.weatherText,
                        temp: '${widget.currentTemp ?? "--"}° / ${widget.low ?? "--"}° ~ ${widget.high ?? "--"}°',
                        city: widget.cityName,
                        note: noteCtrl.text,
                      );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('感谢反馈！'), duration: Duration(seconds: 1)),
                        );
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.accentColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('提交反馈'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor.withAlpha(160),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor.withAlpha(80)),
      ),
      child: _submitted
          ? Row(
              children: [
                Icon(Icons.check_circle, color: theme.successColor, size: 18),
                const SizedBox(width: 8),
                Text('已收到反馈，谢谢！', style: TextStyle(color: theme.successColor, fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            )
          : Row(
              children: [
                Text('天气准确吗？', style: TextStyle(color: theme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                const Spacer(),
                GestureDetector(
                  onTap: _submitAccurate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.successColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('👍🏻 准确', style: TextStyle(color: theme.successColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showInaccurateSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.warningColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('👎🏻 不准', style: TextStyle(color: theme.warningColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
    );
  }
}
