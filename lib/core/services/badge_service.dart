import 'package:flutter_app_badger/flutter_app_badger.dart';
import 'package:flutter/foundation.dart';

class BadgeService {
  BadgeService._internal();

  static final BadgeService _instance = BadgeService._internal();

  factory BadgeService() => _instance;

  bool _isSupported = false;
  bool _isInitialized = false;
  int _currentBadgeCount = 0;
  bool _isInitializing = false;

  /// Initialize the badge service and check platform support
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Prevent concurrent initialization
    if (_isInitializing) {
      // Wait for initialization to complete
      int retries = 0;
      while (_isInitializing && retries < 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        retries++;
      }
      return;
    }

    _isInitializing = true;

    try {
      _isSupported = await FlutterAppBadger.isAppBadgeSupported();
      if (kDebugMode) {
        debugPrint('BadgeService: Platform support: $_isSupported');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BadgeService: Initialization error: $e');
      }
      _isSupported = false;
    } finally {
      _isInitialized = true;
      _isInitializing = false;
    }
  }

  /// Check if badge is supported on the current platform
  bool isSupported() {
    return _isSupported;
  }

  /// Update the app badge count
  /// 
  /// [count] - The number to display on the badge. Use 0 to remove the badge.
  Future<void> updateBadge(int count) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Prevent unnecessary updates and logs if count hasn't changed
    // Also check if initialized to ensure _currentBadgeCount is valid
    if (_isInitialized && count == _currentBadgeCount) {
      return;
    }
    
    _currentBadgeCount = count;

    if (!_isSupported) {
      return;
    }

    try {
      if (count <= 0) {
        await FlutterAppBadger.removeBadge();
        // Removed log to prevent spam
      } else {
        await FlutterAppBadger.updateBadgeCount(count);
        if (kDebugMode) {
          debugPrint('BadgeService: Badge updated to $count');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('BadgeService: Failed to update badge: $e');
      }
    }
  }

  /// Remove the app badge
  Future<void> removeBadge() async {
    await updateBadge(0);
  }
}

