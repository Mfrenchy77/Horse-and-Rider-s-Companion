import 'package:database_repository/database_repository.dart';

/// Shared location and API key lookup helper with in-memory caching.
class LocationLookupService {
  LocationLookupService({
    required this.keysRepository,
    LocationRepository Function(String apiKey)? locationRepositoryBuilder,
    ZipcodeRepository Function(String apiKey)? zipcodeRepositoryBuilder,
  }) : _locationRepositoryBuilder =
           locationRepositoryBuilder ?? _defaultLocationRepository,
       _zipcodeRepositoryBuilder =
           zipcodeRepositoryBuilder ?? _defaultZipcodeRepository;

  final ApiKeyProvider keysRepository;
  final LocationRepository Function(String apiKey) _locationRepositoryBuilder;
  final ZipcodeRepository Function(String apiKey) _zipcodeRepositoryBuilder;

  String? _locationApiKey;
  Future<String>? _locationKeyFuture;
  String? _zipApiKey;
  Future<String>? _zipKeyFuture;

  List<Country>? _countriesCache;
  final Map<String, List<StateLocation>> _statesCache = {};
  final Map<(String, String), List<City>> _citiesCache = {};
  final Map<(String, String, String), ZipcodeApiResponse?> _zipCache = {};

  static LocationRepository _defaultLocationRepository(String apiKey) {
    return LocationRepository(apiKey: apiKey);
  }

  static ZipcodeRepository _defaultZipcodeRepository(String apiKey) {
    return ZipcodeRepository(apiKey: apiKey);
  }

  /// Pre-fetches API keys without throwing if initial warm-up fails.
  void warmUp() {
    getZipCodeApiKey().catchError((_) => '');
    getLocationApiKey().catchError((_) => '');
  }

  Future<String> getLocationApiKey() {
    final cached = _locationApiKey;
    if (cached != null && cached.isNotEmpty) {
      return Future.value(cached);
    }
    final inFlight = _locationKeyFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = keysRepository.getLocationApiKey().then((value) {
      if (value.isNotEmpty) {
        _locationApiKey = value;
      }
      _locationKeyFuture = null;
      return value;
    }, onError: (Object error, StackTrace stackTrace) {
      _locationKeyFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _locationKeyFuture = future;
    return future;
  }

  Future<String> getZipCodeApiKey() {
    final cached = _zipApiKey;
    if (cached != null && cached.isNotEmpty) {
      return Future.value(cached);
    }
    final inFlight = _zipKeyFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = keysRepository.getZipCodeApiKey().then((value) {
      if (value.isNotEmpty) {
        _zipApiKey = value;
      }
      _zipKeyFuture = null;
      return value;
    }, onError: (Object error, StackTrace stackTrace) {
      _zipKeyFuture = null;
      Error.throwWithStackTrace(error, stackTrace);
    });
    _zipKeyFuture = future;
    return future;
  }

  Future<List<Country>> getCountries() async {
    final cached = _countriesCache;
    if (cached != null) {
      return cached;
    }
    final apiKey = await getLocationApiKey();
    final countries = await _locationRepositoryBuilder(apiKey).getCountries();
    _countriesCache = countries;
    return countries;
  }

  Future<List<StateLocation>> getStates({required String countryIso}) async {
    final cached = _statesCache[countryIso];
    if (cached != null) {
      return cached;
    }
    final apiKey = await getLocationApiKey();
    final states = await _locationRepositoryBuilder(
      apiKey,
    ).getStates(countryIso: countryIso);
    _statesCache[countryIso] = states;
    return states;
  }

  Future<List<City>> getCities({
    required String countryIso,
    required String stateIso,
  }) async {
    final key = (countryIso, stateIso);
    final cached = _citiesCache[key];
    if (cached != null) {
      return cached;
    }
    final apiKey = await getLocationApiKey();
    final cities = await _locationRepositoryBuilder(
      apiKey,
    ).getCities(stateIso: stateIso, countryCode: countryIso);
    _citiesCache[key] = cities;
    return cities;
  }

  Future<ZipcodeApiResponse?> queryZipcode({
    required String city,
    required String country,
    required String state,
  }) async {
    final key = (country, state, city);
    if (_zipCache.containsKey(key)) {
      return _zipCache[key];
    }
    final apiKey = await getZipCodeApiKey();
    final response = await _zipcodeRepositoryBuilder(
      apiKey,
    ).queryZipcode(city: city, country: country, state: state);
    if (response != null) {
      _zipCache[key] = response;
    }
    return response;
  }
}
