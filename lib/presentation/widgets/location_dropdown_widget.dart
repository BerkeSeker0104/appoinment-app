import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../data/models/world_location_model.dart';
import '../../data/services/world_api_service.dart';

class LocationDropdownWidget extends StatefulWidget {
  final String label;
  final String hint;
  final bool isRequired;
  final String? Function(String?)? validator;
  final Function(int? countryId, int? cityId, int? stateId)? onLocationSelected;
  final Function(String? countryName, String? cityName, String? stateName)?
      onLocationNamesSelected;
  final int? initialCountryId;
  final int? initialCityId;
  final int? initialStateId;

  const LocationDropdownWidget({
    super.key,
    required this.label,
    required this.hint,
    this.isRequired = false,
    this.validator,
    this.onLocationSelected,
    this.onLocationNamesSelected,
    this.initialCountryId,
    this.initialCityId,
    this.initialStateId,
  });

  @override
  State<LocationDropdownWidget> createState() => _LocationDropdownWidgetState();
}

class _LocationDropdownWidgetState extends State<LocationDropdownWidget> {
  final WorldApiService _worldApiService = WorldApiService();

  // Loading states
  bool _isLoadingCountries = false;
  bool _isLoadingCities = false;
  bool _isLoadingStates = false;

  // Data lists
  List<CountryModel> _countries = [];
  List<CityModel> _cities = [];
  List<StateModel> _states = [];

  // Selected values
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  StateModel? _selectedState;

  // Error state
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  @override
  void didUpdateWidget(LocationDropdownWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If initial values changed, reload them
    if (oldWidget.initialCountryId != widget.initialCountryId ||
        oldWidget.initialCityId != widget.initialCityId ||
        oldWidget.initialStateId != widget.initialStateId) {
      // Only reload if we have new initial values
      if (widget.initialCountryId != null ||
          widget.initialCityId != null ||
          widget.initialStateId != null) {
        _loadInitialValuesFromIds();
      }
    }
  }

  Future<void> _initializeWidget() async {
    // First load countries
    await _loadCountries();

    // Then load initial values if any
    _loadInitialValues();
  }

  void _loadInitialValues() {
    if (widget.initialCountryId != null ||
        widget.initialCityId != null ||
        widget.initialStateId != null) {
      // Load initial values from IDs
      _loadInitialValuesFromIds();
    }
  }

