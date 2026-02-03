import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// TokenStorage - Multi-layer token persistence
/// 
/// Storage layers (in priority order):
/// 1. Memory cache - Fast access, lost on app restart
/// 2. Keychain/KeyStore (via flutter_secure_storage) - Survives app kill, most secure
/// 3. SharedPreferences - Migration fallback
/// 4. File storage - Legacy backup
/// 
/// iOS Note: Keychain is the most reliable storage on iOS, surviving app kills and memory pressure
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._internal();
  factory TokenStorage() => _instance;
  TokenStorage._internal();

  // In-memory storage for hot reload scenarios
  String? _cachedToken;
  String? _cachedUserJson;

  SharedPreferences? _prefs;
  File? _tokenFile;
  
  // Secure storage for iOS Keychain and Android KeyStore
  late FlutterSecureStorage _secureStorage;
  bool _secureStorageAvailable = false;

  Future<void> initialize() async {
    // Initialize secure storage with iOS-specific options
    try {
      _secureStorage = const FlutterSecureStorage(
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
          // Allows access after first unlock, persists through app kill
        ),
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );
      _secureStorageAvailable = true;
      if (kDebugMode) {
        debugPrint('TokenStorage: Secure storage initialized');
      }
    } catch (e) {
      _secureStorageAvailable = false;
      if (kDebugMode) {
        debugPrint('TokenStorage: Secure storage unavailable: $e');
      }
    }

    try {
      _prefs = await SharedPreferences.getInstance();
    } catch (e) {
      _prefs = null;
    }

    // Initialize file storage as backup
    try {
      final directory = await getApplicationDocumentsDirectory();
      _tokenFile = File('${directory.path}/tokens.json');
    } catch (e) {
      _tokenFile = null;
    }
  }

  Future<void> saveToken(String token) async {
    // Save to memory first
    _cachedToken = token;

    // Save to Keychain/KeyStore (most reliable, survives app kill)
    if (_secureStorageAvailable) {
      try {
        await _secureStorage.write(key: 'auth_token', value: token);
        if (kDebugMode) {
          debugPrint('TokenStorage: Token saved to Keychain');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: Keychain save error: $e');
        }
      }
    }

    // Save to SharedPreferences (fallback)
    if (_prefs != null) {
      try {
        await _prefs!.setString('auth_token', token);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: SharedPreferences save error: $e');
        }
      }
    }

    // Save to file as backup
    await _saveToFile();
  }

  Future<void> saveUserJson(String userJson) async {
    _cachedUserJson = userJson;

    // Save to Keychain/KeyStore
    if (_secureStorageAvailable) {
      try {
        await _secureStorage.write(key: 'user_json', value: userJson);
        if (kDebugMode) {
          debugPrint('TokenStorage: User JSON saved to Keychain');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: Keychain save error: $e');
        }
      }
    }

    // Save to SharedPreferences (fallback)
    if (_prefs != null) {
      try {
        await _prefs!.setString('user_json', userJson);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: SharedPreferences save error: $e');
        }
      }
    }

    await _saveToFile();
  }

  Future<String?> getUserJson() async {
    // First check memory cache
    if (_cachedUserJson != null) {
      return _cachedUserJson;
    }

    // Try to get from Keychain/KeyStore
    if (_secureStorageAvailable) {
      try {
        final json = await _secureStorage.read(key: 'user_json');
        if (json != null && json.isNotEmpty) {
          _cachedUserJson = json;
          if (kDebugMode) {
            debugPrint('TokenStorage: User JSON read from Keychain');
          }
          return json;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: Keychain read error: $e');
        }
      }
    }

    // Fallback to SharedPreferences (migration)
    if (_prefs != null) {
      try {
        final json = _prefs!.getString('user_json');
        if (json != null) {
          _cachedUserJson = json;
          if (kDebugMode) {
            debugPrint('TokenStorage: User JSON read from SharedPreferences (migration)');
          }
          // Migrate to Keychain
          if (_secureStorageAvailable) {
            await _secureStorage.write(key: 'user_json', value: json);
          }
          return json;
        }
      } catch (e) {
      }
    }

    await _loadFromFile();
    return _cachedUserJson;
  }

  Future<String?> getToken() async {
    // First check memory cache
    if (_cachedToken != null) {
      if (kDebugMode) {
        debugPrint('TokenStorage: Token read from memory cache');
      }
      return _cachedToken;
    }

    // Try to get from Keychain/KeyStore (most reliable)
    if (_secureStorageAvailable) {
      try {
        final token = await _secureStorage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          if (kDebugMode) {
            debugPrint('TokenStorage: Token read from Keychain');
          }
          return token;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: Keychain read error: $e');
        }
      }
    }

    // Fallback to SharedPreferences (migration support)
    if (_prefs != null) {
      try {
        final token = _prefs!.getString('auth_token');
        if (token != null) {
          _cachedToken = token;
          if (kDebugMode) {
            debugPrint('TokenStorage: Token read from SharedPreferences (migration)');
          }
          // Migrate to Keychain
          if (_secureStorageAvailable) {
            await _secureStorage.write(key: 'auth_token', value: token);
            if (kDebugMode) {
              debugPrint('TokenStorage: Token migrated to Keychain');
            }
          }
          return token;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: SharedPreferences read error: $e');
        }
      }
    }

    // Try to get from file (last resort)
    await _loadFromFile();
    if (_cachedToken != null) {
      if (kDebugMode) {
        debugPrint('TokenStorage: Token read from file backup');
      }
    } else {
      if (kDebugMode) {
        debugPrint('TokenStorage: No token found in any storage');
      }
    }
    return _cachedToken;
  }

  Future<void> clearTokens() async {
    // Clear memory cache
    _cachedToken = null;
    _cachedUserJson = null;

    // Clear from Keychain/KeyStore
    if (_secureStorageAvailable) {
      try {
        await _secureStorage.delete(key: 'auth_token');
        await _secureStorage.delete(key: 'user_json');
        if (kDebugMode) {
          debugPrint('TokenStorage: Tokens cleared from Keychain');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('TokenStorage: Keychain clear error: $e');
        }
      }
    }

    // Clear from SharedPreferences
    if (_prefs != null) {
      try {
        await _prefs!.remove('auth_token');
        await _prefs!.remove('user_json');
      } catch (e) {
      }
    }

    // Clear from file
    if (_tokenFile != null) {
      try {
        if (await _tokenFile!.exists()) {
           await _tokenFile!.delete();
        }
      } catch (e) {
      }
    }
  }

  /// Clear only user data (for token expiration scenarios)
  Future<void> clearUserData() async {
    // Clear user data from memory cache
    _cachedUserJson = null;

    // Clear from SharedPreferences
    if (_prefs != null) {
      try {
        await _prefs!.remove('user_json');
      } catch (e) {
      }
    }

    // Update file without tokens
    await _saveToFile();
  }

  Future<void> _saveToFile() async {
    if (_tokenFile == null) return;

    try {
      final data = {
        'auth_token': _cachedToken,
        'user_json': _cachedUserJson,
      };
      await _tokenFile!.writeAsString(jsonEncode(data));
    } catch (e) {
    }
  }

  Future<void> _loadFromFile() async {
    if (_tokenFile == null) return;

    try {
      if (await _tokenFile!.exists()) {
        final content = await _tokenFile!.readAsString();
        final data = jsonDecode(content) as Map<String, dynamic>;

        _cachedToken = data['auth_token'] as String?;
        _cachedUserJson = data['user_json'] as String?;
      }
    } catch (e) {
    }
  }
}
