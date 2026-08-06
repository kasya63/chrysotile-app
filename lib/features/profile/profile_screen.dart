import 'package:cached_network_image/cached_network_image.dart';
import 'package:chrysotile_app/core/config/app_config.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/core/theme/theme_mode_provider.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:chrysotile_app/features/auth/login_screen.dart';
import 'package:chrysotile_app/features/profile/edit_profile_screen.dart';
import 'package:chrysotile_app/features/profile/feedback_screen.dart';
import 'package:chrysotile_app/features/profile/notifications_screen.dart';
import 'package:chrysotile_app/shared/widgets/brand_header.dart';
import 'package:chrysotile_app/shared/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

const _socialLinks = [
  (
    asset: 'assets/social/telegram.svg',
    url: 'https://t.me/gazetakm',
    label: 'Telegram',
  ),
  (
    asset: 'assets/social/instagram.svg',
    url: 'https://www.instagram.com/gazetakm/',
    label: 'Instagram',
  ),
  (
    asset: 'assets/social/youtube.svg',
    url: 'https://www.youtube.com/channel/UCAkrsp_48W7tEdthJgzu9aA',
    label: 'YouTube',
  ),
  (
    asset: 'assets/social/ok.svg',
    url: 'https://ok.ru/profile/572667802596',
    label: 'OK',
  ),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final effectiveIsDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && isDarkTheme);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.blueSoft,
                        backgroundImage: user?.avatarUrl.isNotEmpty == true
                            ? CachedNetworkImageProvider(user!.avatarUrl)
                            : null,
                        child: user?.avatarUrl.isNotEmpty == true
                            ? null
                            : Icon(
                                Icons.person,
                                size: 48,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.displayName.isNotEmpty == true
                                  ? user!.displayName
                                  : 'Гость',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isDarkTheme
                                    ? AppColors.darkText
                                    : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user == null
                                  ? 'Войдите, чтобы комментировать'
                                  : user.email,
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkTheme
                                    ? AppColors.darkTextSoft
                                    : Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                            if (user == null) ...[
                              const SizedBox(height: 10),
                              FilledButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Войти'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _MenuCard(
                    items: [
                      _MenuItem(
                        label: 'Уведомления',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      _MenuItem(
                        label: 'Обратная связь',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const FeedbackScreen(),
                            ),
                          );
                        },
                      ),
                      if (user != null)
                        _MenuItem(
                          label: 'Редактировать профиль',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const EditProfileScreen(),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Тема',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkTheme
                                ? AppColors.darkText
                                : Colors.black,
                          ),
                        ),
                      ),
                      ThemeToggle(
                        isDark: effectiveIsDark,
                        onChanged: (dark) {
                          ref.read(themeModeProvider.notifier).state =
                              dark ? ThemeMode.dark : ThemeMode.light;
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _socialLinks.map((link) {
                      return IconButton(
                        tooltip: link.label,
                        onPressed: () => launchUrl(
                          Uri.parse(link.url),
                          mode: LaunchMode.externalApplication,
                        ),
                        icon: SvgPicture.asset(
                          link.asset,
                          width: 28,
                          height: 28,
                        ),
                      );
                    }).toList(),
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 24),
                    InkWell(
                      onTap: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout,
                              size: 24,
                              color: isDarkTheme
                                  ? AppColors.darkText
                                  : Colors.black,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Выйти',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDarkTheme
                                    ? AppColors.darkText
                                    : Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Center(
                    child: TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(
                          'https://chrysotile.kz/rulse_use_material/',
                        ),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        'Правила использования материалов',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDarkTheme
                              ? AppColors.blueSoft
                              : AppColors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      AppConfig.siteName,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme
                            ? AppColors.darkTextSoft
                            : AppColors.gray,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.items});

  final List<_MenuItem> items;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : Colors.black.withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 0.5),
      ),
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 0.5, thickness: 0.5, color: borderColor),
            ListTile(
              title: Text(
                items[i].label,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? AppColors.darkText : Colors.black,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: isDark ? AppColors.darkTextSoft : Colors.black45,
              ),
              onTap: items[i].onTap,
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;
}
