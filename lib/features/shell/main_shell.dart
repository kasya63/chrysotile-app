import 'package:chrysotile_app/features/bookmarks/bookmarks_screen.dart';
import 'package:chrysotile_app/features/feed/home_screen.dart';
import 'package:chrysotile_app/features/profile/profile_screen.dart';
import 'package:chrysotile_app/shared/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  static const _tabs = [
    HomeScreen(),
    BookmarksScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration =
        disableAnimations ? Duration.zero : const Duration(milliseconds: 240);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            IgnorePointer(
              ignoring: i != _index,
              child: AnimatedOpacity(
                opacity: i == _index ? 1 : 0,
                duration: duration,
                curve: Curves.easeOutCubic,
                child: TickerMode(
                  enabled: i == _index,
                  child: _tabs[i],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _index,
        onSelected: (value) {
          if (value == _index) {
            return;
          }
          setState(() => _index = value);
        },
      ),
    );
  }
}
