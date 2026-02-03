import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/favorite_model.dart';
import '../models/branch_model.dart';

class FavoriteApiService {
  final ApiClient _apiClient = ApiClient();

  /// Toggle favorite status for a company
  /// Returns: {status: bool, message: string, isFavorite: bool}
  Future<Map<String, dynamic>> toggleFavorite(String companyId) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.favoritesToggle,
        data: {'companyId': companyId},
      );

      final data = response.data as Map<String, dynamic>;
      return {
        'status': data['status'] ?? false,
        'message': data['message'] ?? '',
        'isFavorite': data['isFavorite'] ?? false,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Get user's favorite companies list
  Future<List<FavoriteModel>> getFavoritesList() async {
    try {
      final response = await _apiClient.get(ApiConstants.favoritesList);
      final data = response.data as Map<String, dynamic>;

      if (data['status'] == true && data['data'] is List) {
        final List<dynamic> favoritesJson = data['data'];
        final favorites = <FavoriteModel>[];

        for (var json in favoritesJson) {
          try {
            final favorite =
                FavoriteModel.fromJson(json as Map<String, dynamic>);

            // If company data is incomplete, fetch full company details
            if (favorite.company != null &&
                _isCompanyDataIncomplete(favorite.company!)) {
              try {
                final fullCompany =
                    await _fetchFullCompanyDetails(favorite.companyId);
                if (fullCompany != null) {
                  // Replace the incomplete company data with full details
                  final updatedFavorite = FavoriteModel(
                    userId: favorite.userId,
                    companyId: favorite.companyId,
                    company: fullCompany,
                    createdAt: favorite.createdAt,
                    updatedAt: favorite.updatedAt,
                  );
                  favorites.add(updatedFavorite);
                } else {
                  favorites.add(favorite);
                }
              } catch (e) {
                favorites.add(favorite);
              }
            } else {
              favorites.add(favorite);
            }
          } catch (e) {
            // Skip invalid favorites
          }
        }

        return favorites;
      }

      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Check if company data is incomplete (has placeholder/generic data)
  bool _isCompanyDataIncomplete(BranchModel company) {
    // Check for placeholder data
    final hasGenericName = company.name.toLowerCase().contains('deneme') ||
        company.name.toLowerCase().contains('test') ||
        company.name.isEmpty ||
        company.name.toLowerCase().contains('bilinmeyen') ||
        company.name.toLowerCase().contains('unknown');

    final hasGenericDescription =
        company.type.contains('Profesyonel berber hizmetleri ile 15 yıldır') ||
            company.type.contains('Tip ') ||
            company.type.contains('Type ') ||
            company.type.isEmpty ||
            company.type.toLowerCase().contains('deneme') ||
            company.type.toLowerCase().contains('test');

    final hasNoImage = company.image == null || company.image!.isEmpty;

    final hasEmptyAddress = company.address.isEmpty ||
        company.address.toLowerCase().contains('bilinmeyen') ||
        company.address.toLowerCase().contains('unknown');

    final hasEmptyPhone = company.phone.isEmpty;

    final hasEmptyEmail = company.email.isEmpty;

    final isIncomplete = hasGenericName ||
        hasGenericDescription ||
        hasNoImage ||
        hasEmptyAddress ||
        hasEmptyPhone ||
        hasEmptyEmail;

    return isIncomplete;
  }

  /// Fetch full company details from the company endpoint
  Future<BranchModel?> _fetchFullCompanyDetails(String companyId) async {
    try {
      // Try multiple endpoints to find the correct one
      final endpoints = [
        '${ApiConstants.branches}/$companyId', // /api/company/{id}
        '/api/branches/$companyId', // Alternative branch endpoint
        '/api/company/$companyId', // Direct company endpoint
      ];

      for (String endpoint in endpoints) {
        try {
          final response = await _apiClient.get(endpoint).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Company details fetch timeout for $endpoint');
            },
          );

          final data = response.data as Map<String, dynamic>;

          // Handle different response formats
          Map<String, dynamic>? companyData;
          if (data['status'] == true && data['data'] != null) {
            companyData = data['data'] as Map<String, dynamic>;
          } else if (data['data'] is Map<String, dynamic>) {
            companyData = data['data'] as Map<String, dynamic>;
          } else if (data.containsKey('id')) {
            companyData = data;
          }

          if (companyData != null) {
            final company = BranchModel.fromJson(companyData);

            // Verify the company data is actually better than what we had
            if (company.name.isNotEmpty &&
                !company.name.toLowerCase().contains('deneme') &&
                !company.name.toLowerCase().contains('test') &&
                !company.type.contains('Tip ') &&
                !company.type.contains('Deneme')) {
              return company;
            } else {
              // Continue to next endpoint
              continue;
            }
          }
        } catch (e) {
          // Continue to next endpoint
          continue;
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }
}
