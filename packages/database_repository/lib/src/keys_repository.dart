// ignore_for_file: constant_identifier_names

import 'package:firebase_remote_config/firebase_remote_config.dart';

///This class is responsible for managing the keys of the application
class KeysRepository {
  ///Instance of the Firebase Remote Config
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  ///Constant to refer to the API key for the Google Maps
  static const String MAPS_CONSTANT = 'MapsApiKey';

  /// Constant to refer to the API key for the ZipCode API
  static const String ZIP_CODE_CONSTANT = 'ZipApiKey';

  /// Constant to refer to the API key for the Location API
  static const String LOCATION_KEY_CONSTANT = 'LocationApiKey';

  /// Constant to refer to the API key for the Json Link API
  static const String JSON_LINK_API_KEY_CONSTANT = 'JsonLinkApiKey';

  /// returns the API key for the Google Maps
  Future<String> getMapsApiKey() async {
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString(MAPS_CONSTANT);
  }

  /// returns the API key for the ZipCode API
  Future<String> getZipCodeApiKey() async {
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString(ZIP_CODE_CONSTANT);
  }

  /// returns the API key for the Location API
  Future<String> getLocationApiKey() async {
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString(LOCATION_KEY_CONSTANT);
  }

  /// returns the API key for the Json Link API
  Future<String> getJsonLinkApiKey() async {
    await remoteConfig.fetchAndActivate();
    return remoteConfig.getString(JSON_LINK_API_KEY_CONSTANT);
  }
}
