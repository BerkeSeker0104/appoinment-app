import 'dart:convert';
import '../../core/services/api_client.dart';
import '../../core/constants/api_constants.dart'; // We might need to add constants if not present, but using strings for now as requested
import '../models/company_follower_model.dart';
import '../models/branch_model.dart'; // We might use BranchModel for the following list if the API returns companies
import 'branch_api_service.dart'; // Needed for fetching full company details

class CompanyFollowerApiService {
  final ApiClient _apiClient = ApiClient();
  final String _baseUrl = '/api/company-followers';

  // Toggle Follow (Add/Remove)
  // POST https://api.mandw.com.tr/api/company-followers
  Future<bool> toggleFollow(String companyId) async {
    try {
      final response = await _apiClient.post(
        _baseUrl,
        data: {
          'companyId': companyId,
        },
      );
      
      // Assuming 200/201 means success. 
      // The API description says "Add - Follow... if already following request again -> unfollow"
      // We return true if the request was successful
      return true;
    } catch (e) {
      throw Exception('Takip işlemi başarısız: $e');
    }
  }

  // Get Followers (For Company)
  // GET https://api.mandw.com.tr/api/company-followers?companyId&companyName=
  Future<List<CompanyFollowerModel>> getCompanyFollowers(String companyId) async {
    try {
      final response = await _apiClient.get(
        _baseUrl,
        queryParameters: {
          'companyId': companyId,
        },
      );

      final dynamic responseData = response.data;
      List<dynamic> list = [];
      
      if (responseData is List) {
        list = responseData;
      } else {
        final data = _asMap(responseData);
        if (data['data'] is List) {
          list = data['data'];
        }
      }

      return list.map((e) => CompanyFollowerModel.fromJson(e)).toList();
    } catch (e) {
      // If 404/Empty return empty list
      return [];
    }
  }

  // Get Follow count (Separate call if needed, or derived from getCompanyFollowers)
  // Often APIs provide a lightweight count endpoint or return it in details
  // If no specific endpoint, we get the list and count (expensive but exact)
  Future<int> getFollowerCount(String companyId) async {
    try {
      final followers = await getCompanyFollowers(companyId);
      return followers.length;
    } catch (e) {
      return 0;
    }
  }

  // Follow List get - Kendi takip ettiklerini getirir (Customer viewing companies they follow)
  // GET https://api.mandw.com.tr/api/company-followers/follow-list
  // The user request says: "Müşteri -> Takip ettiği işletmeleri görebilir"
  // API returns list of followed companies.
  // We should map this to a model. Since it's companies, it might return company details.
  Future<List<BranchModel>> getCustomerFollowList() async {
    try {
      final response = await _apiClient.get('$_baseUrl/follow-list');

      final dynamic responseData = response.data;
      print('DEBUG_FOLLOW_LIST_RAW: $responseData');
      List<dynamic> list = [];
      
      if (responseData is List) {
        list = responseData;
      } else {
        final data = _asMap(responseData);
        if (data['data'] is List) {
          list = data['data'];
        }
      }

      // Initial parsing
      final initialList = list.map((e) {
        // Handle nested company object if present
        var companyData = e['companyDetail'] ?? e['company'] ?? e;
        
        // Enhance data with image if missing (fallback to common fields)
        if (companyData is Map<String, dynamic>) {
           if (companyData['image'] == null && companyData['picture'] == null) {
             final possibleImage = companyData['logo'] ?? 
                                 companyData['profile_image'] ?? 
                                 companyData['profileImage'] ??
                                 e['companyLogo'];
                                 
             if (possibleImage != null) {
               companyData = Map<String, dynamic>.from(companyData);
               companyData['image'] = possibleImage;
             }
           }
        }

        return BranchModel.fromJson(companyData);
      }).toList();

      // Fetch full details for each company to get the image and other missing info
      // Since the list endpoint returns sparse data
      final branchApiService = BranchApiService();
      
      final detailedList = await Future.wait(initialList.map((branch) async {
        try {
          // If we already have an image, maybe we don't need to fetch?
          // But to be safe and consistent with the user request "profile appear", let's fetch.
          // However, for performance, we could skip if we had comprehensive data.
          // Given the user report, we definitely need to fetch.
          final fullDetails = await branchApiService.getBranch(branch.id);
          return fullDetails;
        } catch (e) {
          // On error, return the partial model
          print('Error fetching details for ${branch.name}: $e');
          return branch;
        }
      }));

      return detailedList;
    } catch (e) {
      print('DEBUG_FOLLOW_LIST_ERROR: $e');
      return [];
    }
  }
  
  // Helper for safe map conversion
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
}
