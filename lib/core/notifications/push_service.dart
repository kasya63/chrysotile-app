import 'dart:async';
import 'dart:io';

import 'package:chrysotile_app/features/auth/auth_providers.dart';
import 'package:chrysotile_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chrysotile_app/core/api/chrysotile_api.dart';

const _topicsPrefsKey = 'push_topics';
const _defaultTopics = ['cat_glavnye'];

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushService {
  PushService(this._api);

  final ChrysotileApi _api;
  final _local = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  String? _token;

  final StreamController<int> _openPostController =
      StreamController<int>.broadcast();

  Stream<int> get openPostRequests => _openPostController.stream;
  bool get isReady => _ready;
  String? get token => _token;

  Future<bool> initialize() async {
    if (!DefaultFirebaseOptions.isConfigured) {
      return false;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (error, stack) {
      debugPrint('Firebase init failed: $error\n$stack');
      return false;
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        final id = int.tryParse(response.payload ?? '');
        if (id != null) {
          _openPostController.add(id);
        }
      },
    );

    final androidPlugin = _local.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        'chrysotile_news',
        'Новости',
        description: 'Уведомления о новых публикациях',
        importance: Importance.high,
      ),
    );

    final messaging = FirebaseMessaging.instance;
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_showForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      _handleMessageOpen(initial);
    }

    _ready = true;
    return true;
  }

  Future<bool> requestPermissionAndRegister() async {
    if (!_ready) {
      return false;
    }

    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final enabled = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    if (!enabled) {
      return false;
    }

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    _token = token;
    final topics = await loadTopics();
    await _syncTopics(topics);
    await _registerDevice(token, topics);

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      _token = newToken;
      final currentTopics = await loadTopics();
      await _registerDevice(newToken, currentTopics);
    });

    return true;
  }

  Future<List<String>> loadTopics() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_topicsPrefsKey) ?? List.of(_defaultTopics);
  }

  Future<void> saveTopics(List<String> topics) async {
    final normalized = topics.isEmpty ? List.of(_defaultTopics) : topics;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_topicsPrefsKey, normalized);

    if (!_ready || _token == null) {
      return;
    }

    await _syncTopics(normalized);
    await _registerDevice(_token!, normalized);
  }

  Future<void> _syncTopics(List<String> topics) async {
    final messaging = FirebaseMessaging.instance;
    final known = [
      'cat_glavnye',
      'cat_gosudarstvo',
      'cat_region',
      'cat_people',
      'cat_society',
      'cat_special_projects',
      'cat_video',
    ];

    for (final topic in known) {
      if (topics.contains(topic)) {
        await messaging.subscribeToTopic(topic);
      } else {
        await messaging.unsubscribeFromTopic(topic);
      }
    }
  }

  Future<void> _registerDevice(String token, List<String> topics) async {
    final info = await PackageInfo.fromPlatform();
    final platform = kIsWeb
        ? 'unknown'
        : Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
                ? 'android'
                : 'unknown';

    await _api.registerDevice(
      fcmToken: token,
      platform: platform,
      topics: topics,
      appVersion: info.version,
    );
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    final postId = message.data['post_id'];
    final title = notification?.title ?? 'Chrysotile';
    final body = notification?.body ?? '';

    _local.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chrysotile_news',
          'Новости',
          channelDescription: 'Уведомления о новых публикациях',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: postId,
    );
  }

  void _handleMessageOpen(RemoteMessage message) {
    final raw = message.data['post_id'];
    final id = int.tryParse(raw ?? '');
    if (id != null) {
      _openPostController.add(id);
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  return PushService(ref.watch(apiProvider));
});

final pushReadyProvider = FutureProvider<bool>((ref) async {
  final service = ref.watch(pushServiceProvider);
  return service.initialize();
});

final pushTopicsProvider =
    StateNotifierProvider<PushTopicsNotifier, AsyncValue<List<String>>>((ref) {
  return PushTopicsNotifier(ref);
});

class PushTopicsNotifier extends StateNotifier<AsyncValue<List<String>>> {
  PushTopicsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _load();
  }

  final Ref _ref;

  Future<void> _load() async {
    final service = _ref.read(pushServiceProvider);
    state = AsyncValue.data(await service.loadTopics());
  }

  Future<void> toggle(String topic, bool enabled) async {
    final current = List<String>.of(state.value ?? _defaultTopics);
    if (enabled) {
      if (!current.contains(topic)) {
        current.add(topic);
      }
    } else {
      current.remove(topic);
    }
    if (current.isEmpty) {
      current.add('cat_glavnye');
    }
    state = AsyncValue.data(current);
    await _ref.read(pushServiceProvider).saveTopics(current);
  }
}
