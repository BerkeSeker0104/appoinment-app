import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple location service for getting user location and calculating distances
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _lastKnownPosition;

  /// Check if location permission is granted
  Future<bool> hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Request location permission with permission_handler
  Future<bool> requestLocationPermission() async {
    try {
      // Önce izin durumunu kontrol et
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied) {
        // İzin iste
        status = await Permission.location.request();
      }

      if (status.isPermanentlyDenied) {
        // Kalıcı red durumunda sadece false döndür, otomatik ayarlara yönlendirme
        return false;
      }

      return status.isGranted;
    } catch (e) {
      // Fallback to geolocator
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    }
  }

  /// Check if location permission is permanently denied
  Future<bool> isLocationPermissionPermanentlyDenied() async {
    try {
      final status = await Permission.location.status;
      return status.isPermanentlyDenied;
    } catch (e) {
      return false;
    }
  }

  /// Open app settings for location permission (manual action)
  Future<void> openLocationSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
    }
  }

  /// Get current location with simple error handling
  Future<Position?> getCurrentLocation({bool highAccuracy = false}) async {
    try {
      // Check if location services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await getCachedLocation();
      }

      // Check permission
      if (!await hasLocationPermission()) {
        final granted = await requestLocationPermission();
        if (!granted) return await getCachedLocation();
      }

      // Get current position
      // Using medium accuracy is faster and sufficient for nearby search
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: highAccuracy ? LocationAccuracy.high : LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      _lastKnownPosition = position;
      return position;
    } catch (e) {
      // Return last known position on error
      return await getCachedLocation();
    }
  }

  /// Get last known position from OS or memory cache
  Future<Position?> getCachedLocation() async {
    if (_lastKnownPosition != null) return _lastKnownPosition;
    try {
      if (await hasLocationPermission()) {
        _lastKnownPosition = await Geolocator.getLastKnownPosition();
      }
    } catch (_) {}
    return _lastKnownPosition;
  }


  /// Calculate distance between two coordinates in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }

  /// Get short formatted address (City, District)
  Future<String?> getShortAddress() async {
    try {
      final position = await getCurrentLocation();
      if (position == null) {
        return 'Konum bulunamadı';
      }

      // For now, return a simple placeholder
      // You can integrate with geocoding service if needed
      return 'İstanbul, Türkiye';
    } catch (e) {
      return 'Konum bulunamadı';
    }
  }

  /// Extract city and district from full address
  String extractCityAndDistrict(String fullAddress) {
    // Simple implementation - parse address parts
    final parts = fullAddress.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return fullAddress;
  }

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;
}
