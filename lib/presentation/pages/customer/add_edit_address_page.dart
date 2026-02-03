import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_typography.dart';
import '../../../domain/entities/user_address.dart';
import '../../../data/models/world_location_model.dart';
import '../../../data/services/world_api_service.dart';
import '../../providers/address_provider.dart';
import '../../widgets/premium_input.dart';
import '../../widgets/premium_button.dart';
import '../../../l10n/app_localizations.dart';

class AddEditAddressPage extends StatefulWidget {
  final UserAddress? address;
  final AddressType? addressType;

  const AddEditAddressPage({
    super.key,
    this.address,
    this.addressType,
  });

  @override
  State<AddEditAddressPage> createState() => _AddEditAddressPageState();
}

class _AddEditAddressPageState extends State<AddEditAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  final WorldApiService _worldApiService = WorldApiService();

  List<CountryModel> _countries = [];
  List<CityModel> _cities = [];
  CountryModel? _selectedCountry;
  CityModel? _selectedCity;
  String _selectedPhoneCode = '+90';
  AddressType _selectedType = AddressType.delivery;

  bool _isLoadingCountries = false;
  bool _isLoadingCities = false;
  bool _isSaving = false;

  final List<String> _phoneCodes = [
    '+90',
    '+1',
    '+44',
    '+49',
    '+33',
    '+39',
    '+34',
    '+31',
    '+32',
    '+41',
    '+43',
    '+45',
    '+46',
    '+47',
    '+48',
    '+351',
    '+352',
    '+353',
    '+354',
    '+356',
    '+357',
    '+358',
    '+359',
    '+370',
    '+371',
    '+372',
    '+373',
    '+374',
    '+375',
    '+376',
    '+377',
    '+378',
    '+380',
    '+381',
    '+382',
    '+383',
    '+385',
    '+386',
    '+387',
    '+389',
    '+420',
    '+421',
    '+423',
    '+7',
    '+20',
    '+27',
    '+971',
    '+966',
    '+974',
    '+965',
    '+973',
    '+968',
    '+961',
    '+962',
    '+964',
    '+963',
    '+961',
    '+60',
    '+65',
    '+66',
    '+84',
    '+81',
    '+82',
    '+86',
    '+91',
    '+92',
    '+880',
    '+94',
    '+95',
    '+977',
    '+880',
  ];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadCountries();
  }

  void _initializeForm() {
    if (widget.address != null) {
      final address = widget.address!;
      _addressNameController.text = address.addressName;
      _firstNameController.text = address.firstName;
      _lastNameController.text = address.lastName;
      // Telefon numarasını formatlanmış şekilde göster (XXX XXX XXXX)
      _phoneController.text = _formatPhoneNumber(address.phone);
      _addressController.text = address.address;
      _selectedPhoneCode = address.phoneCode;
      _selectedType = address.type;
    } else if (widget.addressType != null) {
      _selectedType = widget.addressType!;
    }
  }

  String _formatPhoneNumber(String value) {
    // Sadece rakamları al
    String digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

    // 10 haneden fazla olamaz
    if (digitsOnly.length > 10) {
      digitsOnly = digitsOnly.substring(0, 10);
    }

    // Format: XXX XXX XXXX
    if (digitsOnly.length <= 3) {
      return digitsOnly;
    } else if (digitsOnly.length <= 6) {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3)}';
    } else {
      return '${digitsOnly.substring(0, 3)} ${digitsOnly.substring(3, 6)} ${digitsOnly.substring(6)}';
    }
  }

  @override
  void dispose() {
    _addressNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
    });

    try {
      final countries = await _worldApiService.getAllCountries();
      setState(() {
        _countries = countries;
        _isLoadingCountries = false;

        // Eğer düzenleme modundaysa, ülke ve şehir seçimlerini yükle
        if (widget.address != null) {
          final address = widget.address!;
          _selectedCountry = countries.firstWhere(
            (c) => c.id == address.countryId,
            orElse: () => countries.first,
          );
          _loadCities(address.countryId);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCountries = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLoadingCountries}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _loadCities(int countryId) async {
    setState(() {
      _isLoadingCities = true;
    });

    try {
      final cities = await _worldApiService.getAllCitiesForCountry(countryId);
      setState(() {
        _cities = cities;
        _isLoadingCities = false;

        // Eğer düzenleme modundaysa, şehir seçimini yükle
        if (widget.address != null) {
          final address = widget.address!;
          try {
            _selectedCity = cities.firstWhere(
              (c) => c.id == address.cityId,
            );
          } catch (e) {
            _selectedCity = cities.isNotEmpty ? cities.first : null;
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingCities = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.errorLoadingCities}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectCountryError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.selectCityError),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final provider = context.read<AddressProvider>();

      // Telefon numarasından sadece rakamları çıkar (boşlukları kaldır)
      final phoneDigitsOnly = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');

      if (widget.address != null) {
        // Update existing address
        await provider.updateAddress(
          id: widget.address!.id,
          type: _selectedType,
          addressName: _addressNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneCode: _selectedPhoneCode,
          phone: phoneDigitsOnly,
          countryId: _selectedCountry!.id,
          cityId: _selectedCity!.id,
          address: _addressController.text.trim(),
        );
      } else {
        // Add new address
        await provider.addAddress(
          type: _selectedType,
          addressName: _addressNameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          phoneCode: _selectedPhoneCode,
          phone: phoneDigitsOnly,
          countryId: _selectedCountry!.id,
          cityId: _selectedCity!.id,
          address: _addressController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.address != null
                  ? AppLocalizations.of(context)!.addressUpdatedSuccess
                  : AppLocalizations.of(context)!.addressAddedSuccess,
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.address != null ? AppLocalizations.of(context)!.editAddress : AppLocalizations.of(context)!.addNewAddress,
          style: AppTypography.h5.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Address Type Selection
              Text(
                AppLocalizations.of(context)!.addressType,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedButton<AddressType>(
                segments: [
                  ButtonSegment<AddressType>(
                    value: AddressType.delivery,
                    label: Text(AppLocalizations.of(context)!.delivery),
                    icon: Icon(Icons.local_shipping_outlined),
                  ),
                  ButtonSegment<AddressType>(
                    value: AddressType.invoice,
                    label: Text(AppLocalizations.of(context)!.invoice),
                    icon: Icon(Icons.receipt_long_outlined),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<AddressType> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.xl),

              // Address Name
              PremiumInput(
                label: AppLocalizations.of(context)!.addressName,
                hint: AppLocalizations.of(context)!.addressNameHint,
                controller: _addressNameController,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.addressNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // First Name and Last Name Row
              Row(
                children: [
                  Expanded(
                    child: PremiumInput(
                      label: AppLocalizations.of(context)!.firstName,
                      controller: _firstNameController,
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.firstNameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: PremiumInput(
                      label: AppLocalizations.of(context)!.lastName,
                      controller: _lastNameController,
                      isRequired: true,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.lastNameRequired;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Phone Code and Phone Row
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kod',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            DropdownButtonFormField<String>(
                              value: _selectedPhoneCode,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceInput,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.lg,
                                ),
                              ),
                              items: _phoneCodes.map((code) {
                                return DropdownMenuItem(
                                  value: code,
                                  child: Text(code),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedPhoneCode = value ?? '+90';
                                });
                              },
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: PremiumInput(
                          label: AppLocalizations.of(context)!.phone,
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          isPhoneNumber: true,
                          isRequired: true,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return AppLocalizations.of(context)!.phoneRequired;
                            }
                            // Sadece rakamları al ve 10 haneli olup olmadığını kontrol et
                            final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
                            if (digitsOnly.length != 10) {
                              return AppLocalizations.of(context)!.phoneMustBe10Digits;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // Country Dropdown
              _buildDropdownLabel(AppLocalizations.of(context)!.country, true),
              const SizedBox(height: AppSpacing.sm),
              _buildCountryDropdown(),
              const SizedBox(height: AppSpacing.lg),

              // City Dropdown
              _buildDropdownLabel(AppLocalizations.of(context)!.city, true),
              const SizedBox(height: AppSpacing.sm),
              _buildCityDropdown(),
              const SizedBox(height: AppSpacing.lg),

              // Address
              PremiumInput(
                label: AppLocalizations.of(context)!.address,
                hint: AppLocalizations.of(context)!.addressHint,
                controller: _addressController,
                maxLines: 4,
                isRequired: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.addressRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Save Button
              PremiumButton(
                text: widget.address != null ? AppLocalizations.of(context)!.update : AppLocalizations.of(context)!.save,
                onPressed: _isSaving ? null : _saveAddress,
                isLoading: _isSaving,
                variant: ButtonVariant.primary,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownLabel(String label, bool isRequired) {
    return RichText(
      text: TextSpan(
        text: label,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        children: isRequired
            ? [
                TextSpan(
                  text: ' *',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<CountryModel>(
        value: _selectedCountry,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)!.selectCountry,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
        items: _countries.map((country) {
          return DropdownMenuItem<CountryModel>(
            value: country,
            child: Text(
              country.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: _isLoadingCountries
            ? null
            : (CountryModel? country) {
                setState(() {
                  _selectedCountry = country;
                  _selectedCity = null;
                  _cities = [];
                });
                if (country != null) {
                  _loadCities(country.id);
                }
              },
        validator: (value) {
          if (value == null) {
            return AppLocalizations.of(context)!.countryRequired;
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCityDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceInput,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<CityModel>(
        value: _selectedCity,
        decoration: InputDecoration(
          hintText: _selectedCountry == null
              ? AppLocalizations.of(context)!.selectCountryFirst
              : AppLocalizations.of(context)!.selectCity,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
        items: _cities.map((city) {
          return DropdownMenuItem<CityModel>(
            value: city,
            child: Text(
              city.name,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          );
        }).toList(),
        onChanged: (_selectedCountry == null || _isLoadingCities)
            ? null
            : (CityModel? city) {
                setState(() {
                  _selectedCity = city;
                });
              },
        validator: (value) {
          if (value == null) {
            return AppLocalizations.of(context)!.cityRequired;
          }
          return null;
        },
      ),
    );
  }
}

