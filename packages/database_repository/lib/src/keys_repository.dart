// ignore_for_file: constant_identifier_names

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Backend-neutral interface for retrieving application API keys.
abstract interface class ApiKeyProvider {
  /// Returns the API key for Google Maps.
  Future<String> getMapsApiKey();

  /// Returns the API key for the ZipCode API.
  Future<String> getZipCodeApiKey();

  /// Returns the API key for the Location API.
  Future<String> getLocationApiKey();

  /// Returns the API key for the Json Link API.
  Future<String> getJsonLinkApiKey();
}

///This class is responsible for managing the keys of the application
class KeysRepository implements ApiKeyProvider {
  /// Constructs a [KeysRepository] with an optional [FirebaseRemoteConfig].
  KeysRepository([this._remoteConfig]);

  final FirebaseRemoteConfig? _remoteConfig;

  ///Instance of the Firebase Remote Config
  FirebaseRemoteConfig get remoteConfig =>
      _remoteConfig ?? FirebaseRemoteConfig.instance;

  final Map<String, String> _cachedKeys = {};
  Future<void>? _fetchFuture;

  Future<String> _getKey(String constant) async {
    final cached = _cachedKeys[constant];
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      await (_fetchFuture ??= remoteConfig.fetchAndActivate());
    } catch (_) {
      _fetchFuture = null;
      rethrow;
    }

    final value = remoteConfig.getString(constant);
    if (value.isNotEmpty) {
      _cachedKeys[constant] = value;
    }
    return value;
  }

  ///Constant to refer to the API key for the Google Maps
  static const String MAPS_CONSTANT = 'MapsApiKey';

  /// Constant to refer to the API key for the ZipCode API
  static const String ZIP_CODE_CONSTANT = 'ZipApiKey';

  /// Constant to refer to the API key for the Location API
  static const String LOCATION_KEY_CONSTANT = 'LocationApiKey';

  /// Constant to refer to the API key for the Json Link API
  static const String JSON_LINK_API_KEY_CONSTANT = 'JsonLinkApiKey';

  /// returns the API key for the Google Maps
  @override
  Future<String> getMapsApiKey() => _getKey(MAPS_CONSTANT);

  /// returns the API key for the ZipCode API
  @override
  Future<String> getZipCodeApiKey() => _getKey(ZIP_CODE_CONSTANT);

  /// returns the API key for the Location API
  @override
  Future<String> getLocationApiKey() => _getKey(LOCATION_KEY_CONSTANT);

  /// returns the API key for the Json Link API
  @override
  Future<String> getJsonLinkApiKey() => _getKey(JSON_LINK_API_KEY_CONSTANT);
}
