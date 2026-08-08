import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fcode_pos/services/deep_link_service.dart';
import 'package:fcode_pos/services/fcm_token_service.dart';
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

  /// Kênh thông báo Android cho foreground notifications cho đơn hàng POS Admin
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'pos_orders_channel', // id
    'Đơn hàng POS Admin', // title
    description:
        'Kênh nhận thông báo đơn hàng mới và cập nhật trạng thái đơn hàng.', // description
    importance: Importance.max,
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

    // 4. Subscribe topic chung cho POS Admin
    try {
      await _messaging.subscribeToTopic('pos_admin');
      if (kDebugMode) {
        print('Subscribed to FCM topic: pos_admin');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error subscribing to FCM topic pos_admin: $e');
      }
    }

    // 5. Khởi tạo Local Notifications (hiển thị banner khi app đang mở ở foreground trên Android)
    await _initLocalNotifications(onNotificationOpened);

    // 6. Đăng ký các Listeners lắng nghe tin nhắn
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
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            final clickAction = data['click_action'] as String?;
            final orderId = data['order_id'] as String?;
            if (clickAction != null && clickAction.isNotEmpty) {
              DeepLinkService.handleDeepLink(clickAction);
            } else if (orderId != null && orderId.isNotEmpty) {
              DeepLinkService.handleDeepLink('fcode://order/$orderId');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error handling local notification response: $e');
            }
          }
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

  /// Xử lý điều hướng khi bấm vào thông báo
  void _handleNotificationMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;

    if (kDebugMode) {
      print('Processing notification payload: $data');
    }

    final clickAction = data['click_action'] as String?;
    final orderId = data['order_id'] as String?;

    if (clickAction != null && clickAction.isNotEmpty) {
      DeepLinkService.handleDeepLink(clickAction);
    } else if (orderId != null && orderId.isNotEmpty) {
      DeepLinkService.handleDeepLink('fcode://order/$orderId');
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
        print('Data payload: ${message.data}');
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
          payload: jsonEncode(message.data),
        );
      }
    });

    // 2. Khi người dùng bấm vào thông báo lúc App đang ở Background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from background via notification: ${message.data}');
      }
      _handleNotificationMessage(message);
      onNotificationOpened?.call(message);
    });

    // 3. Khi ứng dụng bị tắt hoàn toàn (Terminated state) và được mở từ thông báo
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print('App opened from terminated state via notification: ${message.data}');
        }
        _handleNotificationMessage(message);
        onNotificationOpened?.call(message);
      }
    });

    // 4. Tự động lắng nghe khi FCM Token được làm mới
    _messaging.onTokenRefresh.listen((newToken) async {
      if (kDebugMode) {
        print('FCM Token Refreshed: $newToken');
      }
      try {
        await FcmTokenService().registerToken(newToken);
      } catch (e) {
        if (kDebugMode) {
          print('Error syncing refreshed FCM token: $e');
        }
      }
    });
  }

  /// Hiển thị Local Notification thử nghiệm (hoặc với khoảng hoãn delay)
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Duration? delay,
  }) async {
    if (delay != null && delay.inMilliseconds > 0) {
      await Future.delayed(delay);
    }
    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _localNotifications.show(
      id,
      title,
      body,
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
      payload: payload,
    );
  }

  /// Đồng bộ FCM Token hiện tại lên Server
  Future<void> syncTokenWithServer() async {
    try {
      final token = await getFCMToken();
      if (token != null && token.isNotEmpty) {
        await FcmTokenService().registerToken(token);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing FCM Token to server: $e');
      }
    }
  }

  /// Xóa FCM Token khỏi Server khi người dùng đăng xuất
  Future<void> deleteTokenFromServer() async {
    try {
      final token = await getFCMToken();
      await FcmTokenService().deleteToken(fcmToken: token);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting FCM Token from server: $e');
      }
    }
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
