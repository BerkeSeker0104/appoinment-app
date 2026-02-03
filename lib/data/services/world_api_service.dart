import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/world_location_model.dart';

class WorldApiService {
  final ApiClient _apiClient = ApiClient();

  /// Ülkeleri getir
  ///
  /// [search] - Arama terimi (opsiyonel)
  /// [page] - Sayfa numarası (varsayılan: 1)
  /// [dataCount] - Sayfa başına veri sayısı (varsayılan: 20)
  Future<WorldLocationResponse<CountryModel>> getCountries({
    String search = '',
    int page = 1,
    int dataCount = 20,
  }) async {
    try {
      final queryParams = {
        'search': search,
        'page': page,
        'dataCount': dataCount,
      };


      final response = await _apiClient.get(
        ApiConstants.worldCountry,
        queryParameters: queryParams,
      );


      return WorldLocationResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CountryModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Şehirleri getir
  ///
  /// [countryId] - Ülke ID'si (zorunlu)
  /// [search] - Arama terimi (opsiyonel)
  /// [page] - Sayfa numarası (varsayılan: 1)
  /// [dataCount] - Sayfa başına veri sayısı (varsayılan: 20)
  Future<WorldLocationResponse<CityModel>> getCities({
    required int countryId,
    String search = '',
    int page = 1,
    int dataCount = 20,
  }) async {
    try {
      final queryParams = {
        'countryId': countryId,
        'search': search,
        'page': page,
        'dataCount': dataCount,
      };

      final response = await _apiClient.get(
        ApiConstants.worldCities,
        queryParameters: queryParams,
      );


      return WorldLocationResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => CityModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// İlçeleri getir
  ///
  /// [cityId] - Şehir ID'si (zorunlu)
  /// [search] - Arama terimi (opsiyonel)
  /// [page] - Sayfa numarası (varsayılan: 1)
  /// [dataCount] - Sayfa başına veri sayısı (varsayılan: 20)
  Future<WorldLocationResponse<StateModel>> getStates({
    required int cityId,
    String search = '',
    int page = 1,
    int dataCount = 20,
  }) async {
    try {
      final queryParams = {
        'citiesId': cityId,
        'search': search,
        'page': page,
        'dataCount': dataCount,
      };


      final response = await _apiClient.get(
        ApiConstants.worldState,
        queryParameters: queryParams,
      );


      return WorldLocationResponse.fromJson(
        response.data as Map<String, dynamic>,
        (json) => StateModel.fromJson(json),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Tüm ülkeleri getir (pagination olmadan)
  Future<List<CountryModel>> getAllCountries() async {
    try {
      final response = await getCountries(
        dataCount: 1000,
      ); // Büyük sayı ile tüm verileri al
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Bir ülkeye ait tüm şehirleri getir (pagination olmadan)
  Future<List<CityModel>> getAllCitiesForCountry(int countryId) async {
    try {
      final response = await getCities(countryId: countryId, dataCount: 1000);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  /// Bir şehre ait tüm ilçeleri getir (pagination olmadan)
  Future<List<StateModel>> getAllStatesForCity(int cityId) async {
    try {
      final response = await getStates(cityId: cityId, dataCount: 1000);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
