import 'package:chrysotile_app/core/config/app_config.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:dio/dio.dart';

class ChrysotileApi {
  ChrysotileApi({Dio? dio}) : _dio = dio ?? Dio(_defaultOptions);

  final Dio _dio;

  static final BaseOptions _defaultOptions = BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
    headers: const {
      'Accept': 'application/json',
    },
  );

  Future<HomeFeed> fetchHome() async {
    final response = await _dio.get<Map<String, dynamic>>('/home');
    return HomeFeed.fromJson(response.data ?? {});
  }

  Future<PostCard> fetchPost(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    return PostCard.fromJson(response.data ?? {});
  }

  Future<void> trackView(int id) async {
    await _dio.post<void>('/posts/$id/view');
  }

  Future<List<CategoryInfo>> fetchCategories() async {
    final response = await _dio.get<Map<String, dynamic>>('/categories');
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => CategoryInfo.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PaginatedPosts> fetchFeed({
    String? category,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/feed',
      queryParameters: {
        if (category != null && category.isNotEmpty) 'category': category,
        'page': page,
        'per_page': perPage,
      },
    );
    return PaginatedPosts.fromJson(response.data ?? {});
  }

  Future<PaginatedPosts> search({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/search',
      queryParameters: {
        'q': query,
        'page': page,
        'per_page': perPage,
      },
    );
    return PaginatedPosts.fromJson(response.data ?? {});
  }
}
