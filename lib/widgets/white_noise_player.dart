import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';

class WhiteNoisePlayer extends StatefulWidget {
  const WhiteNoisePlayer({super.key});
  @override
  State<WhiteNoisePlayer> createState() => _WhiteNoisePlayerState();
}

class _WhiteNoisePlayerState extends State<WhiteNoisePlayer> {
  int? _playingIndex;
  double _volume = 0.4;

  static const _sounds = [
    {'icon': '🌧️', 'label': '雨声', 'id': 'rain'},
    {'icon': '🔥', 'label': '篝火', 'id': 'campfire'},
    {'icon': '🌊', 'label': '海浪', 'id': 'ocean'},
    {'icon': '🌲', 'label': '森林鸟鸣', 'id': 'forest'},
    {'icon': '🎐', 'label': '风铃', 'id': 'chime'},
    {'icon': '💓', 'label': '心跳', 'id': 'heartbeat'},
  ];

  void _toggle(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _playingIndex = _playingIndex == index ? null : index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final isPlaying = _playingIndex != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Grid of 6 sounds
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_sounds.length, (i) {
            final s = _sounds[i];
            final active = _playingIndex == i;
            return GestureDetector(
              onTap: () => _toggle(i),
              child: Container(
                width: (MediaQuery.of(context).size.width - 56) / 3,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: active
                      ? theme.accentColor.withAlpha(25)
                      : theme.surfaceAlpha,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: active
                          ? theme.accentColor
                          : theme.borderColor,
                      width: active ? 1.5 : 1.0),
                ),
                child: Column(children: [
                  Text(s['icon']!,
                      style: TextStyle(
                          fontSize: active ? 30 : 26)),
                  const SizedBox(height: 6),
                  Text(s['label']!,
                      style: TextStyle(
                          fontSize: 12,
                          color: active
                              ? theme.accentColor
                              : theme.textSecondary)),
                ]),
              ),
            );
          }),
        ),
        if (isPlaying) ...[
          const SizedBox(height: 16),
          // Volume slider
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.borderColor),
            ),
            child: Row(children: [
              const Icon(Icons.volume_down,
                  size: 20, color: Color(0xFFC4A46C)),
              Expanded(
                child: Slider(
                  value: _volume,
                  min: 0,
                  max: 1,
                  activeColor: theme.accentColor,
                  onChanged: (v) =>
                      setState(() => _volume = v),
                ),
              ),
              const Icon(Icons.volume_up,
                  size: 20, color: Color(0xFFC4A46C)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.stop,
                    size: 20,
                    color: Color(0xFFD4837A)),
                onPressed: () =>
                    setState(() => _playingIndex = null),
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
