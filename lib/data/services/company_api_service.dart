import 'dart:convert';
import 'dart:math' show pi, sin, cos, sqrt, atan2;
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/company_type_model.dart';
import '../models/branch_model.dart';
import 'comment_api_service.dart';

class CompanyApiService {
  final ApiClient _apiClient = ApiClient();
  final CommentApiService _commentApiService = CommentApiService();

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  // Get Company Types
  Future<List<CompanyTypeModel>> getCompanyTypes() async {
    // Farklı endpoint'leri deneyelim
    final endpoints = [
      ApiConstants.companyTypes,
      ApiConstants.companyTypesAlt,
      ApiConstants.companyTypesAlt2,
    ];

    for (String endpoint in endpoints) {
      try {
        final response = await _apiClient.get(endpoint);

        final data = _asMap(response.data);

        // Admin panelden gelen veri yapısına göre parsing
        List<dynamic> companyTypesList = [];

        if (data['data'] is List) {
          companyTypesList = data['data'] as List<dynamic>;
        } else if (data['companyTypes'] is List) {
          companyTypesList = data['companyTypes'] as List<dynamic>;
        } else if (data['items'] is List) {
          companyTypesList = data['items'] as List<dynamic>;
        } else if (data is List) {
          companyTypesList = data as List<dynamic>;
        }

        if (companyTypesList.isNotEmpty) {
          return companyTypesList
              .map((json) => CompanyTypeModel.fromJson(json))
              .toList();
        }
      } catch (e) {
        // Son endpoint ise hata fırlat
        if (endpoint == endpoints.last) {
          rethrow;
        }
        // Diğer endpoint'leri dene
        continue;
      }
    }

    // Hiçbir endpoint çalışmazsa boş liste döndür
    return [];
  }

