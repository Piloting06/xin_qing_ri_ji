import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/mood.dart';
import '../stores/theme_state.dart';

class MoodCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> moods;
  final String selectedDate;
  final Function(String date) onDayTap;

  const MoodCalendar({
    super.key,
    required this.moods,
    required this.selectedDate,
    required this.onDayTap,
  });

  Map<String, int> get _moodMap {
    final map = <String, int>{};
    for (final m in moods) {
      final date = m['date']?.toString() ?? '';
      final score = m['emotion_type'] as int?;
      if (date.isNotEmpty && score != null) map[date] = score;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final now = DateTime.now();
    final selected = DateTime.tryParse(selectedDate) ?? now;
    final firstDay = DateTime(selected.year, selected.month, 1);
    final lastDay = DateTime(selected.year, selected.month + 1, 0);
    final startOffset = firstDay.weekday % 7;
    final totalDays = lastDay.day;
    final totalCells = startOffset + totalDays;
    final rows = (totalCells / 7).ceil();
    final moodMap = _moodMap;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.borderColor, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                '${selected.year}年${selected.month}月',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${moods.length} 条记录',
                style: TextStyle(fontSize: 12, color: theme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['日', '一', '二', '三', '四', '五', '六']
                .map((d) => SizedBox(
                      width: 30,
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.textTertiary,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 4),
          ...List.generate(rows, (row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final day = cellIndex - startOffset + 1;
                if (day < 1 || day > totalDays) {
                  return const SizedBox(width: 30, height: 34);
                }

                final mm = selected.month.toString().padLeft(2, '0');
                final dd = day.toString().padLeft(2, '0');
                final dateStr = '${selected.year}-$mm-$dd';
                final score = moodMap[dateStr];
                final isToday =
                    selected.year == now.year && selected.month == now.month && day == now.day;
                final isSelected = dateStr == selectedDate;
                final isFuture = DateTime(selected.year, selected.month, day)
                    .isAfter(DateTime(now.year, now.month, now.day));

                return GestureDetector(
                  onTap: isFuture ? null : () => onDayTap(dateStr),
                  child: Container(
                    width: 30,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? theme.accentColor.withAlpha(32)
                          : isToday
                          ? theme.accentColor.withAlpha(10)
                          : null,
                      border: isSelected
                          ? Border.all(color: theme.accentColor, width: 1.6)
                          : isToday
                          ? Border.all(
                              color: theme.accentColor.withAlpha(120),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          day.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            color: isFuture
                                ? theme.textTertiary.withAlpha(100)
                                : isSelected || isToday
                                ? theme.accentColor
                                : theme.textPrimary,
                            fontWeight: isSelected || isToday
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                        if (score != null)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(moodColors[score] ?? 0xFF90A4AE),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }),
            );
          }),
        ],
      ),
    );
  }
}
