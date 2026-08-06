import 'package:cached_network_image/cached_network_image.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:chrysotile_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

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
              CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: placeholder),
                errorWidget: (_, _, _) => Container(color: placeholder),
              )
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
                      fontSize: 12,
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
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (image.hasUrl)
                CachedNetworkImage(
                  imageUrl: image.url,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(color: placeholder),
                  errorWidget: (_, _, _) => Container(color: placeholder),
                )
              else
                Container(color: placeholder),
              Positioned(
                left: 12,
                top: 11,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue.withValues(alpha: 0.63),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const Text(
                    'Новое',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 10,
                bottom: 10,
                child: Material(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(5),
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(5),
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 7, vertical: 5),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Читать',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
    final category =
        post.categories.isNotEmpty ? post.categories.first.name : 'Новости';
    final showFilled = bookmarked || forceBookmarkedStyle;
    final placeholder =
        isDark ? AppColors.darkBorder : AppColors.thumbnailPlaceholder;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final metaColor = isDark
        ? AppColors.darkTextSoft
        : Colors.black.withValues(alpha: 0.6);

    Widget categoryBadge() => Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.blue.withValues(alpha: 0.25)
                : AppColors.categoryBadge,
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            category,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.blueSoft : AppColors.blue,
            ),
          ),
        );

    Widget metaRow() => Row(
          children: [
            Icon(Icons.calendar_today_outlined, size: 10, color: metaColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                post.dateDisplay.isNotEmpty ? post.dateDisplay : 'Дата',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                  color: metaColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.remove_red_eye_outlined, size: 12, color: metaColor),
            const SizedBox(width: 4),
            Text(
              '${post.views}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w500,
                color: metaColor,
              ),
            ),
          ],
        );

    Widget? bookmarkButton() {
      if (onBookmarkTap == null) {
        return null;
      }
      return IconButton(
        onPressed: onBookmarkTap,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          showFilled ? Icons.bookmark : Icons.bookmark_border,
          size: 22,
          color: showFilled
              ? AppColors.bookmarkFilled
              : (isDark ? AppColors.darkTextSoft : Colors.black54),
        ),
      );
    }

    final titleStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.25,
      color: isDark ? AppColors.darkText : Colors.black,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            constraints: BoxConstraints(minHeight: hasImage ? 80 : 72),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            child: hasImage
                ? SizedBox(
                    height: 80,
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(10),
                          ),
                          child: SizedBox(
                            width: 117,
                            height: 80,
                            child: CachedNetworkImage(
                              imageUrl: image.url,
                              fit: BoxFit.cover,
                              placeholder: (_, _) =>
                                  Container(color: placeholder),
                              errorWidget: (_, _, _) =>
                                  Container(color: placeholder),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 6, 4, 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                categoryBadge(),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: Text(
                                    post.title.isNotEmpty
                                        ? post.title
                                        : 'Новость',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                ),
                                metaRow(),
                              ],
                            ),
                          ),
                        ),
                        bookmarkButton() ?? const SizedBox(width: 8),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              categoryBadge(),
                              const SizedBox(height: 6),
                              Text(
                                post.title.isNotEmpty
                                    ? post.title
                                    : 'Новость',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle,
                              ),
                              const SizedBox(height: 8),
                              metaRow(),
                            ],
                          ),
                        ),
                        bookmarkButton() ?? const SizedBox(width: 8),
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
