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

class BookmarksNotifier extends StateNotifier<AsyncValue<List<PostCard>>> {
  BookmarksNotifier(this._store) : super(const AsyncValue.loading()) {
    _load();
  }

  final BookmarksStore _store;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_store.load);
  }

  Future<void> toggle(PostCard post) async {
    final current = List<PostCard>.of(state.value ?? const []);
    final index = current.indexWhere((item) => item.id == post.id);
    if (index >= 0) {
      current.removeAt(index);
    } else {
      current.insert(0, post);
    }
    state = AsyncValue.data(current);
    await _store.save(current);
  }

  bool contains(int id) {
    return state.value?.any((post) => post.id == id) ?? false;
  }
}

final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, AsyncValue<List<PostCard>>>((ref) {
  return BookmarksNotifier(ref.watch(bookmarksStoreProvider));
});

final isBookmarkedProvider = Provider.family<bool, int>((ref, id) {
  final bookmarks = ref.watch(bookmarksProvider);
  return bookmarks.value?.any((post) => post.id == id) ?? false;
});