  // Get all companies/branches with optional backend filters
  Future<List<BranchModel>> getCompanies({
    String? type,
    double? lat,
    double? lng,
    bool? companyIsActive,
    int? countryId,
    int? cityId,
    int? stateId,
    String? typeId,
    String? isAll,
  }) async {
    try {
      final queryParameters = <String, dynamic>{};

      if (type != null && type.isNotEmpty) {
        queryParameters['type'] = type;
      }
      if (lat != null) {
        queryParameters['lat'] = lat.toString();
      }
      if (lng != null) {
        queryParameters['lng'] = lng.toString();
      }
      if (companyIsActive != null) {
        queryParameters['companyIsActive'] = companyIsActive ? '1' : '0';
      }
      if (countryId != null) {
        queryParameters['countryId'] = countryId.toString();
      }
      if (cityId != null) {
        queryParameters['cityId'] = cityId.toString();
      }
      if (stateId != null) {
        queryParameters['stateId'] = stateId.toString();
      }
      if (typeId != null && typeId.isNotEmpty) {
        queryParameters['typeId'] = typeId;
      }
      if (isAll != null && isAll.isNotEmpty) {
        queryParameters['isAll'] = isAll;
      }

      final response = await _apiClient.get(
        ApiConstants.branches,
        queryParameters: queryParameters.isEmpty ? null : queryParameters,
      );
      final data = _asMap(response.data);

      List<dynamic> companiesList = [];
      if (data['data'] is List) {
        companiesList = data['data'] as List<dynamic>;
      } else if (data['companies'] is List) {
        companiesList = data['companies'] as List<dynamic>;
      } else if (data['branches'] is List) {
        companiesList = data['branches'] as List<dynamic>;
      } else if (data['items'] is List) {
        companiesList = data['items'] as List<dynamic>;
      } else if (data is List) {
        companiesList = data as List<dynamic>;
      }

      final companies =
          companiesList.map((json) => BranchModel.fromJson(json)).toList();

      // Load rating stats for each company and return updated list
      return await _loadRatingStatsForCompanies(companies);
    } catch (e) {
      // If endpoint doesn't exist yet (404), return empty list
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        return [];
      }
      throw Exception('İşletmeler yüklenirken hata oluştu: $e');
    }
  }

  // Get nearby companies (client-side filtering for now)
  Future<List<BranchModel>> getNearbyCompanies(
    double userLat,
    double userLng, {
    double radiusKm = 10,
  }) async {
    try {
      // Get all companies
      final allCompanies = await getCompanies();

      // Filter companies with valid coordinates within radius
      final nearbyCompanies = allCompanies.where((company) {
        if (company.latitude == null || company.longitude == null) {
          return false;
        }

        // Calculate distance using Haversine formula
        final distance = _calculateDistance(
          userLat,
          userLng,
          company.latitude!,
          company.longitude!,
        );

        return distance <= radiusKm;
      }).toList();

      // Sort by distance (closest first)
      nearbyCompanies.sort((a, b) {
        final distanceA = _calculateDistance(
          userLat,
          userLng,
          a.latitude!,
          a.longitude!,
        );
        final distanceB = _calculateDistance(
          userLat,
          userLng,
          b.latitude!,
          b.longitude!,
        );
        return distanceA.compareTo(distanceB);
      });

      return nearbyCompanies;
    } catch (e) {
      return [];
    }
  }

  // Get top rated companies - sorted by rating (highest first)
  Future<List<BranchModel>> getTopRatedCompanies({int limit = 10}) async {
    try {
      // Get all companies with rating stats loaded
      final allCompanies = await getCompanies();

      // Sort by rating (highest first), then by review count (more reviews = better)
      allCompanies.sort((a, b) {
        final ratingA = a.averageRating ?? 0.0;
        final ratingB = b.averageRating ?? 0.0;
        final reviewsA = a.totalReviews ?? 0;
        final reviewsB = b.totalReviews ?? 0;

        // First sort by rating (descending - highest first)
        if (ratingA != ratingB) {
          return ratingB.compareTo(ratingA);
        }

        // If ratings are equal, sort by review count (descending - more reviews first)
        return reviewsB.compareTo(reviewsA);
      });

      // Return top N companies
      return allCompanies.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Get companies filtered by type
  Future<List<BranchModel>> getCompaniesByType(String typeId) async {
    try {
      try {
        final companies = await getCompanies(typeId: typeId);
        if (companies.isNotEmpty) {
          return companies;
        }
      } catch (e) {
        // Backend filtering failed, fall back to client-side filtering
      }

      // Fallback: Client-side filtering
      final allCompanies = await getCompanies();
      final filteredCompanies = allCompanies.where((company) {
        // Check if company type matches the selected type
        // Company type might be stored as ID string or type name
        return company.type.toLowerCase().contains(typeId.toLowerCase()) ||
            company.id == typeId;
      }).toList();

      return filteredCompanies;
    } catch (e) {
      return [];
    }
  }

  // Calculate distance between two coordinates (Haversine formula)
  // Returns distance in kilometers
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        (cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2));

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  // Load rating stats for companies
  Future<List<BranchModel>> _loadRatingStatsForCompanies(
      List<BranchModel> companies) async {
    final updatedCompanies = <BranchModel>[];

    // Process companies in batches to avoid overwhelming the API
    const batchSize = 5;
    for (int i = 0; i < companies.length; i += batchSize) {
      final batch = companies.skip(i).take(batchSize).toList();

      // Process batch in parallel
      final batchResults = await Future.wait(
        batch.map((company) => _loadRatingStatsForCompany(company)),
      );

      updatedCompanies.addAll(batchResults);
    }

    return updatedCompanies;
  }

  // Load rating stats for a single company
  Future<BranchModel> _loadRatingStatsForCompany(BranchModel company) async {
    try {
      final stats = await _commentApiService.getCompanyRatingStats(
        companyId: company.id,
      );

      // Update the company's rating stats
      final updatedCompany = company.copyWith(
        averageRating: stats['averageRating'] as double? ?? 3.0,
        totalReviews: stats['totalReviews'] as int? ?? 0,
      );

      return updatedCompany;
    } catch (e) {
      // Return company with default values (3.0, 0)
      return company.copyWith(
        averageRating: 3.0,
        totalReviews: 0,
      );
    }
  }

  // Update picture order
  Future<void> updatePictureOrder(int pictureId, int newOrder) async {
    try {
      final endpoint = '${ApiConstants.companyPictureOrder}/$pictureId';
      await _apiClient.put(
        endpoint,
        data: {'newOrder': newOrder},
      );
    } catch (e) {
      throw Exception('Görsel sırası güncellenirken hata oluştu: $e');
    }
  }

  // Delete picture
  Future<void> deletePicture(int pictureId) async {
    try {
      final endpoint = '${ApiConstants.companyPictureDelete}/$pictureId';
      await _apiClient.delete(endpoint);
    } catch (e) {
      throw Exception('Görsel silinirken hata oluştu: $e');
    }
  }

  // Get company/branch by ID
  Future<BranchModel> getCompanyById(String companyId) async {
    try {
      final response =
          await _apiClient.get('${ApiConstants.branches}/$companyId');
      final data = _asMap(response.data);

      Map<String, dynamic> companyData;
      if (data['data'] is Map<String, dynamic>) {
        companyData = data['data'];
      } else if (data['company'] is Map<String, dynamic>) {
        companyData = data['company'];
      } else if (data['branch'] is Map<String, dynamic>) {
        companyData = data['branch'];
      } else {
        companyData = data;
      }

      final company = BranchModel.fromJson(companyData);
      
      // Load rating stats for the company
      return await _loadRatingStatsForCompany(company);
    } catch (e) {
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('404') || errorString.contains('bulunamadı')) {
        throw Exception('Şube bulunamadı');
      }
      throw Exception('Şube bilgileri yüklenirken hata oluştu: $e');
    }
  }

  // Get raw branch data (for accessing pictures array with order)
  Future<Map<String, dynamic>> getRawBranchData(String branchId) async {
    try {
      final response =
          await _apiClient.get('${ApiConstants.branches}/$branchId');
      final data = _asMap(response.data);

      if (data['data'] is Map<String, dynamic>) {
        return data['data'];
      }
      return data;
    } catch (e) {
      throw Exception('Şube verisi alınırken hata oluştu: $e');
    }
  }
}
