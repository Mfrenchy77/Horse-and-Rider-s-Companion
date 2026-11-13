import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:horseandriderscompanion/CommonWidgets/location_picker.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Utilities/location_lookup_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeysRepository extends Mock implements KeysRepository {}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _MockZipcodeRepository extends Mock implements ZipcodeRepository {}

void main() {
  group('LocationLookupService', () {
    test('caches keys, countries, states, cities, and zip responses', () async {
      final keys = _MockKeysRepository();
      final locationRepo = _MockLocationRepository();
      final zipRepo = _MockZipcodeRepository();

      when(keys.getLocationApiKey).thenAnswer((_) async => 'loc-key');
      when(keys.getZipCodeApiKey).thenAnswer((_) async => 'zip-key');
      when(locationRepo.getCountries).thenAnswer(
        (_) async => [
          Country(id: 1, name: 'United States', iso2: 'US'),
        ],
      );
      when(() => locationRepo.getStates(countryIso: 'US')).thenAnswer(
        (_) async => [
          StateLocation(
            id: 1,
            name: 'Oregon',
            countryId: 1,
            countryCode: 'US',
            iso2: 'OR',
          ),
        ],
      );
      when(
        () => locationRepo.getCities(stateIso: 'OR', countryCode: 'US'),
      ).thenAnswer((_) async => [City(id: 1, name: 'Bend')]);
      when(
        () => zipRepo.queryZipcode(
          city: 'Bend',
          country: 'US',
          state: 'Oregon',
        ),
      ).thenAnswer(
        (_) async => ZipcodeApiResponse(
          query: const {'city': 'Bend'},
          results: PostalCodeResults(
            results: {
              '97701': [
                LocationInfo(
                  postalCode: '97701',
                  countryCode: 'US',
                  latitude: '44.0',
                  longitude: '-121.3',
                  city: 'Bend',
                  state: 'Oregon',
                  stateCode: 'OR',
                ),
              ],
            },
          ),
        ),
      );

      final service = LocationLookupService(
        keysRepository: keys,
        locationRepositoryBuilder: (_) => locationRepo,
        zipcodeRepositoryBuilder: (_) => zipRepo,
      );

      await service.getCountries();
      await service.getCountries();
      await service.getStates(countryIso: 'US');
      await service.getStates(countryIso: 'US');
      await service.getCities(countryIso: 'US', stateIso: 'OR');
      await service.getCities(countryIso: 'US', stateIso: 'OR');
      await service.queryZipcode(city: 'Bend', country: 'US', state: 'Oregon');
      await service.queryZipcode(city: 'Bend', country: 'US', state: 'Oregon');

      verify(keys.getLocationApiKey).called(1);
      verify(keys.getZipCodeApiKey).called(1);
      verify(locationRepo.getCountries).called(1);
      verify(() => locationRepo.getStates(countryIso: 'US')).called(1);
      verify(
        () => locationRepo.getCities(stateIso: 'OR', countryCode: 'US'),
      ).called(1);
      verify(
        () => zipRepo.queryZipcode(
          city: 'Bend',
          country: 'US',
          state: 'Oregon',
        ),
      ).called(1);
    });
  });

  group('LocationPicker', () {
    testWidgets('renders predictions and handles selection cleanly', (
      tester,
    ) async {
      String? selectedLocation;
      String? selectedPostalCode;
      final prediction = PostalCodeResults(
        results: {
          '97701': [
            LocationInfo(
              postalCode: '97701',
              countryCode: 'US',
              latitude: '44.0',
              longitude: '-121.3',
              city: 'Bend',
              state: 'Oregon',
              stateCode: 'OR',
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: LocationPicker(
                countryLabel: 'Select Country',
                selectedCountry: 'United States',
                selectedState: 'Oregon',
                countryIso: 'US',
                stateId: 'OR',
                selectedCity: 'Bend',
                zipCode: '',
                prediction: prediction,
                autoCompleteStatus: AutoCompleteStatus.success,
                error: '',
                getCountries: () async => const [],
                getStates: (_) async => const [],
                getCities: (_, _) async => const [],
                onCountrySelected: (_) {},
                onStateSelected: (_) {},
                onCitySelected: (_) {},
                onZipCodeChanged: (_) {},
                onLocationSelected: (locationName, postalCode) {
                  selectedLocation = locationName;
                  selectedPostalCode = postalCode;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Postal Code: 97701'), findsOneWidget);
      await tester.tap(find.text('Bend, Oregon'));
      await tester.pumpAndSettle();

      expect(selectedLocation, 'Bend, Oregon');
      expect(selectedPostalCode, '97701');
    });
  });
}
