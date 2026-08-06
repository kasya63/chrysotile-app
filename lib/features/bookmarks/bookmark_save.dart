import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/storage/bookmarks_store.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Saves a post to notes (with optional folder) or removes it if already saved.
Future<void> handleBookmarkTap({
  required BuildContext context,
  required WidgetRef ref,
  required PostCard post,
}) async {
  final bookmarked = ref.read(isBookmarkedProvider(post.id));
  if (bookmarked) {
    await ref.read(bookmarksProvider.notifier).toggle(post);
    return;
  }

  final folders =
      ref.read(bookmarksProvider).valueOrNull?.folders ?? const <BookmarkFolder>[];

  final folderId = await showModalBottomSheet<String?>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text(
                'Сохранить в заметки',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_add_outlined),
              title: const Text('В заметки'),
              subtitle: const Text('Без папки'),
              onTap: () => Navigator.pop(context, ''),
            ),
            if (folders.isNotEmpty) const Divider(height: 1),
            ...folders.map(
              (folder) => ListTile(
                leading: const Icon(Icons.folder_outlined),
                title: Text(folder.name),
                onTap: () => Navigator.pop(context, folder.id),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );

  if (folderId == null || !context.mounted) {
    return;
  }

  await ref.read(bookmarksProvider.notifier).toggle(
        post,
        folderId: folderId.isEmpty ? null : folderId,
      );
}
