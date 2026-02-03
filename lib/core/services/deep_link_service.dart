import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../presentation/pages/customer/barber_detail_page.dart';

/// Deep Link Service
/// Handles incoming deep links from:
/// - iOS Universal Links
/// - Android App Links
/// 
/// URL Format: https://app.mandw.com.tr/company-detail/{branchId}
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  StreamSubscription? _linkSubscription;
  bool _isInitialized = false;
  final _appLinks = AppLinks();
  GlobalKey<NavigatorState>? _navigatorKey;
  
  // Pending link to handle after app is ready
  Uri? _pendingLink;
  bool _isAppReady = false;
  
  // UUID format regex: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  
  /// Log with timestamp and context
  void _log(String message, {String? context}) {
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
    final contextStr = context != null ? '[$context] ' : '';
    // Always print deep link logs for debugging
    debugPrint('🔗 DeepLink[$timestamp] $contextStr$message');
  }

  /// Initialize deep link service
  /// Call this once in main.dart after app starts
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_isInitialized) {
      _log('Service already initialized, skipping');
      return;
    }
    
    _navigatorKey = navigatorKey;
    _isInitialized = true;
    _log('Initializing deep link service');

    // Setup link stream listener FIRST (before checking initial link)
    _log('Setting up link stream listener');
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _log('🚀 Link received while app running: $uri', context: 'STREAM');
        _handleIncomingLink(uri);
      },
      onError: (err, stackTrace) {
        _log('Error receiving link from stream: $err', context: 'ERROR');
      },
    );

    // Check for initial link (app opened via link when closed)
    try {
      _log('Checking for initial link...');
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _log('🚀 Initial link received: $uri', context: 'INIT');
        _handleIncomingLink(uri);
      } else {
        _log('No initial link found');
      }
    } catch (e) {
      _log('Failed to get initial link: $e', context: 'ERROR');
    }
    
    // Mark app as ready after a short delay to ensure navigation is ready
    Future.delayed(const Duration(milliseconds: 500), () {
      _markAppReady();
    });
  }
  
  /// Mark app as ready and process any pending links
  void _markAppReady() {
    if (_isAppReady) return;
    _isAppReady = true;
    _log('App marked as ready for navigation');
    
    // Process pending link if any
    if (_pendingLink != null) {
      _log('Processing pending link: $_pendingLink', context: 'PENDING');
      final link = _pendingLink!;
      _pendingLink = null;
      _processLink(link);
    }
  }
  
  /// Handle incoming link - either process immediately or queue for later
  void _handleIncomingLink(Uri uri) {
    _log('Handling incoming link: $uri');
    
    if (_isAppReady && _navigatorKey?.currentState != null) {
      _processLink(uri);
    } else {
      _log('App not ready, queuing link for later', context: 'QUEUE');
      _pendingLink = uri;
      
      // Also try to process after a short delay
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_pendingLink != null && _navigatorKey?.currentState != null) {
          _log('Retrying pending link after delay', context: 'RETRY');
          final link = _pendingLink!;
          _pendingLink = null;
          _processLink(link);
        }
      });
    }
  }
  
  /// Process and validate the link, then navigate
  void _processLink(Uri uri) {
    _log('Processing link: $uri', context: 'PROCESS');
    
    try {
      String? branchId;
      String linkType = 'UNKNOWN';
      
      // Check if it's a Universal Link
      // Format: https://app.mandw.com.tr/company-detail/{branchId}
      if (uri.scheme == 'https' && 
          (uri.host == 'app.mandw.com.tr' || uri.host == 'api.mandw.com.tr')) {
        
        // Validate path segments
        if (uri.pathSegments.isEmpty) {
          _log('Empty path segments', context: 'ERROR');
          return;
        }
        
        if (uri.pathSegments[0] != 'company-detail') {
          _log('Invalid path: ${uri.path}, expected /company-detail/*', context: 'ERROR');
          return;
        }
        
        if (uri.pathSegments.length < 2) {
          _log('Missing branch ID in path', context: 'ERROR');
          return;
        }
        
        branchId = uri.pathSegments[1];
        linkType = 'UNIVERSAL_LINK';
        _log('✅ Universal Link validated, branchId: $branchId', context: 'VALIDATION');
      }
      // Support custom URL schemes
      else if (uri.scheme == 'myapp' || uri.scheme == 'mandw') {
        if (uri.host != 'company-detail' || uri.pathSegments.isEmpty) {
          _log('Invalid custom scheme format', context: 'ERROR');
          return;
        }
        branchId = uri.pathSegments[0];
        linkType = 'CUSTOM_SCHEME';
        _log('✅ Custom scheme validated, branchId: $branchId', context: 'VALIDATION');
      } else {
        _log('Unsupported link format - scheme: ${uri.scheme}, host: ${uri.host}', context: 'ERROR');
        return;
      }
      
      // Validate branch ID
      if (branchId == null || branchId.isEmpty) {
        _log('Branch ID is null or empty', context: 'ERROR');
        return;
      }
      
      // UUID validation
      if (!_uuidRegex.hasMatch(branchId)) {
        _log('Invalid UUID format: $branchId', context: 'ERROR');
        return;
      }
      
      _log('🎯 Link validated - Type: $linkType, BranchId: $branchId', context: 'SUCCESS');
      _navigateToBranch(branchId);
      
    } catch (e, stackTrace) {
      _log('Error processing link: $e', context: 'ERROR');
      if (kDebugMode) {
        _log('Stack trace: $stackTrace', context: 'ERROR');
      }
    }
  }

  /// Navigate to branch detail page
  void _navigateToBranch(String branchId) {
    final navigator = _navigatorKey?.currentState;
    
    if (navigator == null) {
      _log('❌ Navigator is null, cannot navigate', context: 'ERROR');
      return;
    }
    
    _log('📱 Navigating to BarberDetailPage with branchId: $branchId', context: 'NAVIGATION');
    
    try {
      // Use push directly without any delay
      navigator.push(
        MaterialPageRoute(
          builder: (context) => BarberDetailPage(companyId: branchId),
          settings: RouteSettings(
            name: '/company-detail',
            arguments: branchId,
          ),
        ),
      ).then((_) {
        _log('✅ Navigation completed for branch: $branchId', context: 'SUCCESS');
      }).catchError((error) {
        _log('❌ Navigation error: $error', context: 'ERROR');
      });
      
      _log('Navigation push initiated', context: 'NAVIGATION');
    } catch (e) {
      _log('❌ Exception during navigation: $e', context: 'ERROR');
    }
  }

  /// Dispose service
  void dispose() {
    _log('Disposing deep link service');
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
    _isAppReady = false;
    _pendingLink = null;
    _navigatorKey = null;
  }
}
