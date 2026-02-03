import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/services/api_client.dart';
import 'core/services/locale_service.dart';
import 'core/services/memory_manager.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/deep_link_service.dart';
import 'core/services/badge_service.dart';
import 'core/services/app_lifecycle_service.dart';
import 'core/utils/performance_utils.dart';
import 'firebase_options.dart';
import 'presentation/pages/splash/splash_screen.dart';
import 'presentation/pages/customer/barber_detail_page.dart';
import 'presentation/providers/cart_provider.dart';
import 'presentation/providers/product_provider.dart';
import 'presentation/providers/order_provider.dart';
import 'presentation/providers/favorite_provider.dart';
import 'presentation/providers/message_provider.dart';
import 'presentation/providers/company_type_provider.dart';
import 'presentation/providers/announcement_provider.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/appointment_provider.dart';
import 'presentation/providers/address_provider.dart';
import 'presentation/providers/company_follower_provider.dart';
import 'data/repositories/auth_repository_impl.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize performance optimizations
  PerformanceUtils.optimizeImageCache();
  PerformanceUtils.enablePerformanceOverlay();
  MemoryManager().initialize();

  // Global error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Initialize Firebase
  await _initializeFirebase();

  // Initialize services asynchronously
  unawaited(_initializeServicesAsync());

  runApp(BarberApp(navigatorKey: appNavigatorKey));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      debugPrint('Main: Firebase initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Main: Firebase init error: $e');
    }
  }
}

Future<void> _initializeServicesAsync() async {
  try {
    await Future.wait([
      ApiClient().initialize(),
      LocaleService().initialize(),
      PushNotificationService().initialize(),
      BadgeService().initialize(),
    ]);
    if (kDebugMode) {
      debugPrint('Main: Services initialized');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Main: Services init error: $e');
    }
  }
}

class BarberApp extends StatefulWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const BarberApp({super.key, required this.navigatorKey});

  @override
  State<BarberApp> createState() => _BarberAppState();
}

class _BarberAppState extends State<BarberApp> with WidgetsBindingObserver {
  // Track background time to decide when to validate token
  DateTime? _backgroundStartTime;
  
