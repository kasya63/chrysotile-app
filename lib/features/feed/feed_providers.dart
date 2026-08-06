import 'package:chrysotile_app/core/models/auth_models.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/storage/bookmarks_store.dart';
import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:chrysotile_app/features/auth/auth_providers.dart'
    show apiProvider;

final homeFeedProvider = FutureProvider<HomeFeed>((ref) async {
  final api = ref.watch(apiProvider);
  return api.fetchHome();
});

final postProvider = FutureProvider.family<PostCard, int>((ref, id) async {
  final api = ref.watch(apiProvider);
  return api.fetchPost(id);
});

final categoriesProvider = FutureProvider<List<CategoryInfo>>((ref) async {
  final api = ref.watch(apiProvider);
  return api.fetchCategories();
});

final commentsProvider =
    FutureProvider.family<List<ArticleComment>, int>((ref, postId) async {
  final api = ref.watch(apiProvider);
  return api.fetchComments(postId);
});

/// Selected category slug on home; null = all latest news.
final homeCategoryFilterProvider = StateProvider<String?>((ref) => null);

class HomeLatestFeedState {
  const HomeLatestFeedState({
    this.items = const [],
    this.page = 0,
    this.total = 0,
    this.loading = false,
    this.loadingMore = false,
    this.error,
    this.category,
  });

  final List<PostCard> items;
  final int page;
  final int total;
  final bool loading;
  final bool loadingMore;
  final Object? error;
  final String? category;

  bool get hasMore => items.length < total;

  HomeLatestFeedState copyWith({
    List<PostCard>? items,
    int? page,
    int? total,
    bool? loading,
    bool? loadingMore,
    Object? error,
    bool clearError = false,
    String? category,
    bool clearCategory = false,
  }) {
    return HomeLatestFeedState(
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class HomeLatestFeedNotifier extends StateNotifier<HomeLatestFeedState> {
  HomeLatestFeedNotifier(this._ref) : super(const HomeLatestFeedState()) {
    refresh();
  }

  final Ref _ref;

  Future<void> refresh() async {
    final category = _ref.read(homeCategoryFilterProvider);
    state = HomeLatestFeedState(loading: true, category: category);
    try {
      final api = _ref.read(apiProvider);
      final page = await api.fetchFeed(category: category, page: 1);
      if (!mounted) return;
      state = HomeLatestFeedState(
        items: page.items,
        page: page.page,
        total: page.total,
        category: category,
      );
    } catch (error) {
      if (!mounted) return;
      state = HomeLatestFeedState(error: error, category: category);
    }
  }

  Future<void> loadMore() async {
    if (state.loading || state.loadingMore || !state.hasMore) {
      return;
    }
    state = state.copyWith(loadingMore: true, clearError: true);
    try {
      final api = _ref.read(apiProvider);
      final next = await api.fetchFeed(
        category: state.category,
        page: state.page + 1,
      );
      if (!mounted) return;
      state = state.copyWith(
        items: [...state.items, ...next.items],
        page: next.page,
        total: next.total,
        loadingMore: false,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(loadingMore: false, error: error);
    }
  }
}

final homeLatestFeedProvider =
    StateNotifierProvider<HomeLatestFeedNotifier, HomeLatestFeedState>((ref) {
  final notifier = HomeLatestFeedNotifier(ref);
  ref.listen<String?>(homeCategoryFilterProvider, (previous, next) {
    if (previous != next) {
      notifier.refresh();
    }
  });
  return notifier;
});

final bookmarksStoreProvider = Provider<BookmarksStore>((ref) {
  return BookmarksStore();
});

class BookmarksNotifier extends StateNotifier<AsyncValue<BookmarksData>> {
  BookmarksNotifier(this._store) : super(const AsyncValue.loading()) {
    _load();
  }

  final BookmarksStore _store;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_store.load);
  }

  Future<void> _persist(BookmarksData data) async {
    state = AsyncValue.data(data);
    await _store.save(data);
  }

  Future<void> toggle(PostCard post, {String? folderId}) async {
    final current = state.value ?? const BookmarksData();
    final items = List<BookmarkItem>.of(current.items);
    final index = items.indexWhere((item) => item.post.id == post.id);
    if (index >= 0) {
      items.removeAt(index);
    } else {
      items.insert(
        0,
        BookmarkItem(
          post: post,
          folderId: folderId,
          savedAt: DateTime.now().toIso8601String(),
        ),
      );
    }
    await _persist(current.copyWith(items: items));
  }

  Future<void> moveToFolder(int postId, String? folderId) async {
    final current = state.value ?? const BookmarksData();
    final items = current.items
        .map(
          (item) => item.post.id == postId
              ? item.copyWith(
                  folderId: folderId,
                  clearFolder: folderId == null,
                )
              : item,
        )
        .toList();
    await _persist(current.copyWith(items: items));
  }

  Future<void> createFolder(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final current = state.value ?? const BookmarksData();
    final folder = BookmarkFolder(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: trimmed,
    );
    await _persist(
      current.copyWith(folders: [...current.folders, folder]),
    );
  }

  Future<void> renameFolder(String id, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final current = state.value ?? const BookmarksData();
    final folders = current.folders
        .map((folder) => folder.id == id ? folder.copyWith(name: trimmed) : folder)
        .toList();
    await _persist(current.copyWith(folders: folders));
  }

  Future<void> deleteFolder(String id) async {
    final current = state.value ?? const BookmarksData();
    final folders =
        current.folders.where((folder) => folder.id != id).toList();
    final items = current.items
        .map(
          (item) => item.folderId == id
              ? item.copyWith(clearFolder: true)
              : item,
        )
        .toList();
    await _persist(current.copyWith(folders: folders, items: items));
  }

  bool contains(int id) {
    return state.value?.items.any((item) => item.post.id == id) ?? false;
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<BookmarksData>>((ref) {
  return BookmarksNotifier(ref.watch(bookmarksStoreProvider));
});

final isBookmarkedProvider = Provider.family<bool, int>((ref, id) {
  final bookmarks = ref.watch(bookmarksProvider);
  return bookmarks.value?.items.any((item) => item.post.id == id) ?? false;
});
