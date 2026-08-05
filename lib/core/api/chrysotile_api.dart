import 'package:chrysotile_app/core/config/app_config.dart';
import 'package:chrysotile_app/core/models/auth_models.dart';
import 'package:chrysotile_app/core/models/post_models.dart';
import 'package:dio/dio.dart';

typedef TokenReader = Future<String?> Function();

class ChrysotileApi {
  ChrysotileApi({
    Dio? dio,
    this._tokenReader,
  }) : _dio = dio ?? Dio(_defaultOptions) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final reader = _tokenReader;
          if (reader != null) {
            final token = await reader();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio _dio;
  final TokenReader? _tokenReader;

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

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'https://chrysotile.kz/wp-json/jwt-auth/v1/token',
      data: {
        'username': email,
        'password': password,
      },
    );
    final data = response.data ?? {};
    final token = data['token'] as String? ?? '';
    if (token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Пустой токен авторизации',
      );
    }

    return AuthSession(
      token: token,
      user: AuthUser(
        id: 0,
        email: data['user_email'] as String? ?? email,
        displayName: data['user_display_name'] as String? ?? email,
        nicename: data['user_nicename'] as String? ?? '',
      ),
    );
  }

  Future<AuthSession> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'email': email,
        'password': password,
        'name': name,
      },
    );
    final data = response.data ?? {};
    final token = data['token'] as String? ?? '';
    final userJson = data['user'] as Map<String, dynamic>?;
    final user = userJson != null
        ? AuthUser.fromJson(userJson)
        : AuthUser(
            id: 0,
            email: data['user_email'] as String? ?? email,
            displayName: data['user_display_name'] as String? ?? name,
            nicename: data['user_nicename'] as String? ?? '',
          );

    if (token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: data['message'] as String? ?? 'Не удалось получить токен',
      );
    }

    return AuthSession(token: token, user: user);
  }

  Future<AuthUser> fetchMe() async {
    final response = await _dio.get<Map<String, dynamic>>('/auth/me');
    return AuthUser.fromJson(response.data ?? {});
  }

  Future<List<ArticleComment>> fetchComments(int postId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/posts/$postId/comments',
    );
    final items = response.data?['items'] as List<dynamic>? ?? [];
    return items
        .map((item) => ArticleComment.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ArticleComment> createComment({
    required int postId,
    required String content,
    int parent = 0,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/posts/$postId/comments',
      data: {
        'content': content,
        'parent': parent,
      },
    );
    return ArticleComment.fromJson(response.data ?? {});
  }

  Future<void> registerDevice({
    required String fcmToken,
    required String platform,
    required List<String> topics,
    required String appVersion,
  }) async {
    await _dio.post<void>(
      '/devices',
      data: {
        'fcm_token': fcmToken,
        'platform': platform,
        'topics': topics,
        'app_version': appVersion,
      },
    );
  }

  Future<void> unregisterDevice(String fcmToken) async {
    await _dio.delete<void>(
      '/devices',
      queryParameters: {
        'fcm_token': fcmToken,
      },
    );
  }
}
