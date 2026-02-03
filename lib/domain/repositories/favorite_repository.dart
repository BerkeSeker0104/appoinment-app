import '../entities/favorite.dart';

abstract class FavoriteRepository {
  Future<Map<String, dynamic>> toggleFavorite(String companyId);
  Future<List<Favorite>> getFavorites();
}
