import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:chrysotile_app/features/bookmarks/bookmark_save.dart';
import 'package:chrysotile_app/features/feed/comments_section.dart';
import 'package:chrysotile_app/features/feed/feed_providers.dart';
import 'package:chrysotile_app/shared/widgets/error_state.dart';
import 'package:chrysotile_app/shared/widgets/post_cards.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:share_plus/share_plus.dart';

void openArticle(BuildContext context, int id) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArticleScreen(postId: id),
    ),
  );
}

class ArticleScreen extends ConsumerStatefulWidget {
  const ArticleScreen({super.key, required this.postId});

  final int postId;

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.read(apiProvider).trackView(widget.postId);
    });
  }

  Future<void> _share(String title, String permalink) async {
    final text = permalink.isNotEmpty ? '$title\n$permalink' : title;
    await SharePlus.instance.share(ShareParams(text: text, subject: title));
  }

  @override
  Widget build(BuildContext context) {
    final post = ref.watch(postProvider(widget.postId));
    final bookmarked = ref.watch(isBookmarkedProvider(widget.postId));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        actions: [
          post.maybeWhen(
            data: (article) => IconButton(
              tooltip: bookmarked ? 'Убрать из закладок' : 'В закладки',
              onPressed: () {
                handleBookmarkTap(
                  context: context,
                  ref: ref,
                  post: article,
                );
              },
              icon: Icon(
                bookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: bookmarked
                    ? AppColors.bookmarkFilled
                    : (isDark ? AppColors.darkText : Colors.black87),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: post.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(postProvider(widget.postId)),
        ),
        data: (article) {
          final related = article.related.take(3).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 48),
            children: [
              if (article.image.hasUrl)
                PostImageFrame(
                  image: article.image,
                  borderRadius: 15,
                ),
              const SizedBox(height: 16),
              if (article.categories.isNotEmpty) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.blue.withValues(alpha: 0.25)
                          : AppColors.categoryBadge,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      article.categories.first.name,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColors.blueSoft : AppColors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Text(
                article.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
              ),
              if (article.subtitle.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  article.subtitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.darkTextSoft
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                '${article.dateDisplay} · ~${article.readingMin} мин · ${article.views} просмотров',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.darkTextSoft
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 20),
              if ((article.contentHtml ?? '').isNotEmpty)
                HtmlWidget(
                  article.contentHtml!,
                  textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.6,
                      ),
                ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => _share(article.title, article.permalink),
                icon: const Icon(Icons.ios_share, size: 20),
                label: const Text('Поделиться'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 28),
              CommentsSection(postId: article.id),
              if (related.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Читайте также',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ...related.map(
                  (item) {
                    final relatedBookmarked =
                        ref.watch(isBookmarkedProvider(item.id));
                    return NewsListCard(
                      post: item,
                      bookmarked: relatedBookmarked,
                      onTap: () => openArticle(context, item.id),
                      onBookmarkTap: () {
                        handleBookmarkTap(
                          context: context,
                          ref: ref,
                          post: item,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ],
          );
        },
      ),
    );
  }
}
