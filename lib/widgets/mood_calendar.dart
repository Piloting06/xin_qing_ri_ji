import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/mood.dart';
import '../stores/theme_state.dart';

class MoodCalendar extends StatelessWidget {
  final List<Map<String, dynamic>> moods;
  final Function(String date) onDayTap;

  const MoodCalendar({super.key, required this.moods, required this.onDayTap});

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
    final theme = ThemeState();
    // We use context.watch in parent, but this widget is const-compatible
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final startOffset = firstDay.weekday % 7; // Sunday=0
    final totalDays = lastDay.day;
    final totalCells = startOffset + totalDays;
    final rows = (totalCells / 7).ceil();
    final moodMap = _moodMap;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0D8CC), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Text('${now.year}年${now.month}月',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF3D3228))),
            const Spacer(),
            Text('${moods.length} 条记录',
                style: const TextStyle(fontSize: 12, color: Color(0xFF8C7E6F))),
          ]),
          const SizedBox(height: 10),
          // Weekday headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['日', '一', '二', '三', '四', '五', '六'].map((d) => SizedBox(
              width: 30, child: Center(child: Text(d,
                  style: TextStyle(fontSize: 11, color: Color(0xFFB8A898)))))).toList(),
          ),
          const SizedBox(height: 4),
          // Calendar grid
          ...List.generate(rows, (row) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (col) {
                final cellIndex = row * 7 + col;
                final day = cellIndex - startOffset + 1;
                if (day < 1 || day > totalDays) return const SizedBox(width: 30, height: 34);

                final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final score = moodMap[dateStr];
                final isToday = day == now.day;

                return GestureDetector(
                  onTap: () => onDayTap(dateStr),
                  child: Container(
                    width: 30, height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday ? const Color(0xFFB8956A).withAlpha(20) : null,
                      border: isToday ? Border.all(color: const Color(0xFFB8956A), width: 1.5) : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(day.toString(),
                            style: TextStyle(
                                fontSize: 12,
                                color: isToday ? const Color(0xFF8B7355) : const Color(0xFF5D5348),
                                fontWeight: isToday ? FontWeight.w600 : FontWeight.normal)),
                        if (score != null)
                          Container(width: 6, height: 6,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(moodColors[score] ?? 0xFF90A4AE))),
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
