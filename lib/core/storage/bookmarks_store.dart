import 'dart:convert';

import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarkFolder {
  const BookmarkFolder({
    required this.id,
    required this.name,
  });

  factory BookmarkFolder.fromJson(Map<String, dynamic> json) {
    return BookmarkFolder(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final String id;
  final String name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };

  BookmarkFolder copyWith({String? name}) {
    return BookmarkFolder(id: id, name: name ?? this.name);
  }
}

class BookmarkItem {
  const BookmarkItem({
    required this.post,
    this.folderId,
    required this.savedAt,
  });

  factory BookmarkItem.fromJson(Map<String, dynamic> json) {
    return BookmarkItem(
      post: PostCard.fromJson(json['post'] as Map<String, dynamic>? ?? {}),
      folderId: json['folderId'] as String?,
      savedAt: json['savedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  final PostCard post;
  final String? folderId;
  final String savedAt;

  Map<String, dynamic> toJson() => {
        'post': post.toJson(),
        'folderId': folderId,
        'savedAt': savedAt,
      };

  BookmarkItem copyWith({String? folderId, bool clearFolder = false}) {
    return BookmarkItem(
      post: post,
      folderId: clearFolder ? null : (folderId ?? this.folderId),
      savedAt: savedAt,
    );
  }
}

class BookmarksData {
  const BookmarksData({
    this.folders = const [],
    this.items = const [],
  });

  final List<BookmarkFolder> folders;
  final List<BookmarkItem> items;

  List<PostCard> get posts => items.map((item) => item.post).toList();

  BookmarksData copyWith({
    List<BookmarkFolder>? folders,
    List<BookmarkItem>? items,
  }) {
    return BookmarksData(
      folders: folders ?? this.folders,
      items: items ?? this.items,
    );
  }
}

const readLaterFolderId = 'read_later';
const readLaterFolderName = 'Читать позже';

/// Makes sure the built-in "Читать позже" folder always exists (first in list).
BookmarksData withDefaultFolders(BookmarksData data) {
  if (data.folders.any((folder) => folder.id == readLaterFolderId)) {
    return data;
  }
  return data.copyWith(
    folders: [
      const BookmarkFolder(id: readLaterFolderId, name: readLaterFolderName),
      ...data.folders,
    ],
  );
}

class BookmarksStore {
  static const _legacyKey = 'chrysotile_bookmarks_v1';
  static const _key = 'chrysotile_bookmarks_v2';

  Future<BookmarksData> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final folders = (decoded['folders'] as List<dynamic>? ?? [])
          .map((item) => BookmarkFolder.fromJson(item as Map<String, dynamic>))
          .toList();
      final items = (decoded['items'] as List<dynamic>? ?? [])
          .map((item) => BookmarkItem.fromJson(item as Map<String, dynamic>))
          .toList();
      return withDefaultFolders(BookmarksData(folders: folders, items: items));
    }

    final legacy = prefs.getString(_legacyKey);
    if (legacy == null || legacy.isEmpty) {
      return withDefaultFolders(const BookmarksData());
    }

    final decoded = jsonDecode(legacy) as List<dynamic>;
    final now = DateTime.now().toIso8601String();
    final items = decoded
        .map(
          (item) => BookmarkItem(
            post: PostCard.fromJson(item as Map<String, dynamic>),
            savedAt: now,
          ),
        )
        .toList();
    final data = withDefaultFolders(BookmarksData(items: items));
    await save(data);
    await prefs.remove(_legacyKey);
    return data;
  }

  Future<void> save(BookmarksData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'folders': data.folders.map((folder) => folder.toJson()).toList(),
        'items': data.items.map((item) => item.toJson()).toList(),
      }),
    );
  }
}
