class PostImage {
  const PostImage({
    required this.url,
    required this.width,
    required this.height,
  });

  factory PostImage.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PostImage(url: '', width: 0, height: 0);
    }

    return PostImage(
      url: json['url'] as String? ?? '',
      width: json['width'] as int? ?? 0,
      height: json['height'] as int? ?? 0,
    );
  }

  final String url;
  final int width;
  final int height;

  bool get hasUrl => url.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'url': url,
        'width': width,
        'height': height,
      };
}

class PostCategory {
  const PostCategory({
    required this.id,
    required this.slug,
    required this.name,
  });

  factory PostCategory.fromJson(Map<String, dynamic> json) {
    return PostCategory(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  final int id;
  final String slug;
  final String name;

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
      };
}

class PostCard {
  const PostCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.excerpt,
    required this.date,
    required this.dateDisplay,
    required this.permalink,
    required this.image,
    required this.thumbnail,
    required this.categories,
    required this.readingMin,
    required this.views,
    this.contentHtml,
    this.related = const [],
  });

  factory PostCard.fromJson(Map<String, dynamic> json) {
    return PostCard(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      excerpt: json['excerpt'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dateDisplay: json['date_display'] as String? ?? '',
      permalink: json['permalink'] as String? ?? '',
      image: PostImage.fromJson(json['image'] as Map<String, dynamic>?),
      thumbnail: PostImage.fromJson(json['thumbnail'] as Map<String, dynamic>?),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((item) => PostCategory.fromJson(item as Map<String, dynamic>))
          .toList(),
      readingMin: json['reading_min'] as int? ?? 1,
      views: json['views'] as int? ?? 0,
      contentHtml: json['content_html'] as String?,
      related: (json['related'] as List<dynamic>? ?? [])
          .map((item) => PostCard.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final int id;
  final String title;
  final String subtitle;
  final String excerpt;
  final String date;
  final String dateDisplay;
  final String permalink;
  final PostImage image;
  final PostImage thumbnail;
  final List<PostCategory> categories;
  final int readingMin;
  final int views;
  final String? contentHtml;
  final List<PostCard> related;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'excerpt': excerpt,
        'date': date,
        'date_display': dateDisplay,
        'permalink': permalink,
        'image': image.toJson(),
        'thumbnail': thumbnail.toJson(),
        'categories': categories.map((c) => c.toJson()).toList(),
        'reading_min': readingMin,
        'views': views,
        if (contentHtml != null) 'content_html': contentHtml,
        'related': related.map((p) => p.toJson()).toList(),
      };
}

class FeedSection {
  const FeedSection({
    required this.slug,
    required this.label,
    required this.posts,
    required this.total,
  });

  factory FeedSection.fromJson(Map<String, dynamic> json) {
    return FeedSection(
      slug: json['slug'] as String? ?? '',
      label: json['label'] as String? ?? '',
      posts: (json['posts'] as List<dynamic>? ?? [])
          .map((item) => PostCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
    );
  }

  final String slug;
  final String label;
  final List<PostCard> posts;
  final int total;
}

class HomeFeed {
  const HomeFeed({
    required this.hero,
    required this.sections,
  });

  factory HomeFeed.fromJson(Map<String, dynamic> json) {
    return HomeFeed(
      hero: (json['hero'] as List<dynamic>? ?? [])
          .map((item) => PostCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((item) => FeedSection.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  final List<PostCard> hero;
  final List<FeedSection> sections;
}

class CategoryInfo {
  const CategoryInfo({
    required this.id,
    required this.slug,
    required this.name,
    required this.count,
  });

  factory CategoryInfo.fromJson(Map<String, dynamic> json) {
    return CategoryInfo(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }

  final int id;
  final String slug;
  final String name;
  final int count;
}

class PaginatedPosts {
  const PaginatedPosts({
    required this.items,
    required this.total,
    required this.page,
    required this.perPage,
  });

  factory PaginatedPosts.fromJson(Map<String, dynamic> json) {
    return PaginatedPosts(
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => PostCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      perPage: json['per_page'] as int? ?? 20,
    );
  }

  final List<PostCard> items;
  final int total;
  final int page;
  final int perPage;

  bool get hasMore => items.length < total;

  PaginatedPosts merge(PaginatedPosts next) {
    return PaginatedPosts(
      items: [...items, ...next.items],
      total: next.total,
      page: next.page,
      perPage: next.perPage,
    );
  }
}
