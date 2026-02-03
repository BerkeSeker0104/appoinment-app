import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/services/company_api_service.dart';
import '../../../data/models/branch_model.dart';
import '../../../data/models/company_type_model.dart';
import '../../widgets/location_dropdown_widget.dart';
import 'barber_detail_page.dart';

/// Full-screen Google Maps page for finding barbers (like Google Maps app)
class CustomerSearchPage extends StatefulWidget {
  final bool showBackButton;

  const CustomerSearchPage({
    super.key,
    this.showBackButton = false,
  });

  @override
  State<CustomerSearchPage> createState() => _CustomerSearchPageState();
}

class _CustomerSearchPageState extends State<CustomerSearchPage> {
  // Services
  final CompanyApiService _companyService = CompanyApiService();

  // State
  bool _isLoading = true;
  bool _isLoadingCompanyTypes = false;
  List<BranchModel> _allBarbers = [];
  List<BranchModel> _filteredBarbers = [];
  String _searchQuery = '';

  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // Map
  GoogleMapController? _mapController;
  static const LatLng _initialPosition = LatLng(41.0082, 28.9784);
  Position? _lastKnownPosition;

  // Filter states
  String? _selectedSortType;
  List<CompanyTypeModel> _companyTypes = [];
  String? _selectedCompanyTypeId;
  String? _selectedCompanyTypeName;
  int? _selectedCountryId;
  int? _selectedCityId;
  int? _selectedStateId;
  String? _selectedCountryName;
  String? _selectedCityName;
  String? _selectedStateName;
  BranchModel? _selectedBranch;

  // Debounce timer
  Timer? _searchDebounce;

