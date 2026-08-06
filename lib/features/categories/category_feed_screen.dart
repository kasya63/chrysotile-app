import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/features/bookmarks/bookmark_save.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryFeedScreen extends ConsumerStatefulWidget {
  const CategoryFeedScreen({
    super.key,
    required this.slug,
    required this.title,
  });

  final String slug;
  final String title;

  @override
  ConsumerState<CategoryFeedScreen> createState() => _CategoryFeedScreenState();
}

class _CategoryFeedScreenState extends ConsumerState<CategoryFeedScreen> {
  final _scrollController = ScrollController();
  PaginatedPosts? _feed;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load(page: 1);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    final feed = _feed;
    if (feed != null &&
        feed.hasMore &&
        !_loadingMore &&
        position.pixels >= position.maxScrollExtent - 320) {
      _load(page: feed.page + 1);
    }
  }

  Future<void> _load({required int page}) async {
    setState(() {
      if (page == 1) {
        _loading = true;
      } else {
        _loadingMore = true;
      }
      _error = null;
    });

    try {
      final pageResult = await ref.read(apiProvider).fetchFeed(
            category: widget.slug,
            page: page,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _feed = page == 1 ? pageResult : (_feed?.merge(pageResult) ?? pageResult);
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _feed == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _feed == null) {
      return ErrorState(
        message: _error.toString(),
        onRetry: () => _load(page: 1),
      );
    }

    final feed = _feed;
    if (feed == null || feed.items.isEmpty) {
      return const Center(child: Text('В этой рубрике пока нет материалов'));
    }

    return RefreshIndicator(
      onRefresh: () => _load(page: 1),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: feed.items.length + (feed.hasMore || _loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= feed.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final post = feed.items[index];
          final bookmarked = ref.watch(isBookmarkedProvider(post.id));
          return NewsListCard(
            post: post,
            bookmarked: bookmarked,
            onTap: () => openArticle(context, post.id),
            onBookmarkTap: () {
              handleBookmarkTap(
                context: context,
                ref: ref,
                post: post,
              );
            },
          );
        },
      ),
    );
  }
}
