import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Interface for providers that need to reset their loading states
abstract class LoadingStateResettable {
  void resetLoadingState();
}

/// Service to manage app lifecycle and reset provider loading states
class AppLifecycleService {
  static final AppLifecycleService _instance = AppLifecycleService._internal();
  factory AppLifecycleService() => _instance;
  AppLifecycleService._internal();

  final List<LoadingStateResettable> _providers = [];
  final List<VoidCallback> _onResumeCallbacks = [];
  final List<VoidCallback> _onStaleDataCallbacks = [];
  bool _isInitialized = false;
  
  // Track background duration
  DateTime? _backgroundStartTime;
  Duration? _lastBackgroundDuration;
  
  // Threshold for aggressive refresh (10 minutes)
  static const Duration _aggressiveRefreshThreshold = Duration(minutes: 10);

  void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;
    if (kDebugMode) {
      debugPrint('AppLifecycleService: Initialized');
    }
  }

  void registerProvider(LoadingStateResettable provider) {
    if (!_providers.contains(provider)) {
      _providers.add(provider);
    }
  }

  void unregisterProvider(LoadingStateResettable provider) {
    _providers.remove(provider);
  }

  void registerOnResumeCallback(VoidCallback callback) {
    if (!_onResumeCallbacks.contains(callback)) {
      _onResumeCallbacks.add(callback);
    }
  }

  void unregisterOnResumeCallback(VoidCallback callback) {
    _onResumeCallbacks.remove(callback);
  }

  /// Register callback to be called when data becomes stale
  void registerOnStaleDataCallback(VoidCallback callback) {
    if (!_onStaleDataCallbacks.contains(callback)) {
      _onStaleDataCallbacks.add(callback);
    }
  }

  void unregisterOnStaleDataCallback(VoidCallback callback) {
    _onStaleDataCallbacks.remove(callback);
  }

  void resetAllLoadingStates() {
    if (kDebugMode) {
      debugPrint('AppLifecycleService: Resetting ${_providers.length} providers');
    }
    for (final provider in _providers) {
      try {
        provider.resetLoadingState();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AppLifecycleService: Reset error: $e');
        }
      }
    }
  }

  void onAppPaused() {
    if (kDebugMode) {
      debugPrint('AppLifecycleService: App paused');
    }
    _backgroundStartTime = DateTime.now();
  }

  void onAppResumed() {
    if (kDebugMode) {
      debugPrint('AppLifecycleService: App resumed');
    }
    
    // Calculate background duration
    if (_backgroundStartTime != null) {
      _lastBackgroundDuration = DateTime.now().difference(_backgroundStartTime!);
      if (kDebugMode) {
        debugPrint('AppLifecycleService: Was in background for ${_lastBackgroundDuration!.inSeconds}s');
      }
      _backgroundStartTime = null;
      
      // If app was in background for more than threshold, mark data as stale
      if (_lastBackgroundDuration! > _aggressiveRefreshThreshold) {
        if (kDebugMode) {
          debugPrint('AppLifecycleService: Background duration exceeded threshold, marking data as stale');
        }
        _notifyStaleData();
      }
    }
    
    resetAllLoadingStates();
    
    for (final callback in _onResumeCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AppLifecycleService: Callback error: $e');
        }
      }
    }
  }

  /// Notify all registered callbacks that data is stale
  void _notifyStaleData() {
    for (final callback in _onStaleDataCallbacks) {
      try {
        callback();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('AppLifecycleService: Stale data callback error: $e');
        }
      }
    }
  }

  /// Get the last background duration
  Duration? get lastBackgroundDuration => _lastBackgroundDuration;
  
  /// Check if app was in background for extended period
  bool wasInBackgroundLongTime() {
    return _lastBackgroundDuration != null && 
           _lastBackgroundDuration! > _aggressiveRefreshThreshold;
  }

  void clear() {
    _providers.clear();
    _onResumeCallbacks.clear();
    _onStaleDataCallbacks.clear();
    _backgroundStartTime = null;
    _lastBackgroundDuration = null;
  }
}

