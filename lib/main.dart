import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'stores/app_state.dart';
import 'stores/theme_state.dart';
import 'pages/login_page.dart';
import 'widgets/main_scaffold.dart';
import 'constants/keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const XinQingRiJiApp());
}

class XinQingRiJiApp extends StatelessWidget {
  const XinQingRiJiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
        ChangeNotifierProvider(create: (_) => ThemeState()),
      ],
      child: Consumer<ThemeState>(
        builder: (context, theme, _) {
          return MaterialApp(
            title: '心晴日记',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFFAF8F4),
              colorScheme: const ColorScheme.light(
                primary: Color(0xFFC4A46C),
                secondary: Color(0xFF6E6480),
                surface: Colors.white,
              ),
              fontFamily: 'Roboto',
              inputDecorationTheme: InputDecorationTheme(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC4A46C),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A0A),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFFA08050),
                secondary: Color(0xFF6E6480),
                surface: Color(0xFF1A1A1A),
              ),
            ),
            themeMode: theme.isDark ? ThemeMode.dark : ThemeMode.light,
            home: const SplashGate(),
          );
        },
      ),
    );
  }
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.token) ?? '';
    final dn = prefs.getString(StorageKeys.displayName) ?? '';
    if (mounted) context.read<AppState>().setDisplayName(dn);
    final w = MediaQuery.of(context).size.width;
    if (mounted) context.read<AppState>().setWindowWidth(w.toInt());
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    if (token.isNotEmpty) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MainScaffold()));
    } else {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AnimatedLogo(),
            const SizedBox(height: 24),
            Text('心晴日记',
                style: TextStyle(
                    color: const Color(0xFFC4A46C).withAlpha(200),
                    fontSize: 28,
                    letterSpacing: 4)),
          ],
        ),
      ),
    );
  }
}

class _AnimatedLogo extends StatefulWidget {
  @override
  State<_AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<_AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(80, 80),
        painter: _LogoPainter(_anim.value),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final double progress;
  _LogoPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2, cy = size.height / 2, r = size.width * 0.4;
    final paint = Paint()
      ..color = const Color(0xFFC4A46C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * 3.14159 * progress;
    canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r * progress),
        -3.14159 / 2,
        sweepAngle,
        false,
        paint);

    if (progress > 0.5) {
      final rayProgress = (progress - 0.5) * 2;
      for (int i = 0; i < 8; i++) {
        final angle = (i / 8) * 2 * 3.14159;
        final len = r * 0.35 * rayProgress;
        final dx = cx + cos(angle) * (r + 2);
        final dy = cy + sin(angle) * (r + 2);
        canvas.drawLine(
            Offset(dx, dy),
            Offset(dx + cos(angle) * len, dy + sin(angle) * len),
            paint..color = paint.color.withAlpha((180 * rayProgress).round()));
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.progress != progress;
}
