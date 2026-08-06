import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/brand_header.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:chrysotile_app/shared/widgets/stub_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _stubFolders = [
  ('Город', 5),
  ('Экономика', 3),
  ('Культура', 2),
  ('Спорт', 2),
];

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BrandHeader(),
            const Divider(height: 0.5, thickness: 0.5, color: Color(0xFF9C9C9C)),
            Expanded(
              child: bookmarks.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(bookmarksProvider),
                ),
                data: (items) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Мои заметки',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppColors.darkText
                                    : Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            width: 70,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkBorder
                                    : Colors.black.withValues(alpha: 0.3),
                                width: 0.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  '${items.length}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF325996),
                                  ),
                                ),
                                Text(
                                  'Заметок',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.darkTextSoft
                                        : Colors.black
                                            .withValues(alpha: 0.65),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _SectionHeader(
                        title: 'Недавние заметки',
                        onAll: () => _openStub(context, 'Все заметки'),
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Пока нет заметок. Сохраняйте новости закладкой на карточке.',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.darkTextSoft
                                  : AppColors.gray,
                            ),
                          ),
                        )
                      else
                        ...items.take(3).map(
                              (post) => Dismissible(
                                key: ValueKey('bookmark_${post.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.error,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                onDismissed: (_) {
                                  ref
                                      .read(bookmarksProvider.notifier)
                                      .toggle(post);
                                },
                                child: NewsListCard(
                                  post: post,
                                  forceBookmarkedStyle: true,
                                  bookmarked: true,
                                  onTap: () => openArticle(context, post.id),
                                  onBookmarkTap: () {
                                    ref
                                        .read(bookmarksProvider.notifier)
                                        .toggle(post);
                                  },
                                ),
                              ),
                            ),
                      const SizedBox(height: 16),
                      _SectionHeader(
                        title: 'Папки',
                        onAll: () => _openStub(context, 'Все папки'),
                      ),
                      const SizedBox(height: 12),
                      ..._stubFolders.map(
                        (folder) => _FolderRow(
                          title: folder.$1,
                          count: folder.$2,
                          onTap: () => _openStub(
                            context,
                            folder.$1,
                            message:
                                'Папки скоро появятся. Пока используйте заметки.',
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openStub(
    BuildContext context,
    String title, {
    String message = 'Раздел скоро появится.',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StubPageScreen(title: title, message: message),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.onAll,
  });

  final String title;
  final VoidCallback onAll;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: isDark ? AppColors.darkText : Colors.black,
            ),
          ),
        ),
        GestureDetector(
          onTap: onAll,
          child: Text(
            'Все',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? AppColors.blueSoft : AppColors.blue,
            ),
          ),
        ),
      ],
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.title,
    required this.count,
    required this.onTap,
  });

  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 57,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorder
                    : Colors.black.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 32,
                  color: isDark ? AppColors.blueSoft : AppColors.blue,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkText : Colors.black,
                        ),
                      ),
                      Text(
                        '$count заметок',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.darkTextSoft
                              : Colors.black.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDark ? AppColors.darkTextSoft : Colors.black45,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
