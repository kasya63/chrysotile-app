import 'package:chrysotile_app/core/api/chrysotile_api.dart';
import 'package:chrysotile_app/core/models/auth_models.dart';
import 'package:chrysotile_app/core/storage/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiProvider = Provider<ChrysotileApi>((ref) {
  final storage = ref.watch(tokenStorageProvider);
  return ChrysotileApi(tokenReader: storage.readToken);
});

class AuthController extends AsyncNotifier<AuthUser?> {
  @override
  Future<AuthUser?> build() async {
    final storage = ref.read(tokenStorageProvider);
    final token = await storage.readToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      return await ref.read(apiProvider).fetchMe();
    } catch (_) {
      await storage.clear();
      return null;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(apiProvider).login(
            email: email,
            password: password,
          );
      await ref.read(tokenStorageProvider).writeToken(session.token);
      final me = await ref.read(apiProvider).fetchMe();
      state = AsyncData(me);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
  }) async {
    state = const AsyncLoading();
    try {
      final session = await ref.read(apiProvider).register(
            email: email,
            password: password,
            name: name,
          );
      await ref.read(tokenStorageProvider).writeToken(session.token);
      final me = await ref.read(apiProvider).fetchMe();
      state = AsyncData(me);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> deleteAccount({required String password}) async {
    await ref.read(apiProvider).deleteAccount(password: password);
    await ref.read(tokenStorageProvider).clear();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? avatarPath,
  }) async {
    final updated = await ref.read(apiProvider).updateMe(
          firstName: firstName,
          lastName: lastName,
          avatarPath: avatarPath,
        );
    state = AsyncData(updated);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthUser?>(AuthController.new);

final isLoggedInProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).valueOrNull != null;
});
