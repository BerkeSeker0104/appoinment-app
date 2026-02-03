import 'package:flutter/material.dart';
import '../../domain/entities/favorite.dart';
import '../../domain/usecases/favorite_usecases.dart';
import '../../data/repositories/favorite_repository_impl.dart';
import '../../data/models/branch_model.dart';
import '../../data/services/comment_api_service.dart';
import '../../core/services/app_lifecycle_service.dart';

class FavoriteProvider extends ChangeNotifier implements LoadingStateResettable {
  final FavoriteUseCases _useCases = FavoriteUseCases(FavoriteRepositoryImpl());
  final CommentApiService _commentApiService = CommentApiService();

  List<Favorite> _favorites = [];
  Set<String> _favoriteCompanyIds = {};
  bool _isLoading = false;
  String? _errorMessage;
  // Map to store ratings for each company (companyId -> rating)
  final Map<String, double> _companyRatings = {};

  List<Favorite> get favorites => _favorites;
  Set<String> get favoriteCompanyIds => _favoriteCompanyIds;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Get companies from favorites
  List<BranchModel> get favoriteCompanies {
    return _favorites
        .where((fav) => fav.company != null)
        .map((fav) => fav.company!)
        .toList();
  }

  /// Get rating for a company (from cache or calculate)
  double getCompanyRating(String companyId) {
    return _companyRatings[companyId] ?? 0.0;
  }

  /// Load favorites from server
  Future<void> loadFavorites() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      _favorites = await _useCases.getFavorites();
      _favoriteCompanyIds = _favorites.map((fav) => fav.companyId).toSet();

      // Load ratings for all companies in parallel
      await _loadRatingsForFavorites();

      _errorMessage = null;
    } catch (e) {
      // Check if error is due to unauthorized (guest user)
      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') || 
                            errorString.contains('401') ||
                            errorString.contains('yetkisiz');
      
      // Don't set error message for guest users - overlay will handle it
      if (!isUnauthorized) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      } else {
        _errorMessage = null;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load ratings for all favorite companies using the same calculation as detail page
  Future<void> _loadRatingsForFavorites() async {
    _companyRatings.clear();
    
    // Get all company IDs from favorites
    final companyIds = _favorites
        .where((fav) => fav.company != null)
        .map((fav) => fav.companyId)
        .toList();

    // Load ratings in parallel for better performance
    final futures = companyIds.map((companyId) async {
      try {
        final stats = await _commentApiService.getCompanyRatingStats(
          companyId: companyId,
        );
        return MapEntry(companyId, stats['averageRating'] as double? ?? 0.0);
      } catch (e) {
        // If rating load fails, use 0.0 as default
        return MapEntry(companyId, 0.0);
      }
    });

    final results = await Future.wait(futures);
    for (final entry in results) {
      _companyRatings[entry.key] = entry.value;
    }
  }

  /// Toggle favorite status for a company
  /// Uses optimistic update - updates UI immediately, reverts if fails
  Future<bool> toggleFavorite(String companyId) async {
    // Optimistic update
    final wasInFavorites = _favoriteCompanyIds.contains(companyId);

    if (wasInFavorites) {
      _favoriteCompanyIds.remove(companyId);
      _favorites.removeWhere((fav) => fav.companyId == companyId);
    } else {
      _favoriteCompanyIds.add(companyId);
    }
    notifyListeners();

    try {
      final isFavorite = await _useCases.toggleFavorite(companyId);

      // Verify the result matches our optimistic update
      if (isFavorite != !wasInFavorites) {
        // Revert if server state doesn't match
        if (wasInFavorites) {
          _favoriteCompanyIds.add(companyId);
        } else {
          _favoriteCompanyIds.remove(companyId);
          _favorites.removeWhere((fav) => fav.companyId == companyId);
        }
        notifyListeners();
      } else {
        // Refresh the full list to get complete data
        await loadFavorites();
      }

      return isFavorite;
    } catch (e) {
      // Revert optimistic update on error
      if (wasInFavorites) {
        _favoriteCompanyIds.add(companyId);
      } else {
        _favoriteCompanyIds.remove(companyId);
        _favorites.removeWhere((fav) => fav.companyId == companyId);
      }
      notifyListeners();

      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }

  /// Check if a company is in favorites
  bool isFavorite(String companyId) {
    return _favoriteCompanyIds.contains(companyId);
  }

  /// Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Force refresh favorites with retry logic
  Future<void> refreshFavorites() async {
    await loadFavorites();
  }

  /// Reset loading states - called when app resumes from background
  @override
  void resetLoadingState() {
    if (_isLoading) {
      _isLoading = false;
      notifyListeners();
    }
  }
}
