import 'package:chrysotile_app/core/api/chrysotile_api.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/storage/bookmarks_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiProvider = Provider<ChrysotileApi>((ref) => ChrysotileApi());

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
