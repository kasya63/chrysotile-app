import 'package:chrysotile_app/core/models/post_models.dart';
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
  PaginatedPosts? _feed;
  Object? _error;
  bool _loading = true;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    _load(page: 1);
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: feed.items.length + (feed.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= feed.items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: _loadingMore
                    ? const CircularProgressIndicator()
                    : TextButton(
                        onPressed: () => _load(page: feed.page + 1),
                        child: const Text('Показать ещё'),
                      ),
              ),
            );
          }

          final post = feed.items[index];
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: LeadPostCard(
                post: post,
                onTap: () => openArticle(context, post.id),
              ),
            );
          }

          return CompactPostTile(
            post: post,
            onTap: () => openArticle(context, post.id),
          );
        },
      ),
    );
  }
}
