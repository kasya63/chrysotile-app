import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/features/feed/article_screen.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/features/categories/category_feed_screen.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(homeFeedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chrysotile'),
      ),
      body: feed.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(homeFeedProvider),
        ),
        data: (home) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(homeFeedProvider);
            await ref.read(homeFeedProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              if (home.hero.isNotEmpty) ...[
                Text(
                  'Главное сегодня',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                LeadPostCard(
                  post: home.hero.first,
                  onTap: () => openArticle(context, home.hero.first.id),
                ),
                if (home.hero.length > 1) ...[
                  const SizedBox(height: 8),
                  ...home.hero.skip(1).map(
                        (post) => CompactPostTile(
                          post: post,
                          onTap: () => openArticle(context, post.id),
                        ),
                      ),
                ],
                const SizedBox(height: 20),
              ],
              ...home.sections.map(
                (section) => _FeedSectionBlock(
                  section: section,
                  onOpenPost: (id) => openArticle(context, id),
                  onOpenAll: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => CategoryFeedScreen(
                          slug: section.slug,
                          title: section.label,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedSectionBlock extends StatelessWidget {
  const _FeedSectionBlock({
    required this.section,
    required this.onOpenPost,
    required this.onOpenAll,
  });

  final FeedSection section;
  final ValueChanged<int> onOpenPost;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    if (section.posts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  section.label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              TextButton(
                onPressed: onOpenAll,
                child: const Text('Смотреть все'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LeadPostCard(
            post: section.posts.first,
            onTap: () => onOpenPost(section.posts.first.id),
          ),
          ...section.posts.skip(1).map(
                (post) => CompactPostTile(
                  post: post,
                  onTap: () => onOpenPost(post.id),
                ),
              ),
        ],
      ),
    );
  }
}
