import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart';
import '../models/system_config_model.dart';

class SystemApiService {
  final ApiClient _apiClient = ApiClient();

  Future<SystemConfigModel> getSystemConfig() async {
    try {
      final response = await _apiClient.get(ApiConstants.systemConfig);
      
      if (response.data != null &&
          response.data['status'] == true &&
          response.data['data'] != null) {
        return SystemConfigModel.fromJson(response.data['data']);
      }
      
      throw Exception('Sistem yapılandırması alınamadı');
    } catch (e) {
      throw Exception('Sistem yapılandırması yüklenirken hata oluştu: $e');
    }
  }
}


