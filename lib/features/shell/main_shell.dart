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
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _tabs,
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _index,
        onSelected: (value) => setState(() => _index = value),
      ),
    );
  }
}
