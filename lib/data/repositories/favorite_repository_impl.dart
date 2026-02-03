import '../../domain/entities/favorite.dart';
import '../../domain/repositories/favorite_repository.dart';
import '../services/favorite_api_service.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final FavoriteApiService _apiService = FavoriteApiService();

  @override
  Future<Map<String, dynamic>> toggleFavorite(String companyId) async {
    return await _apiService.toggleFavorite(companyId);
  }

  @override
  Future<List<Favorite>> getFavorites() async {
    final favorites = await _apiService.getFavoritesList();

    // Convert FavoriteModel to Favorite entity
    return favorites
        .map((model) => Favorite(
              userId: model.userId,
              companyId: model.companyId,
              company: model.company,
              createdAt: model.createdAt,
              updatedAt: model.updatedAt,
            ))
        .toList();
  }
}
