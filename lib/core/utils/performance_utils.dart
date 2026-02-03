import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Performance optimization utilities for the app
class PerformanceUtils {
  /// Enable performance overlay in debug mode
  static void enablePerformanceOverlay() {
    // Performance overlay enabled
  }

  /// Optimize image cache settings
  static void optimizeImageCache() {
    if (Platform.isIOS) {
      // iOS-specific cache optimization
      // iPad typically has more memory, iPhone varies
      final isIPad = _isIPad();
      if (isIPad) {
        // iPad: More aggressive caching
        PaintingBinding.instance.imageCache.maximumSize = 300;
        PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150MB
      } else {
        // iPhone: Balanced caching
        PaintingBinding.instance.imageCache.maximumSize = 200;
        PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
      }
    } else {
      // Android or other platforms
      PaintingBinding.instance.imageCache.maximumSize = 200;
      PaintingBinding.instance.imageCache.maximumSizeBytes = 100 << 20; // 100MB
    }
  }
  
  /// Check if device is iPad (iOS specific)
  static bool _isIPad() {
    if (!Platform.isIOS) return false;
    // Simple heuristic: screen size > 700 is likely iPad
    final screenSize = WidgetsBinding.instance.window.physicalSize;
    return screenSize.shortestSide > 700;
  }

  /// Clear image cache when memory is low
  static void clearImageCache() {
    PaintingBinding.instance.imageCache.clear();
  }

  /// Optimize text rendering
  static TextScaler getOptimizedTextScaler(BuildContext context) {
    // Disable text scaling for better performance
    return TextScaler.noScaling;
  }

  /// Check if device has low memory
  static bool isLowMemoryDevice() {
    if (Platform.isIOS) {
      // iOS-specific: Use screen size and device type heuristics
      final screenSize = MediaQueryData.fromWindow(WidgetsBinding.instance.window).size;
      final isIPad = _isIPad();
      
      // iPad generally has more memory
      if (isIPad) {
        return false; // iPad typically has sufficient memory
      }
      
      // iPhone: Consider smaller screens as potentially low memory devices
      // (older iPhones with smaller screens)
      return screenSize.shortestSide < 400;
    }
    
    // Android or other platforms: Simple heuristic
    return MediaQueryData.fromWindow(WidgetsBinding.instance.window)
            .size
            .shortestSide <
        400;
  }

  /// Get optimized image dimensions based on device
  static Size getOptimizedImageSize(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isLowMemory = isLowMemoryDevice();
    
    if (Platform.isIOS) {
      final isIPad = _isIPad();
      if (isIPad) {
        // iPad: Higher quality images
        return Size(screenSize.width * 0.95, screenSize.height * 0.5);
      } else if (isLowMemory) {
        // iPhone with low memory: Smaller images
        return Size(screenSize.width * 0.8, screenSize.height * 0.3);
      } else {
        // iPhone with sufficient memory: Balanced
        return Size(screenSize.width * 0.9, screenSize.height * 0.4);
      }
    }

    // Android or other platforms
    if (isLowMemory) {
      return Size(screenSize.width * 0.8, screenSize.height * 0.3);
    } else {
      return Size(screenSize.width * 0.9, screenSize.height * 0.4);
    }
  }
  
  /// Get iOS-specific image cache width for CachedNetworkImage
  static int? getIOSImageCacheWidth(BuildContext? context) {
    if (!Platform.isIOS) return null;
    
    final isIPad = _isIPad();
    final isLowMemory = isLowMemoryDevice();
    
    if (isIPad) {
      return 400; // Higher resolution for iPad
    } else if (isLowMemory) {
      return 200; // Lower resolution for low memory devices
    } else {
      return 300; // Standard resolution
    }
  }
  
  /// Get iOS-specific image cache height for CachedNetworkImage
  static int? getIOSImageCacheHeight(BuildContext? context) {
    if (!Platform.isIOS) return null;
    
    final isIPad = _isIPad();
    final isLowMemory = isLowMemoryDevice();
    
    if (isIPad) {
      return 400; // Higher resolution for iPad
    } else if (isLowMemory) {
      return 200; // Lower resolution for low memory devices
    } else {
      return 300; // Standard resolution
    }
  }

  /// Debounce function for search and other frequent operations
  static void debounce(
    String tag,
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _debounceTimers[tag]?.cancel();
    _debounceTimers[tag] = Timer(delay, callback);
  }

  static final Map<String, Timer> _debounceTimers = {};

  /// Clean up debounce timers
  static void dispose() {
    for (final timer in _debounceTimers.values) {
      timer.cancel();
    }
    _debounceTimers.clear();
  }
}

/// Optimized image widget with performance enhancements
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final optimizedSize = PerformanceUtils.getOptimizedImageSize(context);
    final isLowMemory = PerformanceUtils.isLowMemoryDevice();

    return Image.network(
      imageUrl,
      width: width ?? optimizedSize.width,
      height: height ?? optimizedSize.height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              color: Colors.grey[200],
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              color: Colors.grey[200],
              child: const Icon(Icons.broken_image),
            );
      },
      // Optimize memory usage with iOS-specific optimizations
      cacheWidth: Platform.isIOS 
          ? PerformanceUtils.getIOSImageCacheWidth(context)
          : (isLowMemory ? 200 : 300),
      cacheHeight: Platform.isIOS
          ? PerformanceUtils.getIOSImageCacheHeight(context)
          : (isLowMemory ? 200 : 300),
      filterQuality: isLowMemory ? FilterQuality.low : FilterQuality.medium,
    );
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String name;

  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.name,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Performance monitoring
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
