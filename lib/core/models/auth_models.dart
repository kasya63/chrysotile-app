class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.nicename,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int? ?? 0,
      email: json['email'] as String? ?? json['user_email'] as String? ?? '',
      displayName: json['display_name'] as String? ??
          json['user_display_name'] as String? ??
          '',
      nicename:
          json['nicename'] as String? ?? json['user_nicename'] as String? ?? '',
    );
  }

  final int id;
  final String email;
  final String displayName;
  final String nicename;
}

class AuthSession {
  const AuthSession({
    required this.token,
    required this.user,
  });

  final String token;
  final AuthUser user;
}

class ArticleComment {
  const ArticleComment({
    required this.id,
    required this.postId,
    required this.parent,
    required this.author,
    required this.authorId,
    required this.content,
    required this.date,
    required this.dateDisplay,
    required this.status,
  });

  factory ArticleComment.fromJson(Map<String, dynamic> json) {
    return ArticleComment(
      id: json['id'] as int? ?? 0,
      postId: json['post_id'] as int? ?? 0,
      parent: json['parent'] as int? ?? 0,
      author: json['author'] as String? ?? '',
      authorId: json['author_id'] as int? ?? 0,
      content: json['content'] as String? ?? '',
      date: json['date'] as String? ?? '',
      dateDisplay: json['date_display'] as String? ?? '',
      status: json['status'] as String? ?? 'approved',
    );
  }

  final int id;
  final int postId;
  final int parent;
  final String author;
  final int authorId;
  final String content;
  final String date;
  final String dateDisplay;
  final String status;

  bool get isPending => status == 'pending';
}