  // Only validate token if app was in background for more than this duration
  // iOS can kill apps in 2-3 minutes, so 1 minute threshold is more appropriate
  static const Duration _minBackgroundTimeForValidation = Duration(minutes: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    AppLifecycleService().initialize();
    
    PushNotificationService().registerNavigatorKey(widget.navigatorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PushNotificationService().processInitialMessage();
      DeepLinkService().initialize(widget.navigatorKey);
      _syncBadgeOnAppOpen();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Use switch for better iOS lifecycle coverage
    switch (state) {
      case AppLifecycleState.resumed:
        _onAppResumed();
        break;
      case AppLifecycleState.inactive:
        _onAppInactive();
        break;
      case AppLifecycleState.paused:
        _onAppPaused();
        break;
      case AppLifecycleState.detached:
        _onAppDetached();
        break;
      case AppLifecycleState.hidden:
        // Flutter 3.13+ - future-proof
        if (kDebugMode) {
          debugPrint('Main: App hidden');
        }
        break;
    }
  }

  void _onAppInactive() {
    if (kDebugMode) {
      debugPrint('Main: App inactive (iOS home button pressed)');
    }
    // iOS-specific: App is transitioning to background
    // This is called before paused on iOS
  }

  void _onAppPaused() {
    if (kDebugMode) {
      debugPrint('Main: App paused');
    }
    _backgroundStartTime = DateTime.now();
    AppLifecycleService().onAppPaused();
  }

  void _onAppDetached() {
    if (kDebugMode) {
      debugPrint('Main: App detached (app terminating)');
    }
    // App is being terminated - can't do much here
  }

  void _onAppResumed() {
    if (kDebugMode) {
      debugPrint('Main: App resumed');
    }
    
    // Let AppLifecycleService handle the resume logic and duration tracking
    AppLifecycleService().onAppResumed();
    
    // Get background duration from the service
    final backgroundDuration = AppLifecycleService().lastBackgroundDuration;
    
    // Reduced from 5 to 1 minute for iOS compatibility
    // iOS can kill apps in background after 2-3 minutes
    if (backgroundDuration != null && backgroundDuration > const Duration(minutes: 1)) {
      if (kDebugMode) {
        debugPrint('Main: Background time exceeded threshold, validating token');
      }
      _validateTokenAfterLongBackground();
    }
    
    // Refresh notification count
    _refreshNotifications();
  }

  /// Validate token only after long background period
  Future<void> _validateTokenAfterLongBackground() async {
    try {
      // Check if we're within login grace period - skip validation if user just logged in
      final authRepo = AuthRepositoryImpl();
      if (authRepo.isWithinGracePeriod()) {
        if (kDebugMode) {
          debugPrint('Main: Skipping token validation - within grace period');
        }
        return;
      }
      
      final apiClient = ApiClient();
      final token = await apiClient.getToken();
      
      // No token means user is logged out - nothing to validate
      if (token == null || token.isEmpty) {
        return;
      }
      
      // Try to validate with a simple API call with retry mechanism
      // Increased timeout from 5 to 10 seconds and attempts from 2 to 3
      // for better network resilience when resuming from background
      try {
        await apiClient.executeWithRetry(
          () => apiClient.get('/api/profile').timeout(
            const Duration(seconds: 10),  // Increased from 5 to 10
          ),
          maxAttempts: 3,  // Increased from 2 to 3
        );
        if (kDebugMode) {
          debugPrint('Main: Token still valid');
        }
      } catch (e) {
        // ApiClient interceptor handles 401 and triggers logout
        if (kDebugMode) {
          debugPrint('Main: Token validation request failed after retries: $e');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Main: Error during token validation: $e');
      }
    }
  }

  void _refreshNotifications() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widget.navigatorKey.currentContext;
      if (context != null) {
        try {
          context.read<NotificationProvider>().loadUnreadCount();
        } catch (e) {
          // Provider not available yet
        }
      }
    });
  }

  void _syncBadgeOnAppOpen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = widget.navigatorKey.currentContext;
      if (context != null) {
        try {
          final notificationProvider = context.read<NotificationProvider>();
          // Only load count on app open, don't start auto-refresh here
          // Auto-refresh will be started when user opens notifications page
          notificationProvider.loadUnreadCount();
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Main: Badge sync error: $e');
          }
        }
      }
    });
  }

  void _registerProviders(BuildContext context) {
    try {
      final lifecycleService = AppLifecycleService();
      
      final providers = <LoadingStateResettable>[
        context.read<CartProvider>(),
        context.read<ProductProvider>(),
        context.read<OrderProvider>(),
        context.read<FavoriteProvider>(),
        context.read<MessageProvider>(),
        context.read<CompanyTypeProvider>(),
        context.read<AnnouncementProvider>(),
        context.read<NotificationProvider>(),
        context.read<AppointmentProvider>(),
        context.read<AddressProvider>(),
        context.read<CompanyFollowerProvider>(),
      ];
      
      for (final provider in providers) {
        lifecycleService.registerProvider(provider);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Main: Provider registration error: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()..loadFavorites()),
        ChangeNotifierProvider(create: (_) => MessageProvider()),
        ChangeNotifierProvider(create: (_) => CompanyTypeProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => CompanyFollowerProvider()..loadCustomerFollowingList()),
        ChangeNotifierProvider(create: (_) => LocaleService()),
      ],
      child: Consumer<LocaleService>(
        builder: (context, localeService, child) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _registerProviders(context);
          });
          
          return MaterialApp(
            navigatorKey: widget.navigatorKey,
            title: 'M&W',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: localeService.currentLocale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('tr', 'TR'),
              Locale('en', 'US'),
            ],
            home: const SplashScreen(),
            onGenerateRoute: (settings) {
              if (settings.name == '/company-detail' || settings.name == '/branch-detail') {
                final branchId = settings.arguments as String?;
                if (branchId != null && branchId.isNotEmpty) {
                  return MaterialPageRoute(
                    builder: (context) => BarberDetailPage(companyId: branchId),
                    settings: settings,
                  );
                }
              }
              return null;
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: PerformanceUtils.getOptimizedTextScaler(context),
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
