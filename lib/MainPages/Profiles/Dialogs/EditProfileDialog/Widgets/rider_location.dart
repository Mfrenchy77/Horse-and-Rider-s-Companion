import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

class RiderLocation extends StatelessWidget {
  const RiderLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        final countryController = TextEditingController()
          ..text = state.selectedCountry ?? '';
        final stateController = TextEditingController()
          ..text = state.selectedState ?? '';
        final cityController = TextEditingController()
          ..text = state.selectedCity ?? '';
        final zipController = TextEditingController()
          ..text = state.zipCode.value;
        return Column(
          children: [
            // Country selection
            TypeAheadField<Country>(
              controller: countryController,
              constraints: const BoxConstraints(maxHeight: 200),
              suggestionsCallback: (pattern) async {
                final countries = await cubit.getCountries();
                // Filter the country names based on the pattern
                return countries
                    .where(
                      (country) => country.name
                          .toLowerCase()
                          .startsWith(pattern.toLowerCase()),
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
                    labelText:
                        state.riderProfile?.countryName ?? 'Select Country',
                  ),
                );
              },
              itemBuilder: (context, Country country) {
                return ListTile(
                  title: Text(country.name),
                  subtitle: Text(country.iso2),
                );
              },
              onSelected: (country) {
                countryController.text = country.name;
                cubit.countrySelected(
                  countryIso: country.iso2,
                  country: country.name,
                );
              },
            ),

            // State selection (visible if a country is selected)
            if (state.selectedCountry != null)
              TypeAheadField<StateLocation>(
                controller: stateController,
                constraints: const BoxConstraints(maxHeight: 200),
                suggestionsCallback: (pattern) async {
                  final states =
                      await cubit.getStates(countryIso: state.countryIso!);
                  // Filter the state names based on the pattern
                  return states
                      .where(
                        (state) => state.name
                            .toLowerCase()
                            .startsWith(pattern.toLowerCase()),
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
                  stateController.text = state.name;
                  cubit
                    ..stateChanged(
                      stateName: state.name,
                      stateId: state.iso2!,
                    )
                    ..stateSelected(state.name);
                },
              ),

            // City selection (visible if a state is selected)
            if (state.selectedState != null)
              Column(
                children: [
                  TypeAheadField<City>(
                    controller: cityController,
                    constraints: const BoxConstraints(maxHeight: 200),
                    suggestionsCallback: (pattern) async {
                      final cities = await cubit.getCities(
                        countryIso: state.countryIso!,
                        stateIso: state.stateId!,
                      );
                      // Filter the city names based on the pattern
                      return cities
                          .where(
                            (city) => city.name
                                .toLowerCase()
                                .startsWith(pattern.toLowerCase()),
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
                      cityController.text = city.name;
                      cubit
                        ..cityChanged(
                          city: city.name,
                        )
                        ..citySelected(city.name);
                    },
                  ),
                  if (state.prediction != null)
                    TypeAheadField<String>(
                      controller: zipController,
                      constraints: const BoxConstraints(maxHeight: 200),
                      suggestionsCallback: (pattern) async {
                        final zipcodes =
                            state.prediction!.results.keys.toList();

                        return zipcodes
                            .where(
                              (zip) => zip
                                  .toLowerCase()
                                  .startsWith(pattern.toLowerCase()),
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
                        return ListTile(
                          title: Text(zip),
                        );
                      },
                      onSelected: (zip) {
                        zipController.text = zip;
                        cubit.riderZipCodeChanged(value: zip);
                      },
                    ),
                  if (state.autoCompleteStatus == AutoCompleteStatus.loading)
                    const CircularProgressIndicator()
                  else if (state.autoCompleteStatus ==
                      AutoCompleteStatus.success)
                    SizedBox(
                      width: double.maxFinite,
                      height: 200,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: state.prediction?.results.length ?? 0,
                        itemBuilder: (context, index) {
                          final postalCode =
                              state.prediction?.results.keys.elementAt(index) ??
                                  '';
                          final locations =
                              state.prediction?.results[postalCode];
                          final controller = ExpansionTileController();
                          return ExpansionTile(
                            controller: controller,
                            initiallyExpanded: true,
                            title: Text('Postal Code: $postalCode'),
                            children: locations
                                    ?.map(
                                      (location) => ListTile(
                                        title: Text(location.city),
                                        subtitle: Text(
                                          '${location.city}, ${location.state}',
                                        ),
                                        onTap: () {
                                          cubit.toggleLocationSearch();
                                          controller.collapse();
                                          debugPrint(
                                            'Location Selected '
                                            '${location.city}',
                                          );
                                          cubit.locationSelected(
                                            locationName: '${location.city}, '
                                                '${location.state}',
                                            selectedZipCode: postalCode,
                                          );
                                        },
                                      ),
                                    )
                                    .toList() ??
                                [const Text('No locations found')],
                          );
                        },
                      ),
                    )
                  else if (state.autoCompleteStatus == AutoCompleteStatus.error)
                    ColoredBox(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          state.error,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }
}
