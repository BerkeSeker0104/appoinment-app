import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/notification.dart' as entity;
import '../../domain/repositories/notification_repository.dart';
import '../../data/repositories/notification_repository_impl.dart';
import '../../data/services/notification_api_service.dart';
import '../../core/services/badge_service.dart';
import '../../core/services/app_lifecycle_service.dart';

class NotificationProvider with ChangeNotifier implements LoadingStateResettable {
  final NotificationRepository _notificationRepository;
  Timer? _refreshTimer;
  Timer? _countRefreshTimer;
  bool _isLoading = false;
  bool _isLoadingCount = false;
  String? _error;
  
  // Flag to prevent multiple auto-refresh instances
  bool _isAutoRefreshActive = false;

  // Notifications list state
  List<entity.Notification> _notifications = [];
  int _unreadCount = 0;
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _hasMorePages = true;

  NotificationProvider()
      : _notificationRepository =
            NotificationRepositoryImpl(NotificationApiService());

  // Getters
  List<entity.Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  bool get isLoadingCount => _isLoadingCount;
  String? get error => _error;
  bool get hasMorePages => _hasMorePages;

  // Start auto-refresh for notifications
  void startAutoRefresh() {
    // CRITICAL FIX: Prevent multiple auto-refresh instances
    // This was causing 100+ notifications because timers were accumulating
    if (_isAutoRefreshActive) {
      return; // Already active, don't create new timers
    }
    
    // Stop existing timers if any (safety check)
    stopAutoRefresh();
    
    // Mark as active BEFORE creating timers
    _isAutoRefreshActive = true;

    // Refresh notifications list every 60 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      loadNotifications(refresh: true);
    });

    // Refresh count every 30 seconds
    _countRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadUnreadCount();
    });

    // Initial load
    loadNotifications();
    loadUnreadCount().then((_) {
      // Update badge after initial count load
      BadgeService().updateBadge(_unreadCount);
    });
  }

  // Stop auto-refresh
  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _countRefreshTimer?.cancel();
    _countRefreshTimer = null;
    
    // Mark as inactive
    _isAutoRefreshActive = false;
  }

  // Load notifications list
  Future<void> loadNotifications({bool refresh = false}) async {
    try {
      if (refresh) {
        _currentPage = 1;
        _notifications = [];
        _hasMorePages = true;
      }

      _isLoading = true;
      _error = null;
      notifyListeners();

      final List<entity.Notification> newNotifications =
          await _notificationRepository.getNotifications(
        page: _currentPage,
        limit: _pageSize,
      );

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      // Check if there are more pages
      _hasMorePages = newNotifications.length == _pageSize;

      _isLoading = false;
      _error = null;
      notifyListeners();

      // Calculate local unread count from loaded notifications
      final localUnreadCount = _notifications.where((n) => !n.isRead).length;

      // Update badge with local count first for immediate feedback
      // If we are on the first page and all loaded notifications are read,
      // we can assume the user has seen everything relevant.
      if (_currentPage == 1 && localUnreadCount == 0) {
        // Only update if current count is not 0
        if (_unreadCount != 0) {
          _unreadCount = 0;
          await BadgeService().updateBadge(0);
          notifyListeners();
        }

        // Skip backend sync if we are confident (optional, but safer to sync)
        // However, if backend is consistently wrong (e.g. 99), we might want to trust local state more
        // when the user is actively viewing the list.

        // Let's still sync but maybe don't override if local is 0 and we just loaded fresh
      } else {
        // If local count differs from backend count, use local count for immediate UI update
        if (localUnreadCount != _unreadCount) {
          _unreadCount = localUnreadCount;
          await BadgeService().updateBadge(_unreadCount);
          notifyListeners();
        }
      }

      // Only sync from backend if we have unread items locally or if we are not on page 1
      // This prevents the case where backend says "99" but we show "0" unread items on screen
      if (localUnreadCount > 0 || _currentPage > 1) {
        await loadUnreadCount();
      }
    } catch (e) {
      _isLoading = false;

      // Check if error is due to unauthorized (guest user)
      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') ||
          errorString.contains('401') ||
          errorString.contains('yetkisiz');

      // Don't set error for guest users - overlay will handle it
      if (!isUnauthorized) {
        _error = e.toString();
      } else {
        _notifications = [];
        _error = null;
      }

      notifyListeners();
    }
  }

  // Load more notifications (pagination)
  Future<void> loadMoreNotifications() async {
    if (_isLoading || !_hasMorePages) return;

    // Save current page in case of error
    final previousPage = _currentPage;
    _currentPage++;
    
    try {
      await loadNotifications();
    } catch (e) {
      // Rollback page increment on error to prevent skipping pages
      _currentPage = previousPage;
      if (kDebugMode) {
        debugPrint('NotificationProvider: loadMoreNotifications failed, rolled back to page $_currentPage');
      }
      rethrow;
    }
  }

  // Load unread count
  Future<void> loadUnreadCount() async {
    try {
      _isLoadingCount = true;
      notifyListeners();

      final count = await _notificationRepository.getUnreadCount();
      
      int newUnreadCount = count;

      // Akıllı kontrol: Eğer ilk sayfayı yüklediysek ve hiç okunmamış bildirim yoksa,
      // backend ne derse desin sayıyı 0 yap. Bu, "hayalet" bildirim sayılarını düzeltir.
      // Genellikle bildirimler tarihe göre sıralı olduğu için, en güncel 20 bildirim
      // okunmuşsa, daha eskilerin okunmamış olması kullanıcı için önemsizdir veya hatadır.
      if (_notifications.isNotEmpty && _currentPage == 1) {
        final localUnreadCount = _notifications.where((n) => !n.isRead).length;
        if (localUnreadCount == 0) {
          newUnreadCount = 0;
        }
      }

      // Update state if changed
      if (_unreadCount != newUnreadCount) {
        _unreadCount = newUnreadCount;
        await BadgeService().updateBadge(_unreadCount);
      }
      
      _isLoadingCount = false;
      notifyListeners();
    } catch (e) {
      _isLoadingCount = false;
      // Don't show error for count loading, just log it
    }
  }

  // Mark notification as read
  Future<bool> markAsRead(String notificationId,
      {bool skipCountRefresh = false}) async {
    try {
      final success = await _notificationRepository.markAsRead(notificationId);

      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          final notification = _notifications[index];
          final wasUnread = !notification.isRead;
          _notifications[index] = notification.copyWith(isRead: true);

          // Decrease unread count if it was unread
          if (wasUnread) {
            _unreadCount = _unreadCount > 0 ? _unreadCount - 1 : 0;
          }

          notifyListeners();
        }

        // Refresh count only if not skipped (for batch operations)
        if (!skipCountRefresh) {
          await loadUnreadCount();
        } else {
          // Update badge even if count refresh is skipped
          await BadgeService().updateBadge(_unreadCount);
        }
      }

      return success;
    } catch (e) {
      return false;
    }
  }

  // Mark all notifications as read (if backend supports it)
  Future<void> markAllAsRead() async {
    try {
      final unreadNotifications =
          _notifications.where((n) => !n.isRead).toList();

      if (unreadNotifications.isEmpty) {
        return;
      }

      // Optimistic update: Update UI immediately
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCount = 0;
      notifyListeners();

      // Update badge immediately
      await BadgeService().updateBadge(0);

      // Then mark each as read on backend (in parallel for better performance)
      // Skip individual count refreshes since we'll refresh once at the end
      final futures = unreadNotifications
          .map((n) => markAsRead(n.id, skipCountRefresh: true));
      await Future.wait(futures);

      // We've optimistically updated the UI and marked all as read locally.
      // We also sent requests to backend.
      // We should NOT call loadUnreadCount() immediately because backend might have delay/cache.
      // Since we know we marked all as read, count should be 0.
      _unreadCount = 0;
      await BadgeService().updateBadge(0);
      notifyListeners();

      // Optionally reload notifications to ensure backend state is consistent
      // await loadNotifications(refresh: true);
    } catch (e) {
      // On error, reload notifications to sync with backend
      await loadNotifications(refresh: true);
      await loadUnreadCount();
    }
  }

  // Get unread notifications
  List<entity.Notification> get unreadNotifications {
    return _notifications.where((n) => !n.isRead).toList();
  }

  // Get read notifications
  List<entity.Notification> get readNotifications {
    return _notifications.where((n) => n.isRead).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoading || _isLoadingCount) {
      _isLoading = false;
      _isLoadingCount = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    AppLifecycleService().unregisterProvider(this);
    stopAutoRefresh();
    super.dispose();
  }
}
