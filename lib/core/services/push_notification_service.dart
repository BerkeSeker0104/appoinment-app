import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/appointment_repository_impl.dart';
import '../../data/services/message_api_service.dart';
import '../../data/services/notification_api_service.dart';
import '../../domain/usecases/appointment_usecases.dart';
import '../constants/api_constants.dart';
import 'api_client.dart';
import 'badge_service.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user.dart';
import '../../presentation/pages/customer/rating_page.dart';
import '../../presentation/widgets/messaging_panel.dart';

const _deviceTokenStorageKey = 'device_token';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    
    // Initialize badge service
    await BadgeService().initialize();
    
    // Update badge immediately when notification is received in background
    try {
      final notificationApiService = NotificationApiService();
      final count = await notificationApiService.getUnreadCount();
      await BadgeService().updateBadge(count);
    } catch (e) {
      // Sessizce devam et - kritik değil
      if (kDebugMode) {
        debugPrint('firebaseMessagingBackgroundHandler: Failed to update badge: $e');
      }
    }
  } catch (_) {
    // Firebase might already be initialized or the platform does not require it.
  }
}

class PushNotificationService {
  PushNotificationService._internal();

  static final PushNotificationService _instance =
      PushNotificationService._internal();

  factory PushNotificationService() => _instance;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  SharedPreferences? _prefs;
  String? _cachedToken;
  bool _isInitialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;
  final List<String> _pendingAppointmentIds = [];
  final Set<String> _handledAppointmentIds = {};
  String? _activeAppointmentNavigationId;
  final List<String> _pendingMessageIds = [];
  final Set<String> _handledMessageIds = {};
  String? _activeMessageNavigationId;
  bool _isAppReady = false;
  final AppointmentUseCases _appointmentUseCases =
      AppointmentUseCases(AppointmentRepositoryImpl());
  final MessageApiService _messageApiService = MessageApiService();

  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('PushNotificationService: initialize called');
    }
    
    // CRITICAL FIX: Early return if already initialized
    // This prevents multiple listener registrations
    if (_isInitialized) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: already initialized, skipping');
      }
      return;
    }
    
    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        _prefs = null;
      }
    }

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(
          firebaseMessagingBackgroundHandler);
    }
    _messaging.onTokenRefresh.listen((token) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: token refreshed: $token');
      }
      _cacheToken(token);
    });
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    
    // Mark as initialized AFTER setting up listeners
    _isInitialized = true;

    await _requestNotificationPermissions();
    await _ensureToken();
  }

  Future<String?> getCachedToken() async {
    if (_cachedToken != null) {
      return _cachedToken;
    }

    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        _prefs = null;
      }
    }

    if (_prefs != null) {
      _cachedToken = _prefs!.getString(_deviceTokenStorageKey);
    }

    return _cachedToken;
  }

  Future<String?> getDeviceToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      try {
        await _messaging.deleteToken();
        _cachedToken = null;
      } catch (e, stackTrace) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: Failed to delete token: $e');
          debugPrint(stackTrace.toString());
        }
      }
    }

    final cached = await getCachedToken();
    if (!forceRefresh && cached != null && cached.isNotEmpty) {
      return cached;
    }

    await _ensureToken();
    return _cachedToken;
  }

  Future<void> _ensureToken() async {
    try {
      await _messaging.setAutoInitEnabled(true);

      final apnsToken = await _messaging.getAPNSToken();
      if (apnsToken == null || apnsToken.isEmpty) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: APNs token not yet available');
        }
        await Future<void>.delayed(const Duration(milliseconds: 500));
        return await _ensureToken();
      }

      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          debugPrint('PushNotificationService: initial token: $token');
        }
        await _cacheToken(token);
        return;
      }

      if (kDebugMode) {
        debugPrint('PushNotificationService: getToken returned null/empty');
      }

      if (_isAppleDevice) {
        final apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null && apnsToken.isNotEmpty && kDebugMode) {
          debugPrint(
              'PushNotificationService: APNs token retrieved but FCM token missing.');
        }
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: Unable to get device token: $e');
        debugPrint(stackTrace.toString());
      }
    }
  }

  Future<void> _requestNotificationPermissions() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        debugPrint(
            'PushNotificationService: permission status ${settings.authorizationStatus}');
      }

      if (settings.authorizationStatus == AuthorizationStatus.denied &&
          kDebugMode) {
        debugPrint('PushNotificationService: Notification permissions denied.');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint(
            'PushNotificationService: Failed to request permissions: $e');
        debugPrint(stackTrace.toString());
      }
    }

    if (_isAppleDevice) {
      try {
        await _messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              'PushNotificationService: Unable to set foreground options: $e');
        }
      }
    }
  }

  void registerNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    _flushPendingAppointments();
    if (_isAppReady) {
      _flushPendingMessages();
    }
  }

  Future<void> processInitialMessage() async {
    try {
      final message = await FirebaseMessaging.instance.getInitialMessage();
      if (message != null) {
        _handleNotificationTap(message);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PushNotificationService: initial message error $e');
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Update badge immediately when notification is received
    _updateBadgeOnNotificationReceived();
    
    if (_isAppointmentNotification(message)) {
      final appointmentId = _extractAppointmentId(message);
      if (appointmentId == null) return;

      final context = _navigatorKey?.currentContext;
      if (context == null) {
        _scheduleRatingNavigation(appointmentId);
        return;
      }

      if (_handledAppointmentIds.contains(appointmentId) ||
          _activeAppointmentNavigationId == appointmentId) {
        return;
      }

      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Randevu Tamamlandı'),
          content: const Text(
            'Randevunuzu değerlendirmek ister misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Daha Sonra'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _scheduleRatingNavigation(appointmentId);
              },
              child: const Text('Değerlendir'),
            ),
          ],
        ),
      );
    }
  }


  void _handleNotificationTap(RemoteMessage message) {
    if (_isAppointmentNotification(message)) {
      final appointmentId = _extractAppointmentId(message);
      if (appointmentId == null) return;
      _scheduleRatingNavigation(appointmentId);
      return;
    }

    if (_isMessageNotification(message)) {
      final messageId = _extractMessageId(message);
      if (messageId == null) return;
      _scheduleMessageNavigation(messageId);
    }
  }

  void _scheduleRatingNavigation(String appointmentId) {
    if (_handledAppointmentIds.contains(appointmentId) ||
        _activeAppointmentNavigationId == appointmentId) {
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      if (!_pendingAppointmentIds.contains(appointmentId)) {
        _pendingAppointmentIds.add(appointmentId);
      }
      return;
    }

    _navigateToRating(appointmentId);
  }

  Future<void> _navigateToRating(String appointmentId) async {
    if (_handledAppointmentIds.contains(appointmentId) ||
        _activeAppointmentNavigationId == appointmentId) {
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      if (!_pendingAppointmentIds.contains(appointmentId)) {
        _pendingAppointmentIds.add(appointmentId);
      }
      return;
    }

    _activeAppointmentNavigationId = appointmentId;

    try {
      final appointment =
          await _appointmentUseCases.getAppointmentDetail(appointmentId);

      final barberName = appointment.companyName ?? 'İşletme';
      final serviceName = appointment.services.isNotEmpty
          ? appointment.services.first.name
          : 'Hizmet';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => RatingPage(
              barberName: barberName,
              serviceName: serviceName,
              appointmentId: appointment.id,
            ),
          ),
        ).then((_) {
          _activeAppointmentNavigationId = null;
        });
      });

      _handledAppointmentIds.add(appointmentId);
    } catch (e) {
      _activeAppointmentNavigationId = null;
      if (kDebugMode) {
        debugPrint(
            'PushNotificationService: navigation to rating failed: $e');
      }
    }
  }

  bool _isAppointmentNotification(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return false;

    final typeRaw = data['type'] ?? data['event'] ?? data['notificationType'];
    if (typeRaw == null) return false;

    final type = typeRaw.toString().toLowerCase();
    return type == 'appointmentcompleted' ||
        type == 'appointment_completed' ||
        type == 'appointmentcomment';
  }

  bool _isMessageNotification(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return false;

    final typeRaw = data['type'] ?? data['event'] ?? data['notificationType'];
    if (typeRaw == null) return false;

    return typeRaw.toString().toLowerCase() == 'message';
  }

  String? _extractAppointmentId(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return null;

    final raw = data['dataId'] ??
        data['appointmentId'] ??
        data['appointment_id'] ??
        data['id'];
    if (raw == null) return null;

    final appointmentId = raw.toString();
    if (appointmentId.isEmpty) return null;
    return appointmentId;
  }

  String? _extractMessageId(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return null;

    final raw = data['messageId'] ?? data['message_id'] ?? data['id'];
    if (raw == null) return null;

    final messageId = raw.toString();
    if (messageId.isEmpty) return null;
    return messageId;
  }

  Future<void> _cacheToken(String token) async {
    _cachedToken = token;

    if (_prefs == null) {
      try {
        _prefs = await SharedPreferences.getInstance();
      } catch (_) {
        _prefs = null;
      }
    }

    if (_prefs != null) {
      try {
        await _prefs!.setString(_deviceTokenStorageKey, token);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
              'PushNotificationService: Failed to persist device token: $e');
        }
      }
    }
  }

  void _scheduleMessageNavigation(String messageId) {
    if (_handledMessageIds.contains(messageId) ||
        _activeMessageNavigationId == messageId) {
      return;
    }

    if (!_isAppReady) {
      if (!_pendingMessageIds.contains(messageId)) {
        _pendingMessageIds.add(messageId);
      }
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      if (!_pendingMessageIds.contains(messageId)) {
        _pendingMessageIds.add(messageId);
      }
      return;
    }

    _navigateToMessage(messageId);
  }

  Future<void> _navigateToMessage(String messageId) async {
    if (_handledMessageIds.contains(messageId) ||
        _activeMessageNavigationId == messageId) {
      return;
    }

    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      if (!_pendingMessageIds.contains(messageId)) {
        _pendingMessageIds.add(messageId);
      }
      return;
    }

    _activeMessageNavigationId = messageId;

    try {
      final user = await _getCurrentUser();
      if (user == null) {
        _activeMessageNavigationId = null;
        return;
      }

      final message = await _messageApiService.getMessage(messageId);

      // Load conversations to find receiver detail and stable conversation id
      List<ConversationModel> conversations = [];
      try {
        conversations = await _messageApiService.getMessagesList(
          companyId: user.isCompany ? message.companyId : null,
        );
      } catch (_) {}

      ConversationModel? targetConversation;
      for (final conversation in conversations) {
        if (conversation.originalId != null &&
            conversation.originalId == messageId) {
          targetConversation = conversation;
          break;
        }

        if (conversation.id.toString() == messageId) {
          targetConversation = conversation;
          break;
        }

        if (user.isCustomer &&
            conversation.companyId?.toString() == message.companyId) {
          targetConversation = conversation;
        } else if (user.isCompany &&
            conversation.customerId?.toString() == message.customerId) {
          targetConversation = conversation;
        }

        if (targetConversation != null) break;
      }

      final receiverName = user.isCustomer
          ? (targetConversation?.companyName ?? 'İşletme')
          : (targetConversation?.customerName ?? 'Müşteri');

      final rawImage = user.isCustomer
          ? targetConversation?.companyImage
          : targetConversation?.customerImage;
      final receiverImage = _resolveImageUrl(rawImage);

      final conversationId = user.isCompany
          ? (targetConversation?.originalId ??
              targetConversation?.id.toString() ??
              messageId)
          : (targetConversation?.id.toString() ??
              targetConversation?.originalId ??
              messageId);

      final companyId =
          targetConversation?.companyId ?? message.companyId ?? conversationId;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        showModalBottomSheet<void>(
          context: navigator.context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => MessagingPanel(
            receiverName: receiverName,
            receiverImage: receiverImage,
            receiverId: conversationId,
            companyId: companyId,
          ),
        ).whenComplete(() {
          _activeMessageNavigationId = null;
        });
      });

      _handledMessageIds.add(messageId);
    } catch (e) {
      _activeMessageNavigationId = null;
      if (kDebugMode) {
        debugPrint('PushNotificationService: message navigation failed: $e');
      }
    }
  }

  String _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.startsWith('http')) return raw;
    return '${ApiConstants.fileUrl}$raw';
  }

  Future<User?> _getCurrentUser() async {
    try {
      final apiClient = ApiClient();
      final userJson = await apiClient.getUserJson();
      if (userJson == null) return null;
      final decoded = jsonDecode(userJson) as Map<String, dynamic>;
      return UserModel.fromJson(decoded).toEntity();
    } catch (_) {
      return null;
    }
  }

  void markAppReady() {
    if (_isAppReady) return;
    _isAppReady = true;
    _flushPendingMessages();
  }

  void markAppNotReady() {
    _isAppReady = false;
  }

  void _flushPendingAppointments() {
    if (_pendingAppointmentIds.isEmpty) return;

    final pending = List<String>.from(_pendingAppointmentIds);
    _pendingAppointmentIds.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final id in pending) {
        _navigateToRating(id);
      }
    });
  }

  void _flushPendingMessages() {
    if (_pendingMessageIds.isEmpty) return;
    if (!_isAppReady) return;

    final pendingMessages = List<String>.from(_pendingMessageIds);
    _pendingMessageIds.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final id in pendingMessages) {
        _navigateToMessage(id);
      }
    });
  }

  /// Update badge count immediately when a notification is received
  /// This ensures the badge is updated in real-time, not just on 30-second intervals
  Future<void> _updateBadgeOnNotificationReceived() async {
    try {
      final notificationApiService = NotificationApiService();
      final count = await notificationApiService.getUnreadCount();
      await BadgeService().updateBadge(count);
    } catch (e) {
      // Sessizce devam et - kritik değil
      if (kDebugMode) {
        debugPrint('PushNotificationService: Failed to update badge: $e');
      }
    }
  }
}

bool get _isAppleDevice {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
