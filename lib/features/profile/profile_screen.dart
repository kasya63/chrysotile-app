import 'package:chrysotile_app/core/notifications/push_service.dart';
import 'package:chrysotile_app/core/theme/theme_mode_provider.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:chrysotile_app/features/auth/login_screen.dart';
import 'package:chrysotile_app/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _topicOptions = <MapEntry<String, String>>[
  MapEntry('cat_glavnye', 'Главное'),
  MapEntry('cat_gosudarstvo', 'В стране'),
  MapEntry('cat_region', 'В регионе'),
  MapEntry('cat_people', 'Люди'),
  MapEntry('cat_society', 'Общество'),
  MapEntry('cat_special_projects', 'Спецпроекты'),
];

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final auth = ref.watch(authControllerProvider);
    final user = auth.valueOrNull;
    final pushReady = ref.watch(pushReadyProvider);
    final topics = ref.watch(pushTopicsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName.isNotEmpty == true
                        ? user!.displayName
                        : 'Гость',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user == null
                        ? 'Читайте новости без входа. Для комментариев войдите по email.'
                        : user.email,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 16),
                  if (user == null)
                    FilledButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      },
                      child: const Text('Войти'),
                    )
                  else
                    OutlinedButton(
                      onPressed: () =>
                          ref.read(authControllerProvider.notifier).logout(),
                      child: const Text('Выйти'),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Уведомления',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          if (!DefaultFirebaseOptions.isConfigured)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Firebase ещё не подключён. После настройки push появятся здесь.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            )
          else ...[
            pushReady.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Push недоступен: $error'),
              data: (ready) {
                if (!ready) {
                  return const Text('Не удалось инициализировать уведомления.');
                }
                return FilledButton.tonal(
                  onPressed: () async {
                    final ok = await ref
                        .read(pushServiceProvider)
                        .requestPermissionAndRegister();
                    if (!context.mounted) {
                      return;
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Уведомления включены'
                              : 'Разрешение не выдано',
                        ),
                      ),
                    );
                  },
                  child: const Text('Включить уведомления'),
                );
              },
            ),
            const SizedBox(height: 8),
            topics.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (selected) => Column(
                children: _topicOptions.map((entry) {
                  return SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(entry.value),
                    value: selected.contains(entry.key),
                    onChanged: (value) {
                      ref
                          .read(pushTopicsProvider.notifier)
                          .toggle(entry.key, value);
                    },
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Тема',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          _ThemeOption(
            label: 'Как в системе',
            selected: themeMode == ThemeMode.system,
            onTap: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.system,
          ),
          _ThemeOption(
            label: 'Светлая',
            selected: themeMode == ThemeMode.light,
            onTap: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.light,
          ),
          _ThemeOption(
            label: 'Тёмная',
            selected: themeMode == ThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).state = ThemeMode.dark,
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
