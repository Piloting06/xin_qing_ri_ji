import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../stores/theme_state.dart';

class WhiteNoisePlayer extends StatefulWidget {
  const WhiteNoisePlayer({super.key});
  @override
  State<WhiteNoisePlayer> createState() => _WhiteNoisePlayerState();
}

class _WhiteNoisePlayerState extends State<WhiteNoisePlayer> {
  final _player = AudioPlayer();
  int? _playingIndex;
  double _volume = 0.4;
  bool _loadingAudio = false;

  static const _sounds = [
    {'icon': '\u{1F327}\u{FE0F}', 'label': '雨声', 'id': 'rain'},
    {'icon': '\u{1F525}', 'label': '篝火', 'id': 'campfire'},
    {'icon': '\u{1F30A}', 'label': '海浪', 'id': 'ocean'},
    {'icon': '\u{1F332}', 'label': '森林鸟鸣', 'id': 'forest'},
    {'icon': '\u{1F390}', 'label': '风铃', 'id': 'chime'},
    {'icon': '\u{1F493}', 'label': '心跳', 'id': 'heartbeat'},
  ];

  static const _serverBase = 'http://114.55.138.55:8888/audio';

  @override
  void initState() {
    super.initState();
    _player.setReleaseMode(ReleaseMode.loop);
    _player.setVolume(_volume);
    _player.onPlayerComplete.listen((_) {
      // Loop mode handles this
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<String> _localPath(String id) async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/noise_$id.wav';
  }

  Future<void> _downloadIfNeeded(String id) async {
    final local = await _localPath(id);
    if (File(local).existsSync()) return;

    try {
      final res = await http.get(Uri.parse('$_serverBase/$id.wav'));
      if (res.statusCode == 200) {
        await File(local).writeAsBytes(res.bodyBytes);
      }
    } catch (_) {}
  }

  Future<void> _toggle(int index) async {
    HapticFeedback.lightImpact();

    if (_playingIndex == index) {
      await _player.stop();
      setState(() => _playingIndex = null);
      return;
    }

    setState(() => _loadingAudio = true);
    final id = _sounds[index]['id']!;

    try {
      await _downloadIfNeeded(id);
      final local = await _localPath(id);

      if (File(local).existsSync()) {
        await _player.play(DeviceFileSource(local));
        await _player.setVolume(_volume);
        setState(() => _playingIndex = index);
      } else {
        // Try playing directly from server
        await _player.play(UrlSource('$_serverBase/$id.wav'));
        await _player.setVolume(_volume);
        setState(() => _playingIndex = index);
      }
    } catch (_) {
      // Audio files not yet available on server
    } finally {
      if (mounted) setState(() => _loadingAudio = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    final isPlaying = _playingIndex != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_loadingAudio)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: LinearProgressIndicator(color: Color(0xFFC4A46C)),
          ),
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
                  onChanged: (v) {
                    setState(() => _volume = v);
                    _player.setVolume(v);
                  },
                ),
              ),
              const Icon(Icons.volume_up,
                  size: 20, color: Color(0xFFC4A46C)),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.stop,
                    size: 20,
                    color: Color(0xFFD4837A)),
                onPressed: () async {
                  await _player.stop();
                  setState(() => _playingIndex = null);
                },
              ),
            ]),
          ),
        ],
      ],
    );
  }
}
