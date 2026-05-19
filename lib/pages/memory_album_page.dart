import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../widgets/ink_writing_loader.dart';

class MemoryAlbumPage extends StatefulWidget {
  const MemoryAlbumPage({super.key});
  @override
  State<MemoryAlbumPage> createState() => _MemoryAlbumPageState();
}

class _MemoryAlbumPageState extends State<MemoryAlbumPage> {
  List<String> _photos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    // Scan app documents directory for photos
    try {
      final dir = Directory('/data/user/0/com.xinqingriji/app_flutter/photos');
      if (await dir.exists()) {
        final files = dir.listSync().whereType<File>().where((f) =>
            f.path.endsWith('.jpg') || f.path.endsWith('.png')).toList();
        files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
        if (mounted) {
          setState(() {
            _photos = files.map((f) => f.path).toList();
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();

    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: theme.accentColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('记忆相册',
            style: TextStyle(color: theme.textPrimary, fontSize: 18)),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
                child: InkWritingLoader(inkColor: theme.gold, size: 40))
            : _photos.isEmpty
                ? Center(
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                        const Text('📷', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('还没有照片记录',
                            style: TextStyle(
                                color: theme.textSecondary, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text('记录心情时上传照片，就会在这里看到',
                            style: TextStyle(
                                color: theme.textSecondary.withAlpha(150),
                                fontSize: 12)),
                      ]))
                : RefreshIndicator(
                    onRefresh: _loadPhotos,
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 6),
                      itemCount: _photos.length,
                      itemBuilder: (_, i) {
                        return GestureDetector(
                          onTap: () => _showPhoto(context, theme, _photos[i]),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_photos[i]),
                                fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  void _showPhoto(BuildContext context, ThemeState theme, String path) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => Scaffold(
                  backgroundColor: Colors.black,
                  appBar: AppBar(
                      backgroundColor: Colors.black,
                      elevation: 0,
                      leading: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context))),
                  body: Center(
                      child: InteractiveViewer(
                          child: Image.file(File(path)))),
                )));
  }
}
