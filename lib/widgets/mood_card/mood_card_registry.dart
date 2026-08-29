import 'package:flutter/material.dart';
import 'film_card_template.dart';
import 'flame_card_template.dart';
import 'mood_card_data.dart';
import 'note_card_template.dart';
import 'sunny_card_template.dart';
import 'ticket_card_template.dart';
import 'weekly_card_template.dart';

/// 全部卡片模板。新增模板：写 builder → 在列表里加一条。
final moodCardTemplates = <MoodCardTemplateSpec>[
  MoodCardTemplateSpec(
    id: 'warm',
    name: '晨光',
    label: 'SUNLIT NOTE',
    dotColors: [Color(0xFFB8782C), Color(0xFFE2C99E), Color(0xFFFAF4EC)],
    buildCard: (data) => NoteCardTemplate.build(data, 'warm'),
  ),
  MoodCardTemplateSpec(
    id: 'dark',
    name: '夜航',
    label: 'NIGHT NOTE',
    dotColors: [Color(0xFF32376E), Color(0xFF1B1F3B), Color(0xFF0E1222)],
    buildCard: (data) => NoteCardTemplate.build(data, 'dark'),
  ),
  MoodCardTemplateSpec(
    id: 'mint',
    name: '薄荷',
    label: 'MINT NOTE',
    dotColors: [Color(0xFF4D8C7A), Color(0xFFA8D5C0), Color(0xFFDDEBE3)],
    buildCard: (data) => NoteCardTemplate.build(data, 'mint'),
  ),
  MoodCardTemplateSpec(
    id: 'blush',
    name: '绯霞',
    label: 'BLUSH NOTE',
    dotColors: [Color(0xFFC4707A), Color(0xFFE7C0B8), Color(0xFFF2DED8)],
    buildCard: (data) => NoteCardTemplate.build(data, 'blush'),
  ),
  MoodCardTemplateSpec(
    id: 'sunny',
    name: '晴收集',
    label: 'SUNNY PICKS',
    dotColors: [Color(0xFFDE9A26), Color(0xFF6E8F5E), Color(0xFF4F7396)],
    buildCard: SunnyCardTemplate.build,
  ),
  MoodCardTemplateSpec(
    id: 'film',
    name: '胶片',
    label: 'FILM',
    dotColors: [Color(0xFF151412), Color(0xFF757575), Color(0xFFFF8A50)],
    buildCard: FilmCardTemplate.build,
  ),
  MoodCardTemplateSpec(
    id: 'ticket',
    name: '车票',
    label: 'TICKET',
    dotColors: [Color(0xFFC04848), Color(0xFFE8D5B0), Color(0xFF8C6B3F)],
    buildCard: TicketCardTemplate.build,
  ),
  MoodCardTemplateSpec(
    id: 'flame',
    name: '火焰',
    label: 'STREAK',
    dotColors: [Color(0xFFFF7A3D), Color(0xFFB23A1B), Color(0xFF33190A)],
    buildCard: FlameCardTemplate.build,
  ),
  MoodCardTemplateSpec(
    id: 'weekly',
    name: '周历',
    label: 'WEEKLY',
    dotColors: [Color(0xFF8A7350), Color(0xFFE0D5C0), Color(0xFF33291C)],
    buildCard: WeeklyCardTemplate.build,
  ),
];

MoodCardTemplateSpec specById(String id) =>
    moodCardTemplates.firstWhere((t) => t.id == id,
        orElse: () => moodCardTemplates.first);
