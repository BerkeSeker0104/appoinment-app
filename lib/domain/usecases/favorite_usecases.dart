import '../entities/favorite.dart';
import '../repositories/favorite_repository.dart';

class FavoriteUseCases {
  final FavoriteRepository _repository;

  FavoriteUseCases(this._repository);

  /// Toggle favorite status for a company
  /// Returns the new favorite status
  Future<bool> toggleFavorite(String companyId) async {
    final result = await _repository.toggleFavorite(companyId);
    return result['isFavorite'] as bool? ?? false;
  }

  /// Get all favorite companies
  Future<List<Favorite>> getFavorites() async {
    return await _repository.getFavorites();
  }

  /// Check if a company is in favorites
  Future<bool> checkIsFavorite(String companyId) async {
    final favorites = await _repository.getFavorites();
    return favorites.any((fav) => fav.companyId == companyId);
  }
}
