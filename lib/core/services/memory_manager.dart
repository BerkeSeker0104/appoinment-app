import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

/// Memory management service for optimizing app performance
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  Timer? _memoryCheckTimer;
  bool _isLowMemory = false;
  final List<VoidCallback> _memoryListeners = [];
  static const MethodChannel _memoryChannel = MethodChannel('memory_info');

  /// Initialize memory monitoring
  void initialize() {
    // Start periodic memory checks
    _startMemoryMonitoring();

    // Listen to system memory pressure
    _listenToMemoryPressure();
  }

  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    _memoryCheckTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkMemoryUsage(),
    );
  }

  /// Check current memory usage
  Future<void> _checkMemoryUsage() async {
    try {
      if (Platform.isAndroid) {
        final memoryInfo = await _getAndroidMemoryInfo();
        final isLowMemory = memoryInfo['isLowMemory'] ?? false;

        if (isLowMemory != _isLowMemory) {
          _isLowMemory = isLowMemory;
          _notifyMemoryListeners();
        }
      } else if (Platform.isIOS) {
        final memoryInfo = await _getIOSMemoryInfo();
        final isLowMemory = memoryInfo['isLowMemory'] ?? false;

        if (isLowMemory != _isLowMemory) {
          _isLowMemory = isLowMemory;
          _notifyMemoryListeners();
        }
      }
    } catch (e) {
      // Memory check failed
    }
  }

  /// Get Android memory information
  Future<Map<String, dynamic>> _getAndroidMemoryInfo() async {
    try {
      final result = await _memoryChannel.invokeMethod('getMemoryInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      // Fallback to basic memory estimation
      return {'isLowMemory': false, 'availableMemory': 0};
    }
  }

  /// Get iOS memory information
  Future<Map<String, dynamic>> _getIOSMemoryInfo() async {
    try {
      final result = await _memoryChannel.invokeMethod('getIOSMemoryInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      // Fallback to basic memory estimation
      // For iOS, we can use a simple heuristic based on device type
      return {
        'isLowMemory': _estimateIOSLowMemory(),
        'availableMemory': 0,
      };
    }
  }

  /// Estimate if iOS device is low on memory
  /// This is a simple heuristic - actual memory info requires native code
  bool _estimateIOSLowMemory() {
    // This is a placeholder - actual implementation will use native iOS APIs
    // For now, return false as we don't have device memory info
    return false;
  }

  /// Listen to system memory pressure events
  void _listenToMemoryPressure() {
    if (Platform.isIOS) {
      // Set up iOS memory warning listener via platform channel
      _memoryChannel.setMethodCallHandler((call) async {
        if (call.method == 'didReceiveMemoryWarning') {
          _isLowMemory = true;
          _notifyMemoryListeners();
          optimizeMemoryUsage();
        } else if (call.method == 'didEnterBackground') {
          // Optimize memory when app enters background
          optimizeMemoryUsage();
        } else if (call.method == 'willEnterForeground') {
          // Restore normal memory settings when app enters foreground
          _isLowMemory = false;
          optimizeMemoryUsage();
        }
      });
    }
    // Android memory pressure is handled via periodic checks
  }

  /// Add memory pressure listener
  void addMemoryListener(VoidCallback listener) {
    _memoryListeners.add(listener);
  }

  /// Remove memory pressure listener
  void removeMemoryListener(VoidCallback listener) {
    _memoryListeners.remove(listener);
  }

  /// Notify all memory listeners
  void _notifyMemoryListeners() {
    for (final listener in _memoryListeners) {
      try {
        listener();
      } catch (e) {
        // Memory listener error
      }
    }
  }

  /// Check if device is in low memory state
  bool get isLowMemory => _isLowMemory;

  /// Force garbage collection
  void forceGarbageCollection() {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();

    // Force Dart garbage collection
    // Note: This is not directly available in Flutter, but we can trigger it
    // by creating and disposing of objects
    _triggerGarbageCollection();
  }

  /// Trigger garbage collection by creating temporary objects
  void _triggerGarbageCollection() {
    // Create a large temporary list and dispose it
    final tempList = List.generate(1000, (index) => 'temp_$index');
    tempList.clear();

    // Create temporary maps and dispose them
    final tempMap = <String, dynamic>{};
    for (int i = 0; i < 100; i++) {
      tempMap['key_$i'] = 'value_$i';
    }
    tempMap.clear();
  }

  /// Optimize memory usage based on current state
  void optimizeMemoryUsage() {
    if (_isLowMemory) {
      // Clear image cache
      PaintingBinding.instance.imageCache.clear();

      // Reduce image cache size
      PaintingBinding.instance.imageCache.maximumSize = 50;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 25 << 20; // 25MB

      // Force garbage collection
      forceGarbageCollection();
    } else {
      // Restore normal cache settings
      PaintingBinding.instance.imageCache.maximumSize = 200;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
    }
  }

  /// Get memory usage statistics
  Future<Map<String, dynamic>> getMemoryStats() async {
    try {
      if (Platform.isAndroid) {
        return await _getAndroidMemoryInfo();
      } else if (Platform.isIOS) {
        return await _getIOSMemoryInfo();
      }
      return {'isLowMemory': false, 'availableMemory': 0};
    } catch (e) {
      return {
        'isLowMemory': false,
        'availableMemory': 0,
        'error': e.toString()
      };
    }
  }

  /// Dispose memory manager
  void dispose() {
    _memoryCheckTimer?.cancel();
    _memoryListeners.clear();
  }
}

/// Memory-aware widget mixin
mixin MemoryAwareWidget<T extends StatefulWidget> on State<T> {
  void initMemoryAware() {
    MemoryManager().addMemoryListener(_onMemoryPressure);
  }

  void disposeMemoryAware() {
    MemoryManager().removeMemoryListener(_onMemoryPressure);
  }

  /// Called when memory pressure is detected
  void _onMemoryPressure() {
    if (mounted) {
      onMemoryPressure();
    }
  }

  /// Override this method to handle memory pressure
  void onMemoryPressure() {
    // Default implementation - clear any cached data
  }
}

/// Memory optimization utilities
class MemoryOptimizer {
  /// Get iOS-specific cache extent
  static double _getIOSCacheExtent() {
    if (!Platform.isIOS) return 200.0;
    
    // iOS devices typically have good memory, so we can cache more
    // iPad: even more aggressive caching
    final screenSize = WidgetsBinding.instance.window.physicalSize;
    final isIPad = screenSize.shortestSide > 700;
    
    if (isIPad) {
      return 400.0; // iPad: cache more items
    } else {
      return 250.0; // iPhone: moderate caching
    }
  }

  /// Optimize list rendering for large datasets
  static Widget buildOptimizedList({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    final cacheExtent = Platform.isIOS ? _getIOSCacheExtent() : 200.0;
    
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Wrap each item in RepaintBoundary for iOS optimization
        final item = itemBuilder(context, index);
        if (Platform.isIOS) {
          return RepaintBoundary(child: item);
        }
        return item;
      },
      // Performance optimizations
      cacheExtent: cacheExtent,
      addAutomaticKeepAlives:
          false, // Don't keep items alive when scrolled away
      addRepaintBoundaries:
          true, // Add repaint boundaries for better performance
      addSemanticIndexes:
          false, // Disable semantic indexes for better performance
    );
  }

  /// Optimize grid rendering for large datasets
  static Widget buildOptimizedGrid({
    required int itemCount,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    ScrollController? controller,
    bool shrinkWrap = false,
  }) {
    final cacheExtent = Platform.isIOS ? _getIOSCacheExtent() : 200.0;
    
    return GridView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: itemCount,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        // Wrap each item in RepaintBoundary for iOS optimization
        final item = itemBuilder(context, index);
        if (Platform.isIOS) {
          return RepaintBoundary(child: item);
        }
        return item;
      },
      // Performance optimizations
      cacheExtent: cacheExtent,
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      addSemanticIndexes: false,
    );
  }
}
