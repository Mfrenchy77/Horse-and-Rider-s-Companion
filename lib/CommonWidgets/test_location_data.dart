import 'package:database_repository/database_repository.dart';

/// Test class to generate 10 [Country] objects and 10 [StateLocation] objects.
/// and 10 [City] objects.
class TestLocationData {
  static List<Country> generateTestCountries(int count) {
    return List.generate(
      count,
      (index) => Country(
        id: index,
        name: 'Country $index',
        iso2: 'C$index',
      ),
    );
  }

  static List<StateLocation> generateTestStates(int count) {
    return List.generate(
      count,
      (index) => StateLocation(
        countryCode: 'C$index',
        id: index,
        name: 'State $index',
        countryId: index,
        iso2: 'S$index',
      ),
    );
  }

  static List<City> generateTestCities(int count) {
    return List.generate(
      count,
      (index) => City(
        id: index,
        name: 'City $index',
      ),
    );
  }
}
