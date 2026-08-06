import 'package:cached_network_image/cached_network_image.dart';
import 'package:chrysotile_app/core/config/app_config.dart';
import 'package:chrysotile_app/core/storage/text_scale_store.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/core/theme/text_scale_provider.dart';
import 'package:chrysotile_app/core/theme/theme_mode_provider.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:chrysotile_app/features/auth/login_screen.dart';
import 'package:chrysotile_app/features/profile/edit_profile_screen.dart';
import 'package:chrysotile_app/features/profile/feedback_screen.dart';
import 'package:chrysotile_app/features/profile/notifications_screen.dart';
import 'package:chrysotile_app/shared/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

const _socialBase =
    'https://chrysotile.kz/wp-content/themes/chrysotile-theme/assets/social';

const _socialLinks = [
  (
    asset: 'assets/social/telegram.svg',
    network: '$_socialBase/telegram.svg',
    url: 'https://t.me/gazetakm',
    label: 'Telegram',
  ),
  (
    asset: 'assets/social/instagram.svg',
    network: '$_socialBase/instagram.svg',
    url: 'https://www.instagram.com/gazetakm/',
    label: 'Instagram',
  ),
  (
    asset: 'assets/social/youtube.svg',
    network: '$_socialBase/youtube.svg',
    url: 'https://www.youtube.com/channel/UCAkrsp_48W7tEdthJgzu9aA',
    label: 'YouTube',
  ),
  (
    asset: 'assets/social/ok.svg',
    network: '$_socialBase/ok.svg',
    url: 'https://ok.ru/profile/572667802596',
    label: 'OK',
  ),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final effectiveIsDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && isDarkTheme);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
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
                    const SizedBox(height: 20),
                    Text(
                      'Размер шрифта',
                      style: TextStyle(
                        fontSize: 16,
                        color:
                            isDarkTheme ? AppColors.darkText : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<double>(
                      segments: const [
                        ButtonSegment<double>(
                          value: TextScaleStore.normal,
                          label: Text('А', style: TextStyle(fontSize: 14)),
                          tooltip: 'Обычный',
                        ),
                        ButtonSegment<double>(
                          value: TextScaleStore.larger,
                          label: Text('А', style: TextStyle(fontSize: 18)),
                          tooltip: 'Крупнее',
                        ),
                        ButtonSegment<double>(
                          value: TextScaleStore.largest,
                          label: Text('А', style: TextStyle(fontSize: 22)),
                          tooltip: 'Ещё крупнее',
                        ),
                      ],
                      selected: {textScale},
                      onSelectionChanged: (value) {
                        ref
                            .read(textScaleProvider.notifier)
                            .setScale(value.first);
                      },
                      showSelectedIcon: false,
                    ),
                    const SizedBox(height: 24),
                    const _SocialRow(links: _socialLinks),
                  ],
                ),
              ),
              if (user != null) ...[
                const SizedBox(height: 8),
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
                          color:
                              isDarkTheme ? AppColors.darkText : Colors.black,
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
              const SizedBox(height: 8),
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
                      color:
                          isDarkTheme ? AppColors.blueSoft : AppColors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({required this.links});

  final List<({String asset, String network, String url, String label})> links;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: links.map((link) {
        return Tooltip(
          message: link.label,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => launchUrl(
              Uri.parse(link.url),
              mode: LaunchMode.externalApplication,
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: SvgPicture.network(
                link.network,
                width: 32,
                height: 32,
                placeholderBuilder: (_) => SvgPicture.asset(
                  link.asset,
                  width: 32,
                  height: 32,
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
