import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/core/theme/theme_mode_provider.dart';
import 'package:chrysotile_app/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ChrysotileApp()));
}

class ChrysotileApp extends ConsumerWidget {
  const ChrysotileApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Chrysotile',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const MainShell(),
    );
  }
}
