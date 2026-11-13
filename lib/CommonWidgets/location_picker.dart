import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

/// Reusable cascading Country -> State -> City -> Postal Code picker.
class LocationPicker extends StatefulWidget {
  const LocationPicker({
    super.key,
    required this.countryLabel,
    required this.selectedCountry,
    required this.selectedState,
    required this.countryIso,
    required this.stateId,
    required this.selectedCity,
    required this.zipCode,
    required this.prediction,
    required this.autoCompleteStatus,
    required this.error,
    required this.getCountries,
    required this.getStates,
    required this.getCities,
    required this.onCountrySelected,
    required this.onStateSelected,
    required this.onCitySelected,
    required this.onZipCodeChanged,
    required this.onLocationSelected,
  });

  final String countryLabel;
  final String? selectedCountry;
  final String? selectedState;
  final String? countryIso;
  final String? stateId;
  final String? selectedCity;
  final String zipCode;
  final PostalCodeResults? prediction;
  final AutoCompleteStatus autoCompleteStatus;
  final String error;
  final Future<List<Country>> Function() getCountries;
  final Future<List<StateLocation>> Function(String countryIso) getStates;
  final Future<List<City>> Function(String countryIso, String stateIso)
  getCities;
  final void Function(Country country) onCountrySelected;
  final void Function(StateLocation state) onStateSelected;
  final void Function(City city) onCitySelected;
  final void Function(String zip) onZipCodeChanged;
  final void Function(String locationName, String postalCode)
  onLocationSelected;

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  final _countryController = TextEditingController();
  final _stateController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipController = TextEditingController();

  void _syncController(TextEditingController controller, String value) {
    if (controller.text != value) {
      controller.text = value;
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _syncController(_countryController, widget.selectedCountry ?? '');
    _syncController(_stateController, widget.selectedState ?? '');
    _syncController(_cityController, widget.selectedCity ?? '');
    _syncController(_zipController, widget.zipCode);

    return Column(
      children: [
        TypeAheadField<Country>(
          controller: _countryController,
          constraints: const BoxConstraints(maxHeight: 200),
          suggestionsCallback: (pattern) async {
            final countries = await widget.getCountries();
            final lowerPattern = pattern.toLowerCase();
            return countries
                .where(
                  (country) =>
                      country.name.toLowerCase().startsWith(lowerPattern),
                )
                .toList();
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                icon: const Icon(Icons.public),
                border: const UnderlineInputBorder(),
                labelText: widget.countryLabel,
              ),
            );
          },
          itemBuilder: (context, country) {
            return ListTile(
              title: Text(country.name),
              subtitle: Text(country.iso2),
            );
          },
          onSelected: (country) {
            _countryController.text = country.name;
            widget.onCountrySelected(country);
          },
        ),
        if (widget.selectedCountry != null)
          TypeAheadField<StateLocation>(
            controller: _stateController,
            constraints: const BoxConstraints(maxHeight: 200),
            suggestionsCallback: (pattern) async {
              final states = await widget.getStates(widget.countryIso!);
              final lowerPattern = pattern.toLowerCase();
              return states
                  .where(
                    (state) =>
                        state.name.toLowerCase().startsWith(lowerPattern),
                  )
                  .toList();
            },
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.flag),
                  border: UnderlineInputBorder(),
                  labelText: 'State',
                ),
              );
            },
            itemBuilder: (context, state) {
              return ListTile(
                title: Text(state.name),
                subtitle: Text(state.iso2 ?? ''),
              );
            },
            onSelected: (state) {
              _stateController.text = state.name;
              widget.onStateSelected(state);
            },
          ),
        if (widget.selectedState != null)
          Column(
            children: [
              TypeAheadField<City>(
                controller: _cityController,
                constraints: const BoxConstraints(maxHeight: 200),
                suggestionsCallback: (pattern) async {
                  final cities = await widget.getCities(
                    widget.countryIso!,
                    widget.stateId!,
                  );
                  final lowerPattern = pattern.toLowerCase();
                  return cities
                      .where(
                        (city) =>
                            city.name.toLowerCase().startsWith(lowerPattern),
                      )
                      .toList();
                },
                builder: (context, controller, focusNode) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      icon: Icon(Icons.location_city),
                      border: UnderlineInputBorder(),
                      labelText: 'City',
                    ),
                  );
                },
                itemBuilder: (context, city) {
                  return ListTile(
                    title: Text(city.name),
                    subtitle: Text(city.id.toString()),
                  );
                },
                onSelected: (city) {
                  _cityController.text = city.name;
                  widget.onCitySelected(city);
                },
              ),
              if (widget.prediction != null)
                TypeAheadField<String>(
                  controller: _zipController,
                  constraints: const BoxConstraints(maxHeight: 200),
                  suggestionsCallback: (pattern) async {
                    final zipcodes = widget.prediction!.results.keys.toList();
                    final lowerPattern = pattern.toLowerCase();
                    return zipcodes
                        .where(
                          (zip) => zip.toLowerCase().startsWith(lowerPattern),
                        )
                        .toList();
                  },
                  builder: (context, controller, focusNode) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.location_city),
                        border: UnderlineInputBorder(),
                        labelText: 'Zip Code',
                      ),
                    );
                  },
                  itemBuilder: (context, zip) {
                    return ListTile(title: Text(zip));
                  },
                  onSelected: (String zip) {
                    _zipController.text = zip;
                    widget.onZipCodeChanged(zip);
                  },
                ),
              if (widget.autoCompleteStatus == AutoCompleteStatus.loading)
                const CircularProgressIndicator()
              else if (widget.autoCompleteStatus == AutoCompleteStatus.success)
                SizedBox(
                  width: double.maxFinite,
                  height: 200,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.prediction?.results.length ?? 0,
                    itemBuilder: (context, index) {
                      final postalCode =
                          widget.prediction?.results.keys.elementAt(index) ??
                          '';
                      final locations = widget.prediction?.results[postalCode];
                      return _PostalCodePredictionTile(
                        key: ValueKey(postalCode),
                        postalCode: postalCode,
                        locations: locations,
                        onLocationSelected: widget.onLocationSelected,
                      );
                    },
                  ),
                )
              else if (widget.autoCompleteStatus == AutoCompleteStatus.error)
                ColoredBox(
                  color: Colors.red,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      widget.error,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _PostalCodePredictionTile extends StatefulWidget {
  const _PostalCodePredictionTile({
    super.key,
    required this.postalCode,
    required this.locations,
    required this.onLocationSelected,
  });

  final String postalCode;
  final List<LocationInfo>? locations;
  final void Function(String locationName, String postalCode)
  onLocationSelected;

  @override
  State<_PostalCodePredictionTile> createState() =>
      _PostalCodePredictionTileState();
}

class _PostalCodePredictionTileState extends State<_PostalCodePredictionTile> {
  final ExpansibleController _controller = ExpansibleController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locations = widget.locations;
    return ExpansionTile(
      controller: _controller,
      initiallyExpanded: true,
      title: Text('Postal Code: ${widget.postalCode}'),
      children:
          locations
              ?.map(
                (location) => ListTile(
                  title: Text(location.city),
                  subtitle: Text('${location.city}, ${location.state}'),
                  onTap: () {
                    _controller.collapse();
                    debugPrint('Location Selected ${location.city}');
                    widget.onLocationSelected(
                      '${location.city}, ${location.state}',
                      widget.postalCode,
                    );
                  },
                ),
              )
              .toList() ??
          const [Text('No locations found')],
    );
  }
}
