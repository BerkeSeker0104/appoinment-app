import 'package:flutter/foundation.dart';
import '../../domain/entities/user_address.dart';
import '../../domain/usecases/user_address_usecases.dart';
import '../../data/repositories/user_address_repository_impl.dart';
import '../../core/services/app_lifecycle_service.dart';

class AddressProvider with ChangeNotifier implements LoadingStateResettable {
  final UserAddressUseCases _useCases = UserAddressUseCases(UserAddressRepositoryImpl());

  List<UserAddress> _addresses = [];
  UserAddress? _selectedDeliveryAddress;
  UserAddress? _selectedInvoiceAddress;
  bool _isLoading = false;
  String? _errorMessage;

  List<UserAddress> get addresses => _addresses;
  UserAddress? get selectedDeliveryAddress => _selectedDeliveryAddress;
  UserAddress? get selectedInvoiceAddress => _selectedInvoiceAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<UserAddress> get deliveryAddresses {
    return _addresses.where((addr) => addr.type == AddressType.delivery).toList();
  }

  List<UserAddress> get invoiceAddresses {
    return _addresses.where((addr) => addr.type == AddressType.invoice).toList();
  }

  Future<void> loadAddresses() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _addresses = await _useCases.getAddresses();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      _addresses = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<UserAddress> addAddress({
    required AddressType type,
    required String addressName,
    required String firstName,
    required String lastName,
    required String phoneCode,
    required String phone,
    required int countryId,
    required int cityId,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final newAddress = await _useCases.addAddress(
        type: type,
        addressName: addressName,
        firstName: firstName,
        lastName: lastName,
        phoneCode: phoneCode,
        phone: phone,
        countryId: countryId,
        cityId: cityId,
        address: address,
      );
      _addresses.add(newAddress);
      _errorMessage = null;
      
      // Eğer bu tip için seçili adres yoksa, yeni eklenen adresi seç
      if (type == AddressType.delivery && _selectedDeliveryAddress == null) {
        _selectedDeliveryAddress = newAddress;
      } else if (type == AddressType.invoice && _selectedInvoiceAddress == null) {
        _selectedInvoiceAddress = newAddress;
      }
      
      return newAddress;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> ensureInvoiceAddressFromDelivery(UserAddress deliveryAddress) async {
    try {
      // 1. Mevcut fatura adreslerinde aynı bilgilerle kayıtlı var mı kontrol et
      final existing = _addresses.where((addr) => addr.type == AddressType.invoice).firstWhere(
        (addr) => 
          addr.firstName == deliveryAddress.firstName &&
          addr.lastName == deliveryAddress.lastName &&
          addr.address == deliveryAddress.address &&
          addr.cityId == deliveryAddress.cityId,
        orElse: () => UserAddress(
          id: '',
          type: AddressType.invoice,
          addressName: '',
          firstName: '',
          lastName: '',
          phoneCode: '',
          phone: '',
          countryId: 0,
          cityId: 0,
          address: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (existing.id.isNotEmpty) {
        return existing.id;
      }

      // 2. Yoksa yeni oluştur
      final newAddress = await addAddress(
        type: AddressType.invoice,
        addressName: '${deliveryAddress.addressName} (Fatura)',
        firstName: deliveryAddress.firstName,
        lastName: deliveryAddress.lastName,
        phoneCode: deliveryAddress.phoneCode,
        phone: deliveryAddress.phone,
        countryId: deliveryAddress.countryId,
        cityId: deliveryAddress.cityId,
        address: deliveryAddress.address,
      );
      
      return newAddress.id;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAddress({
    required String id,
    required AddressType type,
    required String addressName,
    required String firstName,
    required String lastName,
    required String phoneCode,
    required String phone,
    required int countryId,
    required int cityId,
    required String address,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedAddress = await _useCases.updateAddress(
        id: id,
        type: type,
        addressName: addressName,
        firstName: firstName,
        lastName: lastName,
        phoneCode: phoneCode,
        phone: phone,
        countryId: countryId,
        cityId: cityId,
        address: address,
      );
      
      final index = _addresses.indexWhere((addr) => addr.id == id);
      if (index != -1) {
        _addresses[index] = updatedAddress;
        
        // Eğer güncellenen adres seçili adres ise, güncelle
        if (_selectedDeliveryAddress?.id == id) {
          _selectedDeliveryAddress = updatedAddress;
        }
        if (_selectedInvoiceAddress?.id == id) {
          _selectedInvoiceAddress = updatedAddress;
        }
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteAddress(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _useCases.deleteAddress(id);
      _addresses.removeWhere((addr) => addr.id == id);
      
      // Eğer silinen adres seçili adres ise, seçimi temizle
      if (_selectedDeliveryAddress?.id == id) {
        _selectedDeliveryAddress = null;
      }
      if (_selectedInvoiceAddress?.id == id) {
        _selectedInvoiceAddress = null;
      }
      
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectDeliveryAddress(UserAddress? address) {
    _selectedDeliveryAddress = address;
    notifyListeners();
  }

  void selectInvoiceAddress(UserAddress? address) {
    _selectedInvoiceAddress = address;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
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

