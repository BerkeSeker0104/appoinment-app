import 'package:flutter/material.dart';
import '../../data/models/company_follower_model.dart';
import '../../data/models/branch_model.dart';
import '../../data/services/company_follower_api_service.dart';
import '../../core/services/app_lifecycle_service.dart';

class CompanyFollowerProvider extends ChangeNotifier implements LoadingStateResettable {
  final CompanyFollowerApiService _apiService = CompanyFollowerApiService();

  // For Company View
  List<CompanyFollowerModel> _companyFollowers = [];
  bool _isLoadingFollowers = false;
  
  // For Customer View (Following List)
  List<BranchModel> _followingList = [];
  Set<String> _followingCompanyIds = {}; // For quick lookup
  bool _isLoadingFollowing = false;
  
  // Follower Counts (CompanyId -> Count)
  final Map<String, int> _followerCounts = {};
  bool _isLoadingCounts = false;

  String? _errorMessage;

  // Getters
  List<CompanyFollowerModel> get companyFollowers => _companyFollowers;
  bool get isLoadingFollowers => _isLoadingFollowers;
  
  List<BranchModel> get followingList => _followingList; // The actual company/branch objects
  Set<String> get followingCompanyIds => _followingCompanyIds;
  bool get isLoadingFollowing => _isLoadingFollowing;
  
  String? get errorMessage => _errorMessage;

  // Check if following a specific company
  bool isFollowing(String companyId) {
    return _followingCompanyIds.contains(companyId);
  }
  
  // Get follower count for a company
  int getFollowerCount(String companyId) {
    return _followerCounts[companyId] ?? 0;
  }

  // Set follower count manually (useful when initializing from details page)
  void setFollowerCount(String companyId, int count) {
    _followerCounts[companyId] = count;
    notifyListeners();
  }

  /// Load followers for a company (Company View)
  Future<void> loadCompanyFollowers(String companyId) async {
    try {
      _isLoadingFollowers = true;
      _errorMessage = null;
      notifyListeners();

      _companyFollowers = await _apiService.getCompanyFollowers(companyId);
      
      // Update count as well
      _followerCounts[companyId] = _companyFollowers.length;
      
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoadingFollowers = false;
      notifyListeners();
    }
  }

  /// Load companies the customer follows (Customer View)
  Future<void> loadCustomerFollowingList() async {
    try {
      _isLoadingFollowing = true;
      _errorMessage = null;
      notifyListeners();

      _followingList = await _apiService.getCustomerFollowList();
      _followingCompanyIds = _followingList.map((e) => e.id).toSet();
      
    } catch (e) {
       // Check if error is due to unauthorized (guest user)
      final errorString = e.toString().toLowerCase();
      final isUnauthorized = errorString.contains('unauthorized') || 
                            errorString.contains('401') ||
                            errorString.contains('yetkisiz');
      
      if (!isUnauthorized) {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      _isLoadingFollowing = false;
      notifyListeners();
    }
  }

  /// Toggle follow status
  Future<bool> toggleFollow(String companyId) async {
    // Optimistic update
    final wasFollowing = _followingCompanyIds.contains(companyId);
    final currentCount = _followerCounts[companyId] ?? 0;

    if (wasFollowing) {
      _followingCompanyIds.remove(companyId);
      _followingList.removeWhere((e) => e.id == companyId);
      _followerCounts[companyId] = (currentCount - 1).clamp(0, 999999);
    } else {
      _followingCompanyIds.add(companyId);
      // We can't easily add to _followingList here as we don't have the full branch object yet
      // But we can assume the UI calling this has it, or we reload the list later.
      _followerCounts[companyId] = currentCount + 1;
    }
    notifyListeners();

    try {
      // API Call
      await _apiService.toggleFollow(companyId);
      
      // Success - maybe reload the list to be sure, or just trust the optimism if we want speed
      // If we added, we verify by reloading list to get full object if needed? 
      // Actually, if we are on BarberDetail, we know the object.
      // For now, let's just stick to optimistic.
      
      return !wasFollowing;
    } catch (e) {
      // Revert on failure
      if (wasFollowing) {
        _followingCompanyIds.add(companyId);
        // Can't easily restore the object to list without reloading or storing it. 
        // If we removed it, we might need to reload list.
        loadCustomerFollowingList(); 
        _followerCounts[companyId] = currentCount;
      } else {
        _followingCompanyIds.remove(companyId);
        _followerCounts[companyId] = currentCount;
      }
      notifyListeners();
      
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      rethrow;
    }
  }
  
  /// Load just the count and status if needed (e.g. valid when opening a page)
  Future<void> refreshCompanyStatus(String companyId) async {
     // We can just call loadCompanyFollowers if we are the company.
     // But as a customer, we want to know A) Am I following? B) Total Count.
     // The API `getCompanyFollowers` lets us see the count.
     // But `isFollowing` status comes from `loadCustomerFollowingList`.
     // This seems a bit heavy to load ALL following just to check one.
     // But given the API design, that's what we have. 
     // Potentially the `loadCustomerFollowingList` should be called once on app start / profile load.
     
     // Let's assume we call this when entering the page to ensure we have fresh count.
     try {
       final followers = await _apiService.getCompanyFollowers(companyId);
       _followerCounts[companyId] = followers.length;
       notifyListeners();
     } catch (_) {}
  }

  @override
  void resetLoadingState() {
    _isLoadingFollowing = false;
    _isLoadingFollowers = false;
    _isLoadingCounts = false;
    notifyListeners();
  }
  
   void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
