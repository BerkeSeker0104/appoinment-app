class ApiConstants {
  static const String baseUrl = 'https://api.mandw.com.tr';
  static const String fileUrl =
      'https://api.mandw.com.tr'; // FILE_URL from .env

  // Auth Endpoints
  static const String customerRegister = '/api/customer-register';
  static const String companyRegister = '/api/company-register';
  static const String login = '/api/login';
  static const String googleRegister = '/api/google-register';
  static const String appleRegister = '/api/apple-register';
  static const String googleMobileRegister = '/api/google-mobile-register';
  static const String appleMobileRegister = '/api/apple-mobile-register';
  static const String logout = '/api/auth/logout';
  static const String smsSend = '/api/sms-send';
  static const String smsCheck = '/api/sms-check';
  static const String refreshToken =
      '/api/auth/refresh'; // Refresh Token Endpoint

  // Forgot Password Endpoints
  static const String forgotPasswordRequest = '/api/forgot-password/request';
  static const String forgotPasswordVerify = '/api/forgot-password/verify';
  static const String forgotPasswordReset = '/api/forgot-password/reset';

  // Company Endpoints
  static const String companyTypes =
      '/api/company-type'; // DÜZELTİLDİ: Doğru endpoint
  static const String companyTypesAlt = '/api/company-types';
  static const String companyTypesAlt2 = '/api/company-types/get';

  // Branch Endpoints (uses company endpoint)
  static const String branches =
      '/api/company'; // Main endpoint for CRUD operations

  // Branch Picture Endpoints
  static const String companyPictureOrder = '/api/company/picture/order';
  static const String companyPictureDelete = '/api/company/picture';

  // Feature Endpoints
  static const String features = '/api/extra-feature';

  // World Location Endpoints
  static const String worldCountry = '/api/world/country';
  static const String worldCities = '/api/world/cities';
  static const String worldState = '/api/world/state';
  static const String branchFeatures = '/api/branch-features';

  // Company Service Endpoints
  static const String companyServices = '/api/company-service';

  // Service Endpoints
  static const String services = '/api/service';

  // Post Endpoints
  static const String posts = '/api/post';
  static const String postLikes = '/api/post-likes';

  // Appointment Endpoints
  static const String appointments = '/api/appointment';
  static const String appointmentAvailability = '/api/appointment/availability';

  // Product Endpoints
  static const String products = '/api/product';
  static const String productBuy = '/api/product/buy';
  static const String productCategories = '/api/product/category';
  static const String productOrders = '/api/product/order';

  // System Endpoints
  static const String systemConfig = '/api/system/config';

  // Cart Endpoints (backend uses /api/basket)
  static const String cart = '/api/basket';
  static const String cartBuy = '/api/basket/buy';

  // Order Endpoints
  static const String orders = '/api/order';

  // Payment Endpoints
  static const String payment = '/api/payment';

  // Favorite Endpoints
  static const String favoritesToggle = '/api/users/favorite/toggle';
  static const String favoritesList = '/api/users/favorite/list';

  // Message Endpoints
  static const String messages = '/api/message';

  // Company Score Endpoints (Comments & Ratings)
  static const String companyScore = '/api/company-score';

  // Announcement Endpoints
  static const String announcements = '/api/announcement';

  // Notification Endpoints
  static const String notifications = '/api/notification';
  static const String notificationCount = '/api/notification/count';

  // Profile Endpoints
  static const String profile = '/api/profile';
  static const String phoneChange = '/api/phone/change/';
  static const String phoneChangeApprove = '/api/phone/change/approve';
  static const String users = '/api/users';

  // User Address Endpoints
  static const String userAddress = '/api/user-address';

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 60);
  static const Duration receiveTimeout = Duration(seconds: 90);
}
