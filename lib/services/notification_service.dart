import 'dart:async';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler cho Firebase Messaging.
/// Bắt buộc phải là top-level hoặc static function và annotate @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (kDebugMode) {
    print('Handling background message: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Kênh thông báo Android cho foreground notifications
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        'This channel is used for important notifications.', // description
    importance: Importance.high,
  );

  /// Khởi tạo Firebase Messaging và APNs / Local Notifications
  Future<void> initialize({
    Function(RemoteMessage message)? onNotificationOpened,
  }) async {
    if (_isInitialized) return;

    // 1. Kích hoạt Firebase Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 2. Yêu cầu quyền thông báo (đặc biệt quan trọng trên iOS & Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (kDebugMode) {
      print('User notification permission status: ${settings.authorizationStatus}');
    }

    // 3. Cấu hình hiển thị thông báo Foreground cho iOS
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Khởi tạo Local Notifications (hiển thị banner khi app đang mở ở foreground trên Android)
    await _initLocalNotifications(onNotificationOpened);

    // 5. Đăng ký các Listeners lắng nghe tin nhắn
    _setupMessageListeners(onNotificationOpened);

    _isInitialized = true;

    // Log FCM Token & APNs Token để tiện Debug
    await logTokens();
  }

  /// Khởi tạo Local Notification Plugin
  Future<void> _initLocalNotifications(
    Function(RemoteMessage message)? onNotificationOpened,
  ) async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onNotificationOpened != null) {
          // Xử lý khi bấm vào local notification
        }
      },
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }
  }

  /// Lắng nghe các trạng thái thông báo: Foreground, Background Click, Terminated Click
  void _setupMessageListeners(
    Function(RemoteMessage message)? onNotificationOpened,
  ) {
    // 1. Khi nhận thông báo lúc App đang chạy Foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground Message received: ${message.notification?.title}');
      }

      final notification = message.notification;
      final android = message.notification?.android;

      // Hiển thị Banner bằng Local Notification nếu có thông báo
      if (notification != null && (android != null || Platform.isIOS)) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _androidChannel.id,
              _androidChannel.name,
              channelDescription: _androidChannel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
        );
      }
    });

    // 2. Khi người dùng bấm vào thông báo lúc App đang ở Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from background via notification: ${message.data}');
      }
      onNotificationOpened?.call(message);
    });

    // 3. Khi ứng dụng bị tắt hoàn toàn (Terminated state) và được mở từ thông báo
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state via notification: ${message.data}');
        }
        onNotificationOpened?.call(message);
      }
    });

    // 4. Tự động lắng nghe khi FCM Token được làm mới
    _messaging.onTokenRefresh.listen((newToken) {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      // Gửi token mới lên server của bạn tại đây
    });
  }

  /// Lấy FCM Token thiết bị
  Future<String?> getFCMToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching FCM Token: $e');
      }
      return null;
    }
  }

  /// Lấy APNs Token thiết bị (dành riêng cho iOS)
  Future<String?> getAPNsToken() async {
    if (!Platform.isIOS) return null;
    try {
      final token = await _messaging.getAPNSToken();
      return token;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching APNs Token: $e');
      }
      return null;
    }
  }

  /// In toàn bộ Token ra Console để Debug
  Future<void> logTokens() async {
    if (kDebugMode) {
      if (Platform.isIOS) {
        final apnsToken = await getAPNsToken();
        print('📱 APNs Token (iOS): $apnsToken');
      }
      final fcmToken = await getFCMToken();
      print('🔥 FCM Token: $fcmToken');
    }
  }
}
