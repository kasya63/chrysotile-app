import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Figma-style sun/moon theme toggle (light ↔ dark).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isDark),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 66,
        height: 33,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(52),
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFA8EB6), Color(0xFFFFE078)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 220),
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFFE8EAF6) : const Color(0xFFFFEB3B),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
              size: 16,
              color: isDark ? AppColors.blueDark : const Color(0xFFF57C00),
            ),
          ),
        ),
      ),
    );
  }
}
