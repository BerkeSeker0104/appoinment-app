import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/geocoding_model.dart';

class GeocodingService {
  static const String _apiKey = "AIzaSyAnD3vjZ8lHSHzALc3OTfC2iJNmLS7eMtk";
  static const String _baseUrl =
      'https://maps.googleapis.com/maps/api/geocode/json';

  // Guards for preventing multiple simultaneous requests
  Future<GeocodingResult?>? _geocodeInFlight;
  Future<String?>? _reverseGeocodeInFlight;

  /// Adresi koordinatlara çevir (Forward Geocoding)
  Future<GeocodingResult?> geocodeAddress(String address) async {
    // Guard: Return in-flight request if one exists
    if (_geocodeInFlight != null) {
      return _geocodeInFlight;
    }

    try {
      if (address.isEmpty) return null;


      _geocodeInFlight = _performGeocode(address);
      final result = await _geocodeInFlight;
      return result;
    } catch (e) {
      return null;
    } finally {
      _geocodeInFlight = null;
    }
  }

  Future<GeocodingResult?> _performGeocode(String address) async {
    try {
      // Türkçe karakterleri encode et
      final encodedAddress = Uri.encodeComponent(address);
      final url =
          '$_baseUrl?address=$encodedAddress&key=$_apiKey&language=tr&region=tr';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        return null;
      }

      final result = GeocodingResult.fromJson(data['results'][0]);

      return result;
    } catch (e) {
      return null;
    }
  }

  /// Koordinatları adrese çevir (Reverse Geocoding)
  Future<String?> reverseGeocode(double lat, double lng) async {
    // Guard: Return in-flight request if one exists
    if (_reverseGeocodeInFlight != null) {
      return _reverseGeocodeInFlight;
    }

    try {

      _reverseGeocodeInFlight = _performReverseGeocode(lat, lng);
      final result = await _reverseGeocodeInFlight;
      return result;
    } catch (e) {
      return null;
    } finally {
      _reverseGeocodeInFlight = null;
    }
  }

  Future<String?> _performReverseGeocode(double lat, double lng) async {
    try {
      final url =
          '$_baseUrl?latlng=$lat,$lng&key=$_apiKey&language=tr&result_type=street_address';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body);

      if (data['status'] != 'OK' || data['results'].isEmpty) {
        return null;
      }

      return data['results'][0]['formatted_address'];
    } catch (e) {
      return null;
    }
  }

  /// Adresi bias ile geocode et (il/ilçe bilgileri ile)
  Future<GeocodingResult?> geocodeWithBias(
    String address, {
    String? countryCode,
    String? cityName,
    String? districtName,
  }) async {
    try {
      // Bias adresini oluştur
      final biasParts = <String>[];
      if (districtName != null && districtName.isNotEmpty) {
        biasParts.add(districtName);
      }
      if (cityName != null && cityName.isNotEmpty) {
        biasParts.add(cityName);
      }
      if (countryCode != null && countryCode.isNotEmpty) {
        biasParts.add(countryCode);
      }

      if (biasParts.isEmpty) {
        return geocodeAddress(address);
      }

      // Bias adresini oluştur
      final biasAddress = '${address.trim()}, ${biasParts.join(', ')}';


      return geocodeAddress(biasAddress);
    } catch (e) {
      // Fallback: bias olmadan geocode et
      return geocodeAddress(address);
    }
  }
}
