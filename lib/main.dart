import 'package:chrysotile_app/core/notifications/push_service.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/core/theme/text_scale_provider.dart';
import 'package:chrysotile_app/core/theme/theme_mode_provider.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/shell/main_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ChrysotileApp()));
}

class ChrysotileApp extends ConsumerStatefulWidget {
  const ChrysotileApp({super.key});

  @override
  ConsumerState<ChrysotileApp> createState() => _ChrysotileAppState();
}

class _ChrysotileAppState extends ConsumerState<ChrysotileApp> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final ready = await ref.read(pushReadyProvider.future);
      if (!ready || !mounted) {
        return;
      }

      final push = ref.read(pushServiceProvider);
      push.openPostRequests.listen((postId) {
        final nav = navigatorKey.currentState;
        if (nav == null) {
          return;
        }
        nav.push(
          MaterialPageRoute<void>(
            builder: (_) => ArticleScreen(postId: postId),
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Chrysotile News',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        // Respect iOS "Larger Text" together with the in-app A/A/A choice.
        final system = media.textScaler.scale(1.0);
        final combined = (system * textScale).clamp(1.0, 1.9).toDouble();
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(combined),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const MainShell(),
    );
  }
}
