import 'dart:convert';

import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookmarksStore {
  static const _key = 'chrysotile_bookmarks_v1';

  Future<List<PostCard>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => PostCard.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> save(List<PostCard> posts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(posts.map((post) => post.toJson()).toList());
    await prefs.setString(_key, encoded);
  }
}
