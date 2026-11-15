import 'package:cached_network_image/cached_network_image.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// Current text scale (system "Larger Text" x in-app A/A/A), used to size
/// fixed-height cards so large fonts never overflow.
double textScaleOf(BuildContext context) {
  return MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.9).toDouble();
}

Widget _networkImage(String url, Color placeholder) {
  return CachedNetworkImage(
    imageUrl: url,
    fit: BoxFit.cover,
    placeholder: (_, _) => Container(color: placeholder),
    errorWidget: (_, _, _) => Container(color: placeholder),
  );
}

class PostImageFrame extends StatelessWidget {
  const PostImageFrame({
    super.key,
    required this.image,
    this.aspectRatio = 16 / 9,
    this.dateLabel,
    this.borderRadius = 12,
  });

  final PostImage image;
  final double aspectRatio;
  final String? dateLabel;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image.hasUrl)
              _networkImage(image.url, placeholder)
            else
              Container(color: placeholder),
            if (dateLabel != null && dateLabel!.isNotEmpty)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    dateLabel!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.post);

  final PostCard post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final category =
        post.categories.isNotEmpty ? post.categories.first.name : 'Новости';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.blue.withValues(alpha: 0.25)
            : AppColors.categoryBadge,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        category,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.blueSoft : AppColors.blue,
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.post);

  final PostCard post;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metaColor = isDark
        ? AppColors.darkTextSoft
        : Colors.black.withValues(alpha: 0.6);
    const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: 14, color: metaColor),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            post.dateDisplay.isNotEmpty ? post.dateDisplay : 'Дата',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style.copyWith(color: metaColor),
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.remove_red_eye_outlined, size: 16, color: metaColor),
        const SizedBox(width: 4),
        Text('${post.views}', style: style.copyWith(color: metaColor)),
      ],
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({
    required this.filled,
    required this.onTap,
  });

  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      tooltip: filled ? 'Убрать из заметок' : 'Сохранить',
      icon: Icon(
        filled ? Icons.bookmark : Icons.bookmark_border,
        size: 26,
        color: filled
            ? AppColors.bookmarkFilled
            : (isDark ? AppColors.darkTextSoft : Colors.black54),
      ),
    );
  }
}

/// Big photo lead story ("Главное").
class HeroTodayCard extends StatelessWidget {
  const HeroTodayCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final PostCard post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = post.image.hasUrl ? post.image : post.thumbnail;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image.hasUrl)
                _networkImage(image.url, placeholder)
              else
                Container(color: placeholder),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xDD000000)],
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                top: 14,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Новое',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title.isNotEmpty ? post.title : 'Новость',
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${post.dateDisplay}  ·  ${post.views} просм.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Large card: photo on top, big headline below.
class BigNewsCard extends StatelessWidget {
  const BigNewsCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.bookmarked,
    required this.onBookmarkTap,
  });

  final PostCard post;
  final VoidCallback onTap;
  final bool bookmarked;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = post.image.hasUrl ? post.image : post.thumbnail;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(14)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: image.hasUrl
                        ? _networkImage(image.url, placeholder)
                        : Container(color: placeholder),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 6, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CategoryBadge(post),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          post.title.isNotEmpty ? post.title : 'Новость',
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: isDark ? AppColors.darkText : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: _MetaRow(post)),
                          _BookmarkButton(
                            filled: bookmarked,
                            onTap: onBookmarkTap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Two compact cards side by side.
class NewsPairRow extends StatelessWidget {
  const NewsPairRow({
    super.key,
    required this.posts,
    required this.onTap,
  });

  final List<PostCard> posts;
  final void Function(PostCard post) onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _GridCard(post: posts[0], onTap: () => onTap(posts[0]))),
          const SizedBox(width: 12),
          Expanded(
            child: posts.length > 1
                ? _GridCard(post: posts[1], onTap: () => onTap(posts[1]))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _GridCard extends StatelessWidget {
  const _GridCard({required this.post, required this.onTap});

  final PostCard post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = post.image.hasUrl ? post.image : post.thumbnail;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: image.hasUrl
                  ? _networkImage(image.url, placeholder)
                  : Container(color: placeholder),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            post.title.isNotEmpty ? post.title : 'Новость',
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.25,
              color: isDark ? AppColors.darkText : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            post.dateDisplay,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.darkTextSoft
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal swipeable strip of stories.
class NewsCarousel extends StatelessWidget {
  const NewsCarousel({
    super.key,
    required this.title,
    required this.posts,
    required this.onTap,
  });

  final String title;
  final List<PostCard> posts;
  final void Function(PostCard post) onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scale = textScaleOf(context);
    final height = 150 + 36 + 3 * 20.0 * scale;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkText : Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: posts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final post = posts[index];
                final image = post.image.hasUrl ? post.image : post.thumbnail;
                return GestureDetector(
                  onTap: () => onTap(post),
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            height: 150,
                            width: 250,
                            child: image.hasUrl
                                ? _networkImage(image.url, placeholder)
                                : Container(color: placeholder),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            post.title.isNotEmpty ? post.title : 'Новость',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              height: 1.25,
                              color:
                                  isDark ? AppColors.darkText : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewsListCard extends StatelessWidget {
  const NewsListCard({
    super.key,
    required this.post,
    required this.onTap,
    this.bookmarked = false,
    this.onBookmarkTap,
    this.forceBookmarkedStyle = false,
  });

  final PostCard post;
  final VoidCallback onTap;
  final bool bookmarked;
  final VoidCallback? onBookmarkTap;
  final bool forceBookmarkedStyle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final image = post.thumbnail.hasUrl ? post.thumbnail : post.image;
    final hasImage = image.hasUrl;
    final showFilled = bookmarked || forceBookmarkedStyle;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final scale = textScaleOf(context);
    // Height grows with the text size so nothing is clipped or overlaps.
    final cardHeight = 128.0 * scale;

    final titleStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
      color: isDark ? AppColors.darkText : Colors.black,
    );

    final bookmark = onBookmarkTap == null
        ? const SizedBox(width: 8)
        : _BookmarkButton(filled: showFilled, onTap: onBookmarkTap!);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: hasImage
                ? SizedBox(
                    height: cardHeight,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(12),
                          ),
                          child: SizedBox(
                            width: 120,
                            height: cardHeight,
                            child: _networkImage(image.url, placeholder),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 0, 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _CategoryBadge(post),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    post.title.isNotEmpty
                                        ? post.title
                                        : 'Новость',
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                _MetaRow(post),
                              ],
                            ),
                          ),
                        ),
                        bookmark,
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _CategoryBadge(post),
                              const SizedBox(height: 6),
                              Text(
                                post.title.isNotEmpty
                                    ? post.title
                                    : 'Новость',
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              const SizedBox(height: 8),
                              _MetaRow(post),
                            ],
                          ),
                        ),
                        bookmark,
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Legacy lead card — prefers [HeroTodayCard] on home.
class LeadPostCard extends StatelessWidget {
  const LeadPostCard({
    super.key,
    required this.post,
    required this.onTap,
  });

  final PostCard post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HeroTodayCard(post: post, onTap: onTap);
  }
}

/// Compact tile — maps to [NewsListCard] without bookmark action.
class CompactPostTile extends StatelessWidget {
  const CompactPostTile({
    super.key,
    required this.post,
    required this.onTap,
  });

  final PostCard post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NewsListCard(post: post, onTap: onTap);
  }
}
