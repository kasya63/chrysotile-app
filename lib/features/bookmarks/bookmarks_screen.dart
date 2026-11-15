import 'package:chrysotile_app/core/storage/bookmarks_store.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: bookmarks.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(bookmarksProvider),
                ),
                data: (data) => ListView(
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
                              color:
                                  isDark ? AppColors.darkText : Colors.black,
                            ),
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 70),
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
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
                                '${data.items.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF325996),
                                ),
                              ),
                              Text(
                                'Заметок',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppColors.darkTextSoft
                                      : Colors.black.withValues(alpha: 0.65),
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
                      onAll: () => _openAllNotes(context, data.items),
                    ),
                    const SizedBox(height: 12),
                    if (data.items.isEmpty)
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
                      ...data.items.take(3).map(
                            (item) => _BookmarkCard(
                              item: item,
                              folders: data.folders,
                            ),
                          ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Папки',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.darkText
                                  : Colors.black,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _showCreateFolderDialog(context, ref),
                          icon: const Icon(Icons.create_new_folder_outlined,
                              size: 18),
                          label: const Text('Новая'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.blue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (data.folders.isEmpty)
                      Text(
                        'Создайте папку и раскладывайте заметки как удобно.',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.darkTextSoft
                              : AppColors.gray,
                        ),
                      )
                    else
                      ...data.folders.map((folder) {
                        final count = data.items
                            .where((item) => item.folderId == folder.id)
                            .length;
                        return _FolderRow(
                          title: folder.name,
                          count: count,
                          onTap: () => _openFolder(context, folder, data),
                          icon: folder.id == readLaterFolderId
                              ? Icons.schedule
                              : Icons.folder,
                          onLongPress: folder.id == readLaterFolderId
                              ? null
                              : () => _showFolderActions(context, ref, folder),
                        );
                      }),
                  ],
                ),
        ),
      ),
    );
  }

  void _openAllNotes(BuildContext context, List<BookmarkItem> items) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotesListScreen(
          title: 'Все заметки',
          items: items,
        ),
      ),
    );
  }

  void _openFolder(
    BuildContext context,
    BookmarkFolder folder,
    BookmarksData data,
  ) {
    final items =
        data.items.where((item) => item.folderId == folder.id).toList();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => NotesListScreen(
          title: folder.name,
          items: items,
          folderId: folder.id,
        ),
      ),
    );
  }

  Future<void> _showCreateFolderDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая папка'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Название папки'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Создать'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(bookmarksProvider.notifier).createFolder(name);
    }
  }

  Future<void> _showFolderActions(
    BuildContext context,
    WidgetRef ref,
    BookmarkFolder folder,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Переименовать'),
              onTap: () => Navigator.pop(context, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Удалить'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) {
      return;
    }
    if (action == 'delete') {
      await ref.read(bookmarksProvider.notifier).deleteFolder(folder.id);
      return;
    }
    final controller = TextEditingController(text: folder.name);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Переименовать папку'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      await ref.read(bookmarksProvider.notifier).renameFolder(folder.id, name);
    }
  }
}

class _BookmarkCard extends ConsumerWidget {
  const _BookmarkCard({
    required this.item,
    required this.folders,
  });

  final BookmarkItem item;
  final List<BookmarkFolder> folders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey('bookmark_${item.post.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        ref.read(bookmarksProvider.notifier).toggle(item.post);
      },
      child: NewsListCard(
        post: item.post,
        forceBookmarkedStyle: true,
        bookmarked: true,
        onTap: () => openArticle(context, item.post.id),
        onBookmarkTap: () {
          _showMoveSheet(context, ref);
        },
      ),
    );
  }

  Future<void> _showMoveSheet(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(title: Text('Действия с заметкой')),
            ListTile(
              leading: const Icon(Icons.bookmark_remove_outlined),
              title: const Text('Убрать из заметок'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_off_outlined),
              title: const Text('Без папки'),
              onTap: () => Navigator.pop(context, 'none'),
            ),
            ...folders.map(
              (folder) => ListTile(
                leading: const Icon(Icons.folder),
                title: Text(folder.name),
                onTap: () => Navigator.pop(context, folder.id),
              ),
            ),
          ],
        ),
      ),
    );
    if (action == null) {
      return;
    }
    if (action == 'remove') {
      await ref.read(bookmarksProvider.notifier).toggle(item.post);
      return;
    }
    await ref.read(bookmarksProvider.notifier).moveToFolder(
          item.post.id,
          action == 'none' ? null : action,
        );
  }
}

class NotesListScreen extends ConsumerWidget {
  const NotesListScreen({
    super.key,
    required this.title,
    required this.items,
    this.folderId,
  });

  final String title;
  final List<BookmarkItem> items;
  final String? folderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(bookmarksProvider).valueOrNull;
    final liveItems = folderId == null
        ? (data?.items ?? items)
        : (data?.items
                .where((item) => item.folderId == folderId)
                .toList() ??
            items);
    final folders = data?.folders ?? const <BookmarkFolder>[];

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: liveItems.isEmpty
          ? const Center(child: Text('В этой папке пока пусто'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: liveItems.length,
              itemBuilder: (context, index) {
                return _BookmarkCard(
                  item: liveItems[index],
                  folders: folders,
                );
              },
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
    required this.onLongPress,
    this.icon = Icons.folder,
  });

  final String title;
  final int count;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData icon;

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
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: const BoxConstraints(minHeight: 57),
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
                  icon,
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
                          fontSize: 15,
                          color: isDark ? AppColors.darkText : Colors.black,
                        ),
                      ),
                      Text(
                        '$count заметок',
                        style: TextStyle(
                          fontSize: 15,
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
