import 'package:chrysotile_app/core/notifications/push_service.dart';
import 'package:chrysotile_app/firebase_options.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const notificationTopicOptions = <MapEntry<String, String>>[
  MapEntry('cat_glavnye', 'Главное'),
  MapEntry('cat_gosudarstvo', 'В стране'),
  MapEntry('cat_region', 'В регионе'),
  MapEntry('cat_people', 'Люди'),
  MapEntry('cat_society', 'Общество'),
  MapEntry('cat_special_projects', 'Спецпроекты'),
];

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pushReady = ref.watch(pushReadyProvider);
    final topics = ref.watch(pushTopicsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Выберите рубрики, по которым хотите получать push-уведомления.',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.darkTextSoft : AppColors.gray,
            ),
          ),
          const SizedBox(height: 16),
          if (!DefaultFirebaseOptions.isConfigured)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Firebase ещё не подключён. После настройки push появятся здесь.',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSoft : AppColors.gray,
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
            const SizedBox(height: 16),
            topics.when(
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
              data: (selected) => Column(
                children: notificationTopicOptions.map((entry) {
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
        ],
      ),
    );
  }
}