  // Marker icon cache
  final Map<String, BitmapDescriptor> _markerIconCache = {};
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    // Status bar'ı şeffaf yap ve harita arkasına geçsin
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _loadCompanyTypes();
    _loadBarbers();
    _getUserLocation();
  }

  @override
  void dispose() {
    // Status bar'ı normale döndür
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadCompanyTypes() async {
    setState(() {
      _isLoadingCompanyTypes = true;
    });
    try {
      final types = await _companyService.getCompanyTypes();
      if (!mounted) return;
      setState(() {
        _companyTypes = types;
        _isLoadingCompanyTypes = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCompanyTypes = false;
      });
      // We keep silent failure; company type filter will show gracefully.
    }
  }

  /// Load barbers from API
  Future<void> _loadBarbers() async {
    await _fetchBarbersWithFilters();
  }

  Future<void> _fetchBarbersWithFilters({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final shouldSendCoordinates = _selectedSortType == 'nearest';
      final double? lat = shouldSendCoordinates
          ? (_lastKnownPosition?.latitude ?? _initialPosition.latitude)
          : null;
      final double? lng = shouldSendCoordinates
          ? (_lastKnownPosition?.longitude ?? _initialPosition.longitude)
          : null;

      final barbers = await _companyService.getCompanies(
        type: _selectedSortType,
        lat: lat,
        lng: lng,
        countryId: _selectedCountryId,
        cityId: _selectedCityId,
        stateId: _selectedStateId,
        typeId: _selectedCompanyTypeId,
        isAll: '1',
      );

      // Client-side sorting to ensure filters work correctly
      if (_selectedSortType == 'nearest' && _lastKnownPosition != null) {
        barbers.sort((a, b) {
          if (a.latitude == null || a.longitude == null) return 1;
          if (b.latitude == null || b.longitude == null) return -1;
          
          final distA = Geolocator.distanceBetween(
            _lastKnownPosition!.latitude,
            _lastKnownPosition!.longitude,
            a.latitude!,
            a.longitude!,
          );
          final distB = Geolocator.distanceBetween(
            _lastKnownPosition!.latitude,
            _lastKnownPosition!.longitude,
            b.latitude!,
            b.longitude!,
          );
          return distA.compareTo(distB);
        });
      } else if (_selectedSortType == 'maxScore') {
        barbers.sort((a, b) {
          final ratingA = a.averageRating ?? 0.0;
          final ratingB = b.averageRating ?? 0.0;
          // Sort by rating descending, then by total reviews descending
          if (ratingA != ratingB) {
            return ratingB.compareTo(ratingA);
          }
          final reviewsA = a.totalReviews ?? 0;
          final reviewsB = b.totalReviews ?? 0;
          return reviewsB.compareTo(reviewsA);
        });
      }

      if (!mounted) return;
      setState(() {
        _allBarbers = barbers;
        _filteredBarbers = _filterBarbersByQuery(_searchQuery, barbers);
        _isLoading = false;
      });
      // Always reload markers after filtering
      await _loadMarkers();
      
      // Animate camera to first result if available (for visual feedback)
      if (_filteredBarbers.isNotEmpty && 
          _filteredBarbers.first.latitude != null && 
          _filteredBarbers.first.longitude != null &&
          _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(_filteredBarbers.first.latitude!, _filteredBarbers.first.longitude!),
            14,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${AppLocalizations.of(context)!.barbersLoadError}: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<BranchModel> _filterBarbersByQuery(
    String query,
    List<BranchModel> source,
  ) {
    final lowerQuery = query.trim().toLowerCase();
    if (lowerQuery.isEmpty) {
      return List<BranchModel>.from(source);
    }

    return source.where((barber) {
      final matchesName = barber.name.toLowerCase().contains(lowerQuery);
      final matchesAddress = barber.address.toLowerCase().contains(lowerQuery);
      return matchesName || matchesAddress;
    }).toList();
  }

  Future<void> _onSortTypeSelected(String? sortValue) async {
    // Allow reselection to refresh data
    setState(() {
      _selectedSortType = sortValue;
    });
    await _fetchBarbersWithFilters(showLoader: false);
    
    // Show feedback to user
    if (mounted && _filteredBarbers.isNotEmpty) {
      String message = '';
      if (sortValue == null) {
        message = '${_filteredBarbers.length} işletme bulundu';
      } else if (sortValue == 'nearest') {
        message = '${_filteredBarbers.length} işletme yakınlığa göre sıralandı';
      } else if (sortValue == 'maxScore') {
        message = '${_filteredBarbers.length} işletme puana göre sıralandı';
      }
      
      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(milliseconds: 1500),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildSortChip(String label, String? sortValue) {
    final isSelected = _selectedSortType == sortValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        selected: isSelected,
        onSelected: (_) => _onSortTypeSelected(sortValue),
        selectedColor: AppColors.primary,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final backgroundColor = isActive ? AppColors.primary : Colors.white;
    final borderColor = isActive ? AppColors.primary : AppColors.border;
    final textColor = isActive ? Colors.white : AppColors.textPrimary;
    final iconColor = isActive ? Colors.white : AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCompanyTypeBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.7,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Kategori Seç',
                    style: AppTypography.h6.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Tümü',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: _selectedCompanyTypeId == null
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(context, {
                        'id': null,
                        'name': null,
                      });
                    },
                  ),
                  const Divider(),
                  Expanded(
                    child: _isLoadingCompanyTypes
                        ? Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary),
                            ),
                          )
                        : _companyTypes.isEmpty
                            ? Center(
                                child: Text(
                                  'Kategori bulunamadı.',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: _companyTypes.length,
                                separatorBuilder: (_, __) => const Divider(),
                                itemBuilder: (context, index) {
                                  final type = _companyTypes[index];
                                  final isSelected =
                                      _selectedCompanyTypeId == type.id;
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      type.name,
                                      style: AppTypography.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: type.description != null
                                        ? Text(
                                            type.description!,
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          )
                                        : null,
                                    trailing: isSelected
                                        ? Icon(Icons.check,
                                            color: AppColors.primary)
                                        : null,
                                    onTap: () {
                                      Navigator.pop(context, {
                                        'id': type.id,
                                        'name': type.name,
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final String? newId = result['id'] as String?;
    final String? newName = result['name'] as String?;
    if (newId == _selectedCompanyTypeId &&
        newName == _selectedCompanyTypeName) {
      return;
    }

    setState(() {
      _selectedCompanyTypeId = newId;
      _selectedCompanyTypeName = newName;
    });

    await _fetchBarbersWithFilters(showLoader: false);
  }

  Future<void> _openLocationBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        int? tempCountryId = _selectedCountryId;
        int? tempCityId = _selectedCityId;
        int? tempStateId = _selectedStateId;
        String? tempCountryName = _selectedCountryName;
        String? tempCityName = _selectedCityName;
        String? tempStateName = _selectedStateName;

        return FractionallySizedBox(
          heightFactor: 0.85,
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Lokasyon Filtrele',
                        style: AppTypography.h6.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      LocationDropdownWidget(
                        label: 'Lokasyon seçimi',
                        hint: 'Ülke, il ve ilçe seçin',
                        initialCountryId: tempCountryId,
                        initialCityId: tempCityId,
                        initialStateId: tempStateId,
                        onLocationSelected: (countryId, cityId, stateId) {
                          setModalState(() {
                            tempCountryId = countryId;
                            tempCityId = cityId;
                            tempStateId = stateId;
                          });
                        },
                        onLocationNamesSelected:
                            (countryName, cityName, stateName) {
                          tempCountryName = countryName;
                          tempCityName = cityName;
                          tempStateName = stateName;
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context, {'clear': true});
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: BorderSide(color: AppColors.border),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Temizle',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context, {
                                  'clear': false,
                                  'countryId': tempCountryId,
                                  'cityId': tempCityId,
                                  'stateId': tempStateId,
                                  'countryName': tempCountryName,
                                  'cityName': tempCityName,
                                  'stateName': tempStateName,
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Text(
                                'Uygula',
                                style: AppTypography.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (result == null) return;

    if (result['clear'] == true) {
      if (_selectedCountryId == null &&
          _selectedCityId == null &&
          _selectedStateId == null) {
        return;
      }
      setState(() {
        _selectedCountryId = null;
        _selectedCityId = null;
        _selectedStateId = null;
        _selectedCountryName = null;
        _selectedCityName = null;
        _selectedStateName = null;
      });
      await _fetchBarbersWithFilters(showLoader: false);
      return;
    }

    final int? newCountryId = result['countryId'] as int?;
    final int? newCityId = result['cityId'] as int?;
    final int? newStateId = result['stateId'] as int?;
    final String? newCountryName = result['countryName'] as String?;
    final String? newCityName = result['cityName'] as String?;
    final String? newStateName = result['stateName'] as String?;

    final bool hasChanged = newCountryId != _selectedCountryId ||
        newCityId != _selectedCityId ||
        newStateId != _selectedStateId;

    if (!hasChanged) return;

    setState(() {
      _selectedCountryId = newCountryId;
      _selectedCityId = newCityId;
      _selectedStateId = newStateId;
      _selectedCountryName = newCountryName;
      _selectedCityName = newCityName;
      _selectedStateName = newStateName;
    });

    await _fetchBarbersWithFilters(showLoader: false);
  }

  String _getCompanyTypeLabel() {
    if (_selectedCompanyTypeName != null &&
        _selectedCompanyTypeName!.isNotEmpty) {
      return 'Kategori: ${_selectedCompanyTypeName!}';
    }
    return 'Kategori';
  }

  String _getLocationLabel() {
    if (_selectedStateName != null && _selectedStateName!.isNotEmpty) {
      return 'Lokasyon: ${_selectedStateName!}';
    }
    if (_selectedCityName != null && _selectedCityName!.isNotEmpty) {
      return 'Lokasyon: ${_selectedCityName!}';
    }
    if (_selectedCountryName != null && _selectedCountryName!.isNotEmpty) {
      return 'Lokasyon: ${_selectedCountryName!}';
    }
    return 'Lokasyon';
  }

  /// Get user's current location
  Future<void> _getUserLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _lastKnownPosition = position;
        });
        if (_selectedSortType == 'nearest') {
          await _fetchBarbersWithFilters(showLoader: false);
        }
      }
    } catch (e) {}
  }

  /// Debounced search function
  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      setState(() {
        _searchQuery = query;
        _filteredBarbers = _filterBarbersByQuery(_searchQuery, _allBarbers);
      });
      // Update markers when search changes
      await _loadMarkers();
    });
  }

  /// Handle keyboard search action
  void _onSearchSubmitted(String query) {
    setState(() {
      _searchQuery = query;
      _filteredBarbers = _filterBarbersByQuery(_searchQuery, _allBarbers);
    });
    _searchFocusNode.unfocus();
  }

  /// Check if barber is currently open based on working hours
  bool _isOpen(BranchModel barber) {
    final hours = barber.workingHours;
    // 7/24 açık kontrolü
    final alwaysOpen = hours['all']?.toLowerCase().contains('7/24') == true;
    if (alwaysOpen) return true;

    // Günlük saatleri kontrol et
    final now = DateTime.now();
    final weekdayToKey = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];
    final key = weekdayToKey[now.weekday - 1];
    final value = hours[key]?.toLowerCase() ?? '';
    if (value.isEmpty) return false;
    if (value.contains('kapalı')) return false;

    // "09:00 - 18:00" veya "09:00:00 - 18:00:00" formatını parse et
    final parts = value.split('-');
    if (parts.length < 2) return false;
    final openStr = _normalizeTimeString(parts[0].trim());
    final closeStr = _normalizeTimeString(parts[1].trim());

    TimeOfDay? _parse(String s) {
      final p = s.split(':');
      if (p.length < 2) return null; // "09:00:00" formatını da destekle
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h == null || m == null) return null;
      return TimeOfDay(hour: h, minute: m);
    }

    final open = _parse(openStr);
    final close = _parse(closeStr);
    if (open == null || close == null) return false;

    final nowTod = TimeOfDay.fromDateTime(now);
    bool isAfterOpen = nowTod.hour > open.hour ||
        (nowTod.hour == open.hour && nowTod.minute >= open.minute);
    bool isBeforeClose = nowTod.hour < close.hour ||
        (nowTod.hour == close.hour && nowTod.minute <= close.minute);
    return isAfterOpen && isBeforeClose;
  }

  /// Zaman formatını normalize et: "09:00:00" -> "09:00"
  String _normalizeTimeString(String time) {
    if (time.isEmpty) return '09:00';
    
    // "09:00:00" veya "09:00" formatını destekle
    final parts = time.split(':');
    if (parts.length >= 2) {
      final hour = parts[0].padLeft(2, '0');
      final minute = parts[1].padLeft(2, '0');
      return '$hour:$minute';
    }
    
    return time;
  }

  /// Get mock rating for barber
  double _getMockRating(BranchModel barber) {
    // Mock implementation - return random rating between 3.5-5.0
    final hash = barber.id.hashCode;
    return 3.5 + (hash % 150) / 100.0; // 3.5 to 5.0
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _filteredBarbers = List<BranchModel>.from(_allBarbers);
    });
  }

  /// Go to user location
  void _goToUserLocation() {
    if (_lastKnownPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude),
          15,
        ),
      );
    }
  }

  /// Create custom marker icon from company profile image
  Future<BitmapDescriptor> _createCustomMarkerIcon(
    BranchModel barber,
  ) async {
    // Check cache first
    if (_markerIconCache.containsKey(barber.id)) {
      return _markerIconCache[barber.id]!;
    }

    try {
      // Use profile image or fallback to default icon
      String? imageUrl = barber.image;
      
      if (imageUrl == null || imageUrl.isEmpty) {
        // No image, use default marker with status color
        final defaultIcon = _isOpen(barber)
            ? BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen)
            : BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed);
        _markerIconCache[barber.id] = defaultIcon;
        return defaultIcon;
      }

      // Download image
      final dio = Dio();
      final response = await dio.get<Uint8List>(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      if (response.data == null) {
        throw Exception('Failed to load image');
      }

      // Decode image
      final codec = await ui.instantiateImageCodec(
        response.data!,
        targetWidth: 100, // Resize for performance
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      // Create circular marker with border
      final pictureRecorder = ui.PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      final size = 80.0;
      final borderWidth = 3.0;

      // Draw white border circle
      final borderPaint = Paint()
        ..color = _isOpen(barber) ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = borderWidth;
      canvas.drawCircle(
        Offset(size / 2, size / 2),
        size / 2 - borderWidth / 2,
        borderPaint,
      );

      // Draw image as circle
      final imagePaint = Paint();
      final path = Path()
        ..addOval(Rect.fromCircle(
          center: Offset(size / 2, size / 2),
          radius: size / 2 - borderWidth,
        ));
      canvas.clipPath(path);
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(0, 0, size, size),
        imagePaint,
      );

      // Convert to image
      final picture = pictureRecorder.endRecording();
      final markerImage = await picture.toImage(size.toInt(), size.toInt());
      final byteData = await markerImage.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) {
        throw Exception('Failed to convert image to bytes');
      }

      // Create bitmap descriptor
      final bitmapDescriptor = BitmapDescriptor.fromBytes(
        byteData.buffer.asUint8List(),
      );

      // Cache the icon
      _markerIconCache[barber.id] = bitmapDescriptor;
      return bitmapDescriptor;
    } catch (e) {
      // On error, use default marker
      final defaultIcon = _isOpen(barber)
          ? BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen)
          : BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed);
      _markerIconCache[barber.id] = defaultIcon;
      return defaultIcon;
    }
  }

  /// Load markers for map
  Future<void> _loadMarkers() async {
    final markers = await _buildAllMarkers();
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  /// Build all markers for map
  Future<Set<Marker>> _buildAllMarkers() async {
    final markers = <Marker>{};

    // User location will be handled by Google Maps myLocationEnabled

    // Add barber markers
    for (int i = 0; i < _filteredBarbers.length; i++) {
      final barber = _filteredBarbers[i];
      if (barber.latitude != null && barber.longitude != null) {
        final icon = await _createCustomMarkerIcon(barber);
        markers.add(
          Marker(
            markerId: MarkerId('barber_$i'),
            position: LatLng(barber.latitude!, barber.longitude!),
            icon: icon,
            onTap: () {
              setState(() {
                _selectedBranch = barber;
              });
              // Focus map on selected pin
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                    LatLng(barber.latitude!, barber.longitude!)),
              );
            },
          ),
        );
      }
    }

    return markers;
  }

  /// Build branch popup card
  Widget _buildBranchPopupCard(BranchModel branch) {
    final rating = _getMockRating(branch);
    final isOpen = _isOpen(branch);

    return Positioned(
      bottom: 120, // Navbar height (80) + margin (16) + extra spacing (24)
      left: 16,
      right: 16,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with close button
              Row(
                children: [
                  Expanded(
                    child: Text(
                      branch.name,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => setState(() => _selectedBranch = null),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Company profile section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company profile image
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: branch.image != null
                          ? Image.network(
                              branch.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  child: Icon(
                                    Icons.business,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(
                                Icons.business,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Company info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Address
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                branch.address,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Rating and status
                        Row(
                          children: [
                            Icon(Icons.star, size: 14, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              rating.toStringAsFixed(1),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isOpen ? Colors.green : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                                child: Text(
                                  isOpen ? AppLocalizations.of(context)!.open : AppLocalizations.of(context)!.closed,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                  ),
                                ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Services section (if available)
              if (branch.services.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context)!.services,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: branch.services.take(3).map((service) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        service,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (branch.services.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      AppLocalizations.of(context)!.plusMore(branch.services.length - 3),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BarberDetailPage(companyId: branch.id),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                        child: Text(
                        AppLocalizations.of(context)!.appointmentButton,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BarberDetailPage(companyId: branch.id),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.detailsButton,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sortOptions = <Map<String, String?>>[
      {'label': AppLocalizations.of(context)!.allFilters, 'value': null},
      {'label': AppLocalizations.of(context)!.sortNearest, 'value': 'nearest'},
      {'label': AppLocalizations.of(context)!.sortHighestRated, 'value': 'maxScore'},
    ];

    return Scaffold(
      extendBodyBehindAppBar: true, // Status bar'ın arkasına geçsin
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppLocalizations.of(context)!.mapLoading,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Full Screen Google Maps (Status bar'ın arkasına da geçsin)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _lastKnownPosition != null
                        ? LatLng(_lastKnownPosition!.latitude,
                            _lastKnownPosition!.longitude)
                        : _initialPosition,
                    zoom: 14,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    // Load markers after map is created
                    _loadMarkers();
                  },
                  markers: _markers,
                  myLocationEnabled:
                      true, // Google Maps'in orijinal konum pin'i
                  myLocationButtonEnabled: false, // Custom button kullanacağız
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  rotateGesturesEnabled: false,
                  scrollGesturesEnabled: true,
                  tiltGesturesEnabled: false,
                  zoomGesturesEnabled: true,
                  onTap: (LatLng position) {
                    // Close popup when tapping on map
                    if (_selectedBranch != null) {
                      setState(() {
                        _selectedBranch = null;
                      });
                    }
                  },
                ),

                // Back Button - Sadece showBackButton true ise göster
                if (widget.showBackButton)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.textPrimary,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),

                // Search Bar - Status bar'ın hemen altında
                Positioned(
                  top: MediaQuery.of(context).padding.top +
                      16, // Status bar'ın altında 16px boşluk
                  left: widget.showBackButton ? 72 : 20, // Geri butonu varsa daha fazla sol boşluk
                  right: 20, // Daha geniş alan, ama kenarlardan biraz boşluk
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      onChanged: _onSearchChanged,
                      onSubmitted: _onSearchSubmitted,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!
                            .searchBarberPlaceholder,
                        hintStyle: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.textSecondary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(Icons.clear,
                                    color: AppColors.textSecondary),
                                onPressed: _clearSearch,
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

                // My Location Button - Navbar'ın sağ üst köşesinde
                Positioned(
                  bottom: 200, // Company card'ın üstünde, daha fazla boşluk
                  right: 16,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _goToUserLocation,
                      icon: Icon(Icons.my_location,
                          color: AppColors.primary, size: 24),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ),

                // Search Results Overlay - Arama çubuğunun altında liste
                if (_searchQuery.isNotEmpty)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 72,
                    left: 20,
                    right: 20,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(color: AppColors.border, width: 1),
                      ),
                      constraints: const BoxConstraints(maxHeight: 260),
                      child: _filteredBarbers.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text(
                                AppLocalizations.of(context)!.noResults,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredBarbers.length > 20
                                  ? 20
                                  : _filteredBarbers.length,
                              itemBuilder: (context, index) {
                                final branch = _filteredBarbers[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(Icons.store_mall_directory,
                                      color: AppColors.primary),
                                  title: Text(
                                    branch.name,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  subtitle: Text(
                                    branch.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  onTap: () {
                                    setState(() {
                                      _selectedBranch = branch;
                                      _searchQuery = branch.name;
                                      _searchController.text = branch.name;
                                      _filteredBarbers = _filterBarbersByQuery(
                                          _searchQuery, _allBarbers);
                                    });
                                    _searchFocusNode.unfocus();

                                    if (branch.latitude != null &&
                                        branch.longitude != null) {
                                      _mapController?.animateCamera(
                                        CameraUpdate.newLatLngZoom(
                                          LatLng(branch.latitude!,
                                              branch.longitude!),
                                          16,
                                        ),
                                      );
                                    } else {
                                      // Koordinat yoksa detay sayfasına git
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              BarberDetailPage(
                                                  companyId: branch.id),
                                        ),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ),

                // Filter Chips - Arama çubuğunun altında
                Positioned(
                  top: MediaQuery.of(context).padding.top +
                      80, // Arama çubuğunun altında
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          ...sortOptions.map(
                            (option) => _buildSortChip(
                              option['label'] ?? '',
                              option['value'],
                            ),
                          ),
                          _buildFilterButton(
                            label: _getCompanyTypeLabel(),
                            icon: Icons.store_mall_directory,
                            isActive: _selectedCompanyTypeId != null,
                            onTap: _openCompanyTypeBottomSheet,
                          ),
                          _buildFilterButton(
                            label: _getLocationLabel(),
                            icon: Icons.location_on,
                            isActive: _selectedCountryId != null ||
                                _selectedCityId != null ||
                                _selectedStateId != null,
                            onTap: _openLocationBottomSheet,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Popup card (if branch selected)
                if (_selectedBranch != null)
                  _buildBranchPopupCard(_selectedBranch!),
              ],
            ),
    );
  }
}
