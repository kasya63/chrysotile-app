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
                placeholder: (_, _) => Container(color: AppColors.border),
                errorWidget: (_, _, _) => Container(color: AppColors.border),
              )
            else
              Container(color: AppColors.border),
            if (dateLabel != null && dateLabel!.isNotEmpty)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostImageFrame(
            image: post.image.hasUrl ? post.image : post.thumbnail,
            dateLabel: post.dateDisplay,
          ),
          const SizedBox(height: 12),
          Text(
            post.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}

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
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 112,
              child: PostImageFrame(
                image: post.thumbnail.hasUrl ? post.thumbnail : post.image,
                aspectRatio: 4 / 3,
                dateLabel: post.dateDisplay,
                borderRadius: 10,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                post.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