  Future<void> _loadInitialValuesFromIds() async {
    try {
      // Load country
      if (widget.initialCountryId != null) {
        // Eğer countries listesi boşsa, önce yükle
        if (_countries.isEmpty) {
          await _loadCountries();
        }
        
        // Tüm ülkeleri yükle (pagination ile) - eğer hala boşsa
        if (_countries.isEmpty) {
          final countriesResponse =
              await _worldApiService.getCountries(dataCount: 1000);
          final countries = countriesResponse.data;

          // Duplicate'leri temizle ve _countries listesini güncelle
          final uniqueCountries = <int, CountryModel>{};
          for (final country in countries) {
            uniqueCountries[country.id] = country;
          }
          _countries = uniqueCountries.values.toList();
        }

        try {
          _selectedCountry = _countries.firstWhere(
            (c) => c.id == widget.initialCountryId,
          );
        } catch (e) {
          // Country not found, keep null
          _selectedCountry = null;
        }

        if (_selectedCountry != null) {
          // Load cities for selected country - TÜM şehirleri yükle
          final cities = await _worldApiService.getAllCitiesForCountry(_selectedCountry!.id);
          
          // Duplicate'leri temizle - ID'ye göre unique yap
          final uniqueCities = <int, CityModel>{};
          for (final city in cities) {
            uniqueCities[city.id] = city;
          }
          _cities = uniqueCities.values.toList();

          // Load city
          if (widget.initialCityId != null) {
            try {
              _selectedCity = _cities.firstWhere(
                (c) => c.id == widget.initialCityId,
              );
            } catch (e) {
              // City not found, keep null
              _selectedCity = null;
            }

            if (_selectedCity != null) {
              // Load states for selected city - TÜM ilçeleri yükle
              final states = await _worldApiService.getAllStatesForCity(_selectedCity!.id);
              
              // Duplicate'leri temizle - ID'ye göre unique yap
              final uniqueStates = <int, StateModel>{};
              for (final state in states) {
                uniqueStates[state.id] = state;
              }
              _states = uniqueStates.values.toList();

              // Load state
              if (widget.initialStateId != null) {
                try {
                  _selectedState = _states.firstWhere(
                    (s) => s.id == widget.initialStateId,
                  );
                } catch (e) {
                  // State not found, keep null
                  _selectedState = null;
                }
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {});
        // Call callbacks with loaded values
        widget.onLocationSelected?.call(
          _selectedCountry?.id,
          _selectedCity?.id,
          _selectedState?.id,
        );
        widget.onLocationNamesSelected?.call(
          _selectedCountry?.name,
          _selectedCity?.name,
          _selectedState?.name,
        );
      }
    } catch (e) {
      // Error handling
    }
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _errorMessage = null;
    });

    try {
      // Tüm ülkeleri yükle (pagination ile)
      final countries = await _worldApiService.getAllCountries();
      if (mounted) {
        setState(() {
          // Duplicate'leri temizle - ID'ye göre unique yap
          final uniqueCountries = <int, CountryModel>{};
          for (final country in countries) {
            uniqueCountries[country.id] = country;
          }
          _countries = uniqueCountries.values.toList();
          _isLoadingCountries = false;

          // Initial değerler varsa onları kullan, yoksa Türkiye'yi varsayılan seç
          if (widget.initialCountryId != null) {
            // Initial değerler _loadInitialValuesFromIds'de yüklenecek
          } else {
            // Türkiye'yi varsayılan seç (code: "TR" veya name: "Turkey")
            _selectedCountry = _countries.firstWhere(
              (c) =>
                  c.code == 'TR' ||
                  c.name.toLowerCase().contains('turkey') ||
                  c.name.toLowerCase().contains('türkiye'),
              orElse: () => _countries.first,
            );

            // Türkiye seçiliyse şehirleri yükle
            if (_selectedCountry != null) {
              _loadCities(_selectedCountry!.id);
              widget.onLocationSelected?.call(_selectedCountry?.id, null, null);
              widget.onLocationNamesSelected?.call(
                _selectedCountry?.name,
                null,
                null,
              );
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Ülkeler yüklenemedi: ${e.toString()}';
          _isLoadingCountries = false;
        });
      }
    }
  }

  Future<void> _loadCities(int countryId) async {
    setState(() {
      _isLoadingCities = true;
      _cities = [];
      _states = [];
      _selectedCity = null;
      _selectedState = null;
      _errorMessage = null;
    });

    try {
      final response = await _worldApiService.getAllCitiesForCountry(countryId);
      if (mounted) {
        setState(() {
          // Duplicate'leri temizle - ID'ye göre unique yap
          final uniqueCities = <int, CityModel>{};
          for (final city in response) {
            uniqueCities[city.id] = city;
          }
          _cities = uniqueCities.values.toList();
          _isLoadingCities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Şehirler yüklenemedi: ${e.toString()}';
          _isLoadingCities = false;
        });
      }
    }
  }

  Future<void> _loadStates(int cityId) async {
    setState(() {
      _isLoadingStates = true;
      _states = [];
      _selectedState = null;
      _errorMessage = null;
    });

    try {
      final response = await _worldApiService.getAllStatesForCity(cityId);
      if (mounted) {
        setState(() {
          // Duplicate'leri temizle - ID'ye göre unique yap
          final uniqueStates = <int, StateModel>{};
          for (final state in response) {
            uniqueStates[state.id] = state;
          }
          _states = uniqueStates.values.toList();
          _isLoadingStates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'İlçeler yüklenemedi: ${e.toString()}';
          _isLoadingStates = false;
        });
      }
    }
  }

  void _onCountrySelected(CountryModel? country) {
    setState(() {
      _selectedCountry = country;
      _selectedCity = null;
      _selectedState = null;
      _cities = [];
      _states = [];
    });

    if (country != null) {
      _loadCities(country.id);
    }

    // Callback
    widget.onLocationSelected?.call(country?.id, null, null);
    widget.onLocationNamesSelected?.call(country?.name, null, null);
  }

  void _onCitySelected(CityModel? city) {
    setState(() {
      _selectedCity = city;
      _selectedState = null;
      _states = [];
    });

    if (city != null) {
      _loadStates(city.id);
    }

    // Callback
    widget.onLocationSelected?.call(_selectedCountry?.id, city?.id, null);
    widget.onLocationNamesSelected?.call(
      _selectedCountry?.name,
      city?.name,
      null,
    );
  }

  void _onStateSelected(StateModel? state) {
    setState(() {
      _selectedState = state;
    });

    // Callback
    widget.onLocationSelected?.call(
      _selectedCountry?.id,
      _selectedCity?.id,
      state?.id,
    );
    widget.onLocationNamesSelected?.call(
      _selectedCountry?.name,
      _selectedCity?.name,
      state?.name,
    );
  }

  String? _validateLocation() {
    if (widget.isRequired) {
      if (_selectedCountry == null) {
        return 'Ülke seçimi gerekli';
      }
      if (_selectedCity == null) {
        return 'İl seçimi gerekli';
      }
      if (_selectedState == null) {
        return 'İlçe seçimi gerekli';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Error message
        if (_errorMessage != null) ...[
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.errorLight,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(color: AppColors.error, width: 0.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: AppSpacing.iconSm,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _loadCountries,
                  child: Text(
                    'Tekrar Dene',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Country Dropdown
        _buildDropdown(
          label: 'Ülke',
          hint: 'Ülke seçin',
          isLoading: _isLoadingCountries,
          items: _countries
              .map(
                (country) => DropdownMenuItem(
                  value: country,
                  child: Text(country.name),
                ),
              )
              .toList(),
          selectedValue: _selectedCountry,
          onChanged: _onCountrySelected,
        ),

        const SizedBox(height: AppSpacing.lg),

        // City and State Dropdowns in a Row
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City Dropdown
            Expanded(
              child: _buildDropdown(
                label: 'İl',
                hint: _selectedCountry == null ? 'Önce ülke seçin' : 'İl seçin',
                isLoading: _isLoadingCities,
                items: _cities
                    .map(
                      (city) => DropdownMenuItem(value: city, child: Text(city.name)),
                    )
                    .toList(),
                selectedValue: _selectedCity,
                onChanged: _onCitySelected,
                isEnabled: _selectedCountry != null,
              ),
            ),

            const SizedBox(width: AppSpacing.lg),

            // State Dropdown
            Expanded(
              child: _buildDropdown(
                label: 'İlçe',
                hint: _selectedCity == null ? 'Önce il seçin' : 'İlçe seçin',
                isLoading: _isLoadingStates,
                items: _states
                    .map(
                      (state) =>
                          DropdownMenuItem(value: state, child: Text(state.name)),
                    )
                    .toList(),
                selectedValue: _selectedState,
                onChanged: _onStateSelected,
                isEnabled: _selectedCity != null,
              ),
            ),
          ],
        ),

        // Validation error
        if (widget.validator != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Builder(
            builder: (context) {
              final error = widget.validator?.call(_validateLocation());
              return error != null
                  ? Text(
                      error,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.error,
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required String hint,
    required bool isLoading,
    required List<DropdownMenuItem<T>> items,
    required T? selectedValue,
    required Function(T?) onChanged,
    bool isEnabled = true,
  }) {
    // Duplicate items'ları temizle - ID bazlı kontrol
    final uniqueItems = <int, DropdownMenuItem<T>>{};
    for (final item in items) {
      if (item.value != null) {
        // CountryModel, CityModel, StateModel için ID kullan
        int? id;
        if (item.value is CountryModel) {
          id = (item.value as CountryModel).id;
        } else if (item.value is CityModel) {
          id = (item.value as CityModel).id;
        } else if (item.value is StateModel) {
          id = (item.value as StateModel).id;
        } else {
          // Diğer tipler için hash kullan
          id = item.value.hashCode;
        }

        if (!uniqueItems.containsKey(id)) {
          uniqueItems[id] = item;
        }
      }
    }
    final cleanedItems = uniqueItems.values.toList();

    // selectedValue'yu temizlenmiş items ile eşleştir
    T? cleanedSelectedValue;
    if (selectedValue != null) {
      int? selectedId;
      if (selectedValue is CountryModel) {
        selectedId = (selectedValue as CountryModel).id;
      } else if (selectedValue is CityModel) {
        selectedId = (selectedValue as CityModel).id;
      } else if (selectedValue is StateModel) {
        selectedId = (selectedValue as StateModel).id;
      } else {
        selectedId = selectedValue.hashCode;
      }

      // Temizlenmiş items'da bu ID'ye sahip item'ı bul
      final matchingItem = cleanedItems.firstWhere(
        (item) {
          if (item.value == null) return false;
          int? itemId;
          if (item.value is CountryModel) {
            itemId = (item.value as CountryModel).id;
          } else if (item.value is CityModel) {
            itemId = (item.value as CityModel).id;
          } else if (item.value is StateModel) {
            itemId = (item.value as StateModel).id;
          } else {
            itemId = item.value.hashCode;
          }
          return itemId == selectedId;
        },
        orElse: () => cleanedItems.isNotEmpty
            ? cleanedItems.first
            : DropdownMenuItem<T>(value: null, child: const SizedBox()),
      );

      cleanedSelectedValue = matchingItem.value;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color:
                  selectedValue != null ? AppColors.primary : AppColors.border,
              width: 1,
            ),
          ),
          child: isLoading
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Yükleniyor...',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<T>(
                    value: cleanedSelectedValue,
                    hint: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Text(
                        hint,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    isExpanded: true,
                    isDense: false,
                    items: cleanedItems,
                    selectedItemBuilder: (BuildContext context) {
                      return cleanedItems.map<Widget>((DropdownMenuItem<T> item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: item.child,
                          ),
                        );
                      }).toList();
                    },
                    onChanged: isEnabled ? onChanged : null,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    menuMaxHeight: 300, // YENİ: Max height ekle
                  ),
                ),
        ),
      ],
    );
  }
}
