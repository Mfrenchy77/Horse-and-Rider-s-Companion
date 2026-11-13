import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/location_picker.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';

class RiderLocation extends StatelessWidget {
  const RiderLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditRiderProfileCubit>();
        return LocationPicker(
          countryLabel: state.riderProfile?.countryName ?? 'Select Country',
          selectedCountry: state.selectedCountry,
          selectedState: state.selectedState,
          countryIso: state.countryIso,
          stateId: state.stateId,
          selectedCity: state.selectedCity,
          zipCode: state.zipCode.value,
          prediction: state.prediction,
          autoCompleteStatus: state.autoCompleteStatus,
          error: state.error,
          getCountries: cubit.getCountries,
          getStates: (countryIso) => cubit.getStates(countryIso: countryIso),
          getCities: (countryIso, stateIso) =>
              cubit.getCities(countryIso: countryIso, stateIso: stateIso),
          onCountrySelected: (country) => cubit.countrySelected(
            countryIso: country.iso2,
            country: country.name,
          ),
          onStateSelected: (selectedState) {
            cubit
              ..stateChanged(
                stateName: selectedState.name,
                stateId: selectedState.iso2!,
              )
              ..stateSelected(selectedState.name);
          },
          onCitySelected: (city) {
            cubit
              ..cityChanged(city: city.name)
              ..citySelected(city.name);
          },
          onZipCodeChanged: (zip) => cubit.riderZipCodeChanged(value: zip),
          onLocationSelected: (locationName, postalCode) {
            cubit
              ..toggleLocationSearch()
              ..locationSelected(
                locationName: locationName,
                selectedZipCode: postalCode,
              );
          },
        );
      },
    );
  }
}
