import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class StubPageScreen extends StatelessWidget {
  const StubPageScreen({
    super.key,
    required this.title,
    this.message = 'Раздел скоро появится.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 48,
                color: isDark ? AppColors.darkTextSoft : AppColors.gray,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSoft
                          : AppColors.gray,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
