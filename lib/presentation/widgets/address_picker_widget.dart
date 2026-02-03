import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../data/services/geocoding_service.dart';

class AddressPickerWidget extends StatefulWidget {
  final String label;
  final String hint;
  final String? initialValue;
  final bool isRequired;
  final String? Function(String?)? validator;
  final Function(String, double?, double?)? onAddressSelected;
  final String? errorText;

  // YENİ: Location bias için
  final String? countryCode; // "TR"
  final String? cityName; // "İstanbul"
  final String? districtName; // "Kadıköy"
  final bool enableGeocoding; // Manuel girişte geocode et

  const AddressPickerWidget({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue,
    this.isRequired = false,
    this.validator,
    required this.onAddressSelected,
    this.errorText,
    this.countryCode,
    this.cityName,
    this.districtName,
    this.enableGeocoding = true,
  });

  @override
  State<AddressPickerWidget> createState() => _AddressPickerWidgetState();
}

class _AddressPickerWidgetState extends State<AddressPickerWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _selectedAddress;
  String? _errorMessage;
  List<Location> _searchResults = [];
  bool _isSearching = false;

  // YENİ: Geocoding için
  final GeocodingService _geocodingService = GeocodingService();
  bool _isGeocoding = false;

  /// Adres arama fonksiyonu - Geliştirilmiş geocoding ile
  Future<void> _searchAddresses(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Bias ile arama yap
      String searchQuery = query;
      if (widget.cityName != null && widget.districtName != null) {
        searchQuery = '$query, ${widget.districtName}, ${widget.cityName}';
      }

      List<Location> locations = await locationFromAddress(searchQuery);
      setState(() {
        _searchResults = locations;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  /// Adres seçimi
  void _selectAddress(Location location) async {
    String address;
    
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(location.latitude, location.longitude);

      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        List<String> addressParts = [];

        // Sokak adı
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          addressParts.add(placemark.street!);
        }

        // Mahalle/Semt
        if (placemark.subLocality != null &&
            placemark.subLocality!.isNotEmpty) {
          addressParts.add(placemark.subLocality!);
        }

        // İlçe
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }

        // İl
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }

        // Ülke
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        address = addressParts.join(', ');

        // Eğer adres boşsa Google Maps API'den reverse geocoding dene
        if (address.isEmpty) {
          final reverseGeocodedAddress =
              await _geocodingService.reverseGeocode(
            location.latitude,
            location.longitude,
          );
          if (reverseGeocodedAddress != null &&
              reverseGeocodedAddress.isNotEmpty) {
            address = reverseGeocodedAddress;
          } else {
            address = 'Konum seçildi';
          }
        }
      } else {
        // Placemark yoksa Google Maps API'den reverse geocoding dene
        final reverseGeocodedAddress =
            await _geocodingService.reverseGeocode(
          location.latitude,
          location.longitude,
        );
        if (reverseGeocodedAddress != null &&
            reverseGeocodedAddress.isNotEmpty) {
          address = reverseGeocodedAddress;
        } else {
          address = 'Konum seçildi';
        }
      }
    } catch (e) {
      // iOS'ta bazen placemark API'si çalışmayabilir, bu normaldir
      // Bu durumda Google Maps API'den reverse geocoding yapılır
      try {
        final reverseGeocodedAddress =
            await _geocodingService.reverseGeocode(
          location.latitude,
          location.longitude,
        );
        if (reverseGeocodedAddress != null &&
            reverseGeocodedAddress.isNotEmpty) {
          address = reverseGeocodedAddress;
        } else {
          address = 'Konum seçildi';
        }
      } catch (e2) {
        address = 'Konum seçildi';
      }
    }

    // Koordinatlar varsa adres seçilmiş sayılır
    if (mounted) {
      setState(() {
        _selectedAddress = address;
        _errorMessage = null;
        _controller.text = address;
        _searchResults = [];
      });

      widget.onAddressSelected?.call(
        address,
        location.latitude,
        location.longitude,
      );
    }
  }

  /// Manuel adres girişi için geocoding
  Future<void> _geocodeAddress(String address) async {
    if (!widget.enableGeocoding) return;

    // Kullanıcının girdiği orijinal adresi sakla
    final originalAddress = address.trim();

    setState(() {
      _isGeocoding = true;
      _errorMessage = null;
    });

    try {
      // Bias ile geocoding yap
      final result = await _geocodingService.geocodeWithBias(
        originalAddress,
        countryCode: widget.countryCode,
        cityName: widget.cityName,
        districtName: widget.districtName,
      );

      if (result != null && mounted) {
        // Kullanıcının girdiği orijinal adresi kullan, geocoding sonucundaki formattedAddress'i değil
        // Sadece koordinatları geocoding'den al
        setState(() {
          _selectedAddress = originalAddress;
          _errorMessage = null;
          _isGeocoding = false;
          _controller.text = originalAddress; // Kullanıcının girdiği adresi göster
        });

        widget.onAddressSelected?.call(
          originalAddress, // Kullanıcının girdiği adresi gönder
          result.lat,
          result.lng,
        );
      } else if (mounted) {
        setState(() {
          _isGeocoding = false;
          _errorMessage =
              'Adres bulunamadı. Lütfen daha detaylı bir adres girin.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGeocoding = false;
          _errorMessage = 'Adres arama hatası: $e';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
      _selectedAddress = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        RichText(
          text: TextSpan(
            text: widget.label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            children: widget.isRequired
                ? [
                    TextSpan(
                      text: ' *',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ]
                : [],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Address Input with Geocoding
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: _errorMessage != null || widget.errorText != null
                  ? AppColors.error
                  : _selectedAddress != null && _selectedAddress!.isNotEmpty
                      ? AppColors.success
                      : AppColors.border,
              width: _selectedAddress != null && _selectedAddress!.isNotEmpty
                  ? 2
                  : 1,
            ),
          ),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                focusNode: _focusNode,
                decoration: InputDecoration(
                  hintText: _selectedAddress != null &&
                          _selectedAddress!.isNotEmpty
                      ? null
                      : widget.hint.isNotEmpty
                          ? widget.hint
                          : 'Haritadan adres seçin',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  prefixIcon: Icon(
                    Icons.location_on,
                    color: _errorMessage != null || widget.errorText != null
                        ? AppColors.error
                        : _selectedAddress != null &&
                                _selectedAddress!.isNotEmpty
                            ? AppColors.success
                            : AppColors.textSecondary,
                    size: AppSpacing.iconMd,
                  ),
                  suffixIcon: _isSearching || _isGeocoding
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _selectedAddress != null &&
                              _selectedAddress!.isNotEmpty &&
                              _errorMessage == null
                          ? Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: AppSpacing.iconMd,
                            )
                          : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.md,
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                onChanged: (value) {
                  if (value.length > 2) {
                    _searchAddresses(value);
                  } else {
                    setState(() {
                      _searchResults = [];
                    });
                  }
                },
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _geocodeAddress(value);
                  }
                },
              ),

              // Arama sonuçları - Geliştirilmiş adres gösterimi
              if (_searchResults.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(AppSpacing.radiusMd),
                      bottomRight: Radius.circular(AppSpacing.radiusMd),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final location = _searchResults[index];
                      return FutureBuilder<List<Placemark>>(
                        future: placemarkFromCoordinates(
                            location.latitude, location.longitude),
                        builder: (context, snapshot) {
                          String displayText;
                          String subtitleText =
                              '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';

                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final placemark = snapshot.data!.first;
                            // Daha iyi adres formatı
                            List<String> addressParts = [];
                            if (placemark.street != null &&
                                placemark.street!.isNotEmpty) {
                              addressParts.add(placemark.street!);
                            }
                            if (placemark.locality != null &&
                                placemark.locality!.isNotEmpty) {
                              addressParts.add(placemark.locality!);
                            }
                            if (placemark.administrativeArea != null &&
                                placemark.administrativeArea!.isNotEmpty) {
                              addressParts.add(placemark.administrativeArea!);
                            }

                            if (addressParts.isNotEmpty) {
                              displayText = addressParts.join(', ');
                            } else {
                              displayText =
                                  'Konum: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
                            }
                          } else {
                            displayText =
                                'Konum: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}';
                          }

                          return ListTile(
                            leading: Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                              size: AppSpacing.iconSm,
                            ),
                            title: Text(
                              displayText,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              subtitleText,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            onTap: () => _selectAddress(location),
                          );
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),

        // Error message
        if (_errorMessage != null || widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              _errorMessage ?? widget.errorText ?? '',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),

      ],
    );
  }
}
