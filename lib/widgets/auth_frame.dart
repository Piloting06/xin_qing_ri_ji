import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../stores/theme_state.dart';
import '../theme/xq_decorations.dart';
import '../theme/xq_typography.dart';

class XqAuthBackdrop extends StatelessWidget {
  final ThemeState theme;

  const XqAuthBackdrop({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -70,
          child: _XqAuthGlow(
            size: 220,
            color: theme.accentColor.withAlpha(theme.isDark ? 42 : 30),
          ),
        ),
        Positioned(
          left: -80,
          bottom: 80,
          child: _XqAuthGlow(
            size: 180,
            color: theme.gold.withAlpha(theme.isDark ? 30 : 24),
          ),
        ),
      ],
    );
  }
}

class _XqAuthGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _XqAuthGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class XqAuthHero extends StatelessWidget {
  final ThemeState theme;
  final String title;
  final IconData icon;
  final double size;

  const XqAuthHero({
    super.key,
    required this.theme,
    required this.title,
    this.icon = Icons.auto_stories_outlined,
    this.size = 68,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: theme.cardColor.withAlpha(220),
            borderRadius: BorderRadius.circular(size >= 68 ? 24 : 20),
            border: Border.all(color: theme.borderColor),
            boxShadow: XqDecorations.shadowMedium(dark: theme.isDark),
          ),
          child: Icon(icon, color: theme.gold, size: size * 0.45),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: XqTypography.headlineLarge.copyWith(
            color: theme.textPrimary,
            letterSpacing: title.length <= 4 ? 2 : 0,
          ),
        ),
      ],
    );
  }
}

class XqAuthCard extends StatelessWidget {
  final ThemeState theme;
  final Widget child;

  const XqAuthCard({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: XqDecorations.heroCard(
        theme.cardColor.withAlpha(theme.isDark ? 238 : 245),
        theme.cardColor.withAlpha(theme.isDark ? 230 : 250),
        theme.borderColor,
        dark: theme.isDark,
        glow: theme.accentColor,
      ),
      child: child,
    );
  }
}

class XqAuthInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final void Function(String)? onSubmitted;
  final String? error;

  const XqAuthInput({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.suffix,
    this.onSubmitted,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: keyboardType == TextInputType.phone ? 11 : null,
          onSubmitted: onSubmitted,
          style: TextStyle(color: theme.textPrimary, fontSize: 15),
          cursorColor: theme.accentColor,
          decoration: InputDecoration(
            counterText: '',
            prefixIcon: Icon(icon, color: theme.accentColor, size: 20),
            suffixIcon: suffix,
            hintText: hint,
            errorText: error,
          ),
        ),
      ],
    );
  }
}

class XqAuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final bool active;
  final VoidCallback onTap;

  const XqAuthButton({
    super.key,
    required this.label,
    required this.loading,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeState>();
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: active && !loading ? onTap : null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.accentColor,
          foregroundColor: theme.textOnAccent,
          disabledBackgroundColor: theme.borderColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.textOnAccent,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
