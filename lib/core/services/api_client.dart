import 'dart:async';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'token_storage.dart';
import 'error_parser.dart';
import '../constants/api_constants.dart';
import '../../data/repositories/auth_repository_impl.dart';

/// ApiClient - Singleton HTTP client with token management
/// 
/// Features:
/// - Automatic token refresh on 401
/// - Cookie management
/// - Request cancellation
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  Dio? _dio;
  bool _isInitialized = false;
  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;
  final TokenStorage _tokenStorage = TokenStorage();
  PersistCookieJar? _cookieJar;
  final List<CancelToken> _activeCancelTokens = [];
  
  /// Public endpoints that don't require authentication
  /// These endpoints should NOT send Authorization header
  /// and should NOT attempt token refresh on 401
  static const List<String> _publicEndpoints = [
    '/api/customer-register',
    '/api/company-register',
    '/api/login',
    '/api/google-register',
    '/api/apple-register',
    '/api/google-mobile-register',
    '/api/apple-mobile-register',
    '/api/sms-send',
    '/api/sms-check',
    '/api/forgot-password/request',
    '/api/forgot-password/verify',
    '/api/forgot-password/reset',
    // '/api/auth/refresh', // Authenticated endpoint to send current token
  ];
  
  /// Check if a path is a public endpoint
  bool _isPublicEndpoint(String path) {
    return _publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  Future<void> initialize() async {
    if (_isInitialized && _dio != null) return;

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: ApiConstants.defaultHeaders,
        ),
      );
      dio.options.extra['withCredentials'] = true;

      await _tokenStorage.initialize();

      final appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = '${appDocDir.path}/.cookies/';
      _cookieJar = PersistCookieJar(
        ignoreExpires: true,
        storage: FileStorage(cookiePath),
      );
      dio.interceptors.add(CookieManager(_cookieJar!));
      dio.interceptors.add(_createAuthInterceptor());

      _dio = dio;
      _isInitialized = true;
      
      if (kDebugMode) {
        debugPrint('ApiClient: Initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiClient: Init error: $e');
      }
    }
  }

  Future<Dio> _getDio() async {
    if (_dio == null) {
      await initialize();
    }
    if (_dio == null) {
      throw Exception('Network client not available');
    }
    return _dio!;
  }

  /// Create auth interceptor with token refresh logic
  Interceptor _createAuthInterceptor() {
    return QueuedInterceptorsWrapper(
      onRequest: (options, handler) async {
        // Always add Accept-Language
        options.headers['Accept-Language'] = 'tr';
        
        final path = options.path;
        
        // Don't add Authorization header for public endpoints
        // These endpoints don't require authentication
        if (_isPublicEndpoint(path)) {
          if (kDebugMode) {
            debugPrint('ApiClient: Skipping auth for public endpoint: $path');
          }
          handler.next(options);
          return;
        }
        
        // Add auth token to authenticated requests
        final token = await getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        // Only handle 401 errors
        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }
        
        final path = error.requestOptions.path;
        
        // Don't retry public endpoints - they don't need token refresh
        // Just pass through the error (e.g., wrong credentials for login)
        if (_isPublicEndpoint(path)) {
          if (kDebugMode) {
            debugPrint('ApiClient: Skipping token refresh for public endpoint 401: $path');
          }
          return handler.next(error);
        }
        
        // Don't retry if we're already refreshing
        if (_isRefreshing) {
          if (kDebugMode) {
            debugPrint('ApiClient: Already refreshing, skipping retry');
          }
          return handler.next(error);
        }
        
        // Try to refresh token
        // Returns: token string on success, '' on timeout/network, null on 401
        final refreshResult = await _tryRefreshToken();
        
        if (refreshResult != null && refreshResult.isNotEmpty) {
          // Got new token - retry original request
          try {
            final response = await _retryRequest(error.requestOptions, refreshResult);
            return handler.resolve(response);
          } catch (e) {
            if (kDebugMode) {
              debugPrint('ApiClient: Retry failed: $e');
            }
          }
        } else if (refreshResult == null) {
          // null = refresh endpoint returned 401, session truly expired
          await _handleSessionExpired();
        }
        // else refreshResult == '' means timeout/network error - don't expire session
        // Just pass through the original error
        
        handler.next(error);
      },
    );
  }

  /// Try to refresh the token
  /// Returns: token string on success, empty string on timeout/network error, null on 401/auth failure
  Future<String?> _tryRefreshToken() async {
    // If refresh is already in progress, wait for it to complete
    if (_isRefreshing && _refreshCompleter != null) {
      if (kDebugMode) {
        debugPrint('ApiClient: Refresh in progress, waiting for completion...');
      }
      try {
        return await _refreshCompleter!.future;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ApiClient: Waiting for refresh failed: $e');
        }
        return '';
      }
    }
    
    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();
    
    try {
      if (kDebugMode) {
        debugPrint('ApiClient: Attempting token refresh (dedicated instance)');
      }
      
      // Get current token to send with refresh request
      final token = await getToken();
      
      // Use a dedicated Dio instance to avoid interceptor deadlocks
      // This is critical because the main _dio instance is locked by the 
      // QueuedInterceptorsWrapper while processing the 401 error.
      final tokenDio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          ...ApiConstants.defaultHeaders,
          'Accept-Language': 'tr',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
      ));

      // Add cookie manager to share session cookies
      if (_cookieJar != null) {
        tokenDio.interceptors.add(CookieManager(_cookieJar!));
      }
      
      final response = await tokenDio.post(
        ApiConstants.refreshToken,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        String? newToken;
        
        if (data is Map<String, dynamic>) {
          final dataNode = data['data'] as Map<String, dynamic>?;
          newToken = data['token'] ?? 
                     data['access_token'] ?? 
                     dataNode?['token'] ?? 
                     dataNode?['access_token'];
        }

        if (newToken != null && newToken.isNotEmpty) {
          await saveToken(newToken);
          if (kDebugMode) {
            debugPrint('ApiClient: Token refreshed successfully');
          }
          _refreshCompleter!.complete(newToken);
          return newToken;
        }
      }
      
      if (kDebugMode) {
        debugPrint('ApiClient: Token refresh response invalid');
      }
      _refreshCompleter?.complete('');
      return '';  // Empty string = network/parse error, don't expire session
      
    } on DioException catch (e) {
      // Only return null (trigger session expire) for actual 401 from refresh endpoint
      if (e.response?.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('ApiClient: Refresh endpoint returned 401 - session truly expired');
        }
        _refreshCompleter?.complete(null);
        return null;  // null = session expired, trigger logout
      }
      if (kDebugMode) {
        debugPrint('ApiClient: Token refresh network error: $e');
      }
      _refreshCompleter?.complete('');
      return '';  // Empty string = network error, don't expire session
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ApiClient: Token refresh error: $e');
      }
      _refreshCompleter?.complete('');
      return '';  // Empty string = timeout/other error, don't expire session
    } finally {
      _isRefreshing = false;
      // Clear completer after a short delay to allow queued requests to complete
      Future.delayed(const Duration(milliseconds: 100), () {
        _refreshCompleter = null;
      });
    }
  }

  /// Retry a request with new token
  Future<Response> _retryRequest(RequestOptions opts, String token) async {
    opts.headers['Authorization'] = 'Bearer $token';
    opts.headers['Accept-Language'] = 'tr';
    
    return await _dio!.request(
      opts.path,
      options: Options(
        method: opts.method,
        headers: opts.headers,
        responseType: opts.responseType,
        contentType: opts.contentType,
      ),
      data: opts.data,
      queryParameters: opts.queryParameters,
    );
  }

  /// Handle session expiration
  /// Protected by auth-in-progress flag and grace period to prevent race conditions
  Future<void> _handleSessionExpired() async {
    // Check if auth is in progress (login/register happening)
    // This prevents clearing tokens while Apple/Google sign-in response is pending
    if (AuthRepositoryImpl.isAuthInProgress) {
      if (kDebugMode) {
        debugPrint('ApiClient: Skipping session expiration - auth in progress');
      }
      return;
    }
    
    // Check grace period - don't clear tokens right after a successful login
    // This prevents race conditions where pending API calls trigger token clear
    final authRepo = AuthRepositoryImpl();
    if (authRepo.isWithinGracePeriod()) {
      if (kDebugMode) {
        debugPrint('ApiClient: Skipping session expiration - within grace period');
      }
      return;
    }
    
    if (kDebugMode) {
      debugPrint('ApiClient: Session expired - clearing tokens');
    }
    await clearTokens();
    _tokenStorage.clearUserData();
    authRepo.handleTokenExpiration();
  }

  void cancelAllRequests() {
    for (final token in _activeCancelTokens) {
      if (!token.isCancelled) {
        token.cancel('Request cancelled');
      }
    }
    _activeCancelTokens.clear();
  }

  /// Execute a request with automatic retry on timeout/network errors
  /// Retries up to maxAttempts (default 2) with exponential backoff
  Future<T> executeWithRetry<T>(
    Future<T> Function() request, {
    int maxAttempts = 2,
    Duration initialDelay = const Duration(milliseconds: 500),
  }) async {
    int attempt = 0;
    Duration delay = initialDelay;

    while (true) {
      attempt++;
      try {
        return await request();
      } on DioException catch (e) {
        final isTimeout = e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.sendTimeout;
        
        final isNetworkError = e.type == DioExceptionType.connectionError ||
            e.type == DioExceptionType.unknown;

        // Only retry on timeout or network errors, not on 4xx/5xx responses
        final shouldRetry = (isTimeout || isNetworkError) && attempt < maxAttempts;

        if (!shouldRetry) {
          rethrow;
        }

        if (kDebugMode) {
          debugPrint('ApiClient: Request failed (attempt $attempt/$maxAttempts), retrying in ${delay.inMilliseconds}ms...');
        }

        await Future.delayed(delay);
        delay *= 2; // Exponential backoff
      } catch (e) {
        // Don't retry on non-Dio exceptions
        rethrow;
      }
    }
  }

  // HTTP Methods
  Future<Response> get(String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    if (cancelToken == null) _activeCancelTokens.add(token);
    
    try {
      final dio = await _getDio();
      final response = await dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      _activeCancelTokens.remove(token);
      return response;
    } on DioException catch (e) {
      _activeCancelTokens.remove(token);
      throw _handleDioError(e);
    }
  }

  Future<Response> post(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    if (cancelToken == null) _activeCancelTokens.add(token);
    
    try {
      final dio = await _getDio();
      final response = await dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      _activeCancelTokens.remove(token);
      return response;
    } on DioException catch (e) {
      _activeCancelTokens.remove(token);
      throw _handleDioError(e);
    }
  }

  Future<Response> put(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    if (cancelToken == null) _activeCancelTokens.add(token);
    
    try {
      final dio = await _getDio();
      final response = await dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      _activeCancelTokens.remove(token);
      return response;
    } on DioException catch (e) {
      _activeCancelTokens.remove(token);
      throw _handleDioError(e);
    }
  }

  Future<Response> delete(String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    if (cancelToken == null) _activeCancelTokens.add(token);
    
    try {
      final dio = await _getDio();
      final response = await dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      _activeCancelTokens.remove(token);
      return response;
    } on DioException catch (e) {
      _activeCancelTokens.remove(token);
      throw _handleDioError(e);
    }
  }

  Future<Response> postMultipart(String path, {
    required Map<String, dynamic> data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    final token = cancelToken ?? CancelToken();
    if (cancelToken == null) _activeCancelTokens.add(token);
    
    try {
      final formData = FormData.fromMap(data);
      final dio = await _getDio();
      final response = await dio.post(
        path,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: token,
      );
      _activeCancelTokens.remove(token);
      return response;
    } on DioException catch (e) {
      _activeCancelTokens.remove(token);
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException error) {
    return ErrorParser.parseError(error);
  }

  // Token management
  Future<void> saveToken(String token) async {
    await _tokenStorage.saveToken(token);
  }

  Future<String?> getToken() async {
    return await _tokenStorage.getToken();
  }

  Future<void> clearTokens() async {
    await _tokenStorage.clearTokens();
    await _cookieJar?.deleteAll();
  }

  Future<void> saveUserJson(String userJson) async {
    await _tokenStorage.saveUserJson(userJson);
  }

  Future<String?> getUserJson() async {
    return await _tokenStorage.getUserJson();
  }
}
