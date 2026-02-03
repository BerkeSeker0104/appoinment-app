import 'package:flutter/material.dart';
import '../../data/models/announcement_model.dart';
import '../../data/services/announcement_api_service.dart';
import '../../core/services/app_lifecycle_service.dart';

class AnnouncementProvider extends ChangeNotifier implements LoadingStateResettable {
  final AnnouncementApiService _apiService = AnnouncementApiService();

  List<AnnouncementModel> _announcements = [];
  bool _isLoading = false;
  String? _error;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 10;

  List<AnnouncementModel> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  bool get hasAnnouncements => _announcements.isNotEmpty;
  int get announcementCount => _announcements.length;

  List<AnnouncementModel> get activeAnnouncements {
    return _announcements.where((announcement) => !announcement.isExpired).toList();
  }

  Future<void> loadAnnouncements({bool refresh = false}) async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;

      if (refresh) {
        _announcements.clear();
        _currentPage = 1;
        _hasMore = true;
      }

      if (!_hasMore && !refresh) return;

      final result = await _apiService.getAnnouncementsPaginated(
        page: _currentPage,
        limit: _pageSize,
      );

      final newAnnouncements = result['announcements'] as List<AnnouncementModel>;
      _hasMore = result['hasMore'] as bool;

      if (refresh) {
        _announcements = newAnnouncements;
      } else {
        _announcements.addAll(newAnnouncements);
      }

      _currentPage++;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadMoreAnnouncements() async {
    if (!_hasMore || _isLoading) return;
    await loadAnnouncements();
  }

  Future<void> refreshAnnouncements() async {
    await loadAnnouncements(refresh: true);
  }

  Future<bool> createAnnouncement({
    required String content,
    required String expiredDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.createAnnouncement(
        content: content,
        expiredDate: expiredDate,
      );

      if (success) {
        await loadAnnouncements(refresh: true);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> updateAnnouncement({
    required int id,
    required String content,
    required String expiredDate,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.updateAnnouncement(
        id: id,
        content: content,
        expiredDate: expiredDate,
      );

      if (success) {
        await loadAnnouncements(refresh: true);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  Future<bool> deleteAnnouncement(int id) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _apiService.deleteAnnouncement(id);

      if (success) {
        _announcements.removeWhere((a) => a.id == id);
      }

      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
    }
  }

  AnnouncementModel? getAnnouncementById(int id) {
    try {
      return _announcements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clear() {
    _announcements.clear();
    _isLoading = false;
    _error = null;
    _hasMore = true;
    _currentPage = 1;
    notifyListeners();
  }

  void removeExpiredAnnouncements() {
    final initialCount = _announcements.length;
    _announcements.removeWhere((announcement) => announcement.isExpired);

    if (_announcements.length != initialCount) {
      notifyListeners();
    }
  }

  List<AnnouncementModel> searchAnnouncements(String query) {
    if (query.isEmpty) return _announcements;

    final lowerQuery = query.toLowerCase();
    return _announcements.where((announcement) {
      return announcement.contentJson.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<AnnouncementModel> get sortedAnnouncements {
    final sorted = List<AnnouncementModel>.from(_announcements);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
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
