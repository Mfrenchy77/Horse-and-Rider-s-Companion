// ignore_for_file: lines_longer_than_80_chars

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class EditRiderProfileDialog extends StatelessWidget {
  const EditRiderProfileDialog({super.key, required this.riderProfile});
  final RiderProfile riderProfile;
  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => KeysRepository(),
        ),
        RepositoryProvider(
          create: (context) => CloudRepository(),
        ),
        RepositoryProvider(
          create: (context) => RiderProfileRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => EditRiderProfileCubit(
          keysRepository: context.read<KeysRepository>(),
          cloudRepository: context.read<CloudRepository>(),
          riderProfile: riderProfile,
          riderProfileRepository: context.read<RiderProfileRepository>(),
        ),
        child: BlocListener<EditRiderProfileCubit, EditRiderProfileState>(
          listener: (context, state) {
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                ).closed.then((_) {
                  context.read<EditRiderProfileCubit>().clearError();
                });
            }
          },
          child: BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
            builder: (context, state) {
              final cubit = context.read<EditRiderProfileCubit>();

              if (state.status == SubmissionStatus.success) {
                Navigator.pop(context);
              }
              return Scaffold(
                appBar: AppBar(
                  title: Text('Edit: ${riderProfile.name}'),
                ),
                backgroundColor: Colors.transparent,
                body: AlertDialog(
                  scrollable: true,
                  title: const Text('Edit Profile'),
                  content: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Form(
                      child: Column(
                        children: [
                          _profilePhoto(
                            state: state,
                            context: context,
                            size: isSmallScreen ? 85 : 150,
                          ),
                          gap(),
                          _riderName(
                            context: context,
                            state: state,
                          ),
                          gap(),
                          _riderBio(
                            context: context,
                            state: state,
                          ),
                          gap(),
                          _riderHomeUrl(
                            context: context,
                            state: state,
                          ),
                          gap(),
                          _riderLocation(
                            cubit: cubit,
                            context: context,
                            state: state,
                          ),
                          gap(),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    // cancel button with same color as background, teext color is primary text color
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Cancel',
                      ),
                    ),
                    Visibility(
                      visible: state.status != SubmissionStatus.inProgress,
                      child: FilledButton(
                        onPressed: () {
                          context
                              .read<EditRiderProfileCubit>()
                              .updateRiderProfile();
                        },
                        child: state.status == SubmissionStatus.inProgress
                            ? const CircularProgressIndicator()
                            : const Text('Submit'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

Widget _riderName({
  required BuildContext context,
  required EditRiderProfileState state,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderNameChanged(value: value),
    keyboardType: TextInputType.name,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    initialValue: state.riderName,
    decoration: const InputDecoration(
      labelText: "Rider's Name",
      hintText: "Enter Rider's Name",
      icon: Icon(Icons.person),
    ),
  );
}

Widget _riderHomeUrl({
  required BuildContext context,
  required EditRiderProfileState state,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderHomeUrlChanged(value: value),
    keyboardType: TextInputType.url,
    textInputAction: TextInputAction.next,
    initialValue: state.homeUrl,
    decoration: const InputDecoration(
      labelText: 'Website',
      hintText: 'Enter your buisness website',
      icon: Icon(Icons.public),
    ),
  );
}

Widget _riderBio({
  required BuildContext context,
  required EditRiderProfileState state,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderBioChanged(value: value),
    keyboardType: TextInputType.multiline,
    maxLines: 12,
    minLines: 3,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.sentences,
    initialValue: state.bio,
    decoration: const InputDecoration(
      labelText: "Rider's Bio",
      hintText: "Enter Rider's Bio",
      icon: Icon(Icons.person),
    ),
  );
}

Widget _riderLocation({
  required BuildContext context,
  required EditRiderProfileState state,
  required EditRiderProfileCubit cubit,
}) {
  final countryController = TextEditingController()
    ..text = state.selectedCountry ?? '';
  final stateController = TextEditingController()
    ..text = state.selectedState ?? '';
  final cityController = TextEditingController()
    ..text = state.selectedCity ?? '';
  final zipController = TextEditingController()..text = state.zipCode.value;
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
              labelText: state.riderProfile?.countryName ?? 'Select Country',
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
            final states = await cubit.getStates(countryIso: state.countryIso!);
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
                  final zipcodes = state.prediction!.results.keys.toList();

                  return zipcodes
                      .where(
                        (zip) =>
                            zip.toLowerCase().startsWith(pattern.toLowerCase()),
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
            else if (state.autoCompleteStatus == AutoCompleteStatus.success)
              SizedBox(
                width: double.maxFinite,
                height: 200,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.prediction?.results.length ?? 0,
                  itemBuilder: (context, index) {
                    final postalCode =
                        state.prediction?.results.keys.elementAt(index) ?? '';
                    final locations = state.prediction?.results[postalCode];
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
                                      'Location Selected ${location.city}',
                                    );
                                    cubit.locationSelected(
                                      locationName:
                                          '${location.city}, ${location.state}',
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
}

Widget _profilePhoto({
  required double size,
  required BuildContext context,
  required EditRiderProfileState state,
}) {
  final isDark = SharedPrefs().isDarkMode;
  return InkWell(
    onTap: () => context.read<EditRiderProfileCubit>().riderProfilePicClicked(),
    child: Column(
      children: [
        ///   Image
        if (state.isSubmitting)
          const CircularProgressIndicator()
        else
          CachedNetworkImage(
            imageUrl: '${state.picUrl}',
            placeholder: (context, url) =>
                const Image(image: AssetImage('assets/horse_icon_01.png')),
            errorWidget: (context, url, error) =>
                const Image(image: AssetImage('assets/horse_icon_01.png')),
            height: size,
            width: size,
          ),
        smallGap(),
        Text(
          state.riderProfile?.picUrl != null
              ? 'Tap to Change your Photo'
              : ' Tap to Add a Photo',
        ),
        smallGap(),
        Divider(
          color: isDark ? Colors.white : Colors.black,
          endIndent: 20,
          indent: 20,
        ),
        smallGap(),
      ],
    ),
  );
}
