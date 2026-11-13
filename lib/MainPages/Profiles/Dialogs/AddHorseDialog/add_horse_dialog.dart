// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:horseandriderscompanion/CommonWidgets/form_page_body.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/horse_details.dart';
import 'package:horseandriderscompanion/CommonWidgets/themed_app_bar.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Widgets/horse_height.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/EditProfileDialog/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

/// Dialog for adding a new horse profile or editing an existing one
class AddHorseDialog extends StatefulWidget {
  const AddHorseDialog({
    super.key,
    required this._editProfile,
    required RiderProfile userProfile,
    required this._horseProfile,
  }) : _usersProfile = userProfile;

  ///   If editProfile is true then we are editing an existing horse profile
  final bool _editProfile;

  ///   The user's profile
  final RiderProfile _usersProfile;

  ///   The horse profile to edit, if null then we are creating a new horse profile
  final HorseProfile? _horseProfile;

  @override
  State<AddHorseDialog> createState() => _AddHorseDialogState();
}

class _AddHorseDialogState extends State<AddHorseDialog> {
  final _heightController = TextEditingController();
  final _breedController = TextEditingController();
  final _dobController = TextEditingController();
  final _colorController = TextEditingController();
  final _purchaseDateController = TextEditingController();
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
    _heightController.dispose();
    _breedController.dispose();
    _dobController.dispose();
    _colorController.dispose();
    _purchaseDateController.dispose();
    _countryController.dispose();
    _stateController.dispose();
    _cityController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if horseProfile is null then we are creating a new horse profile
    // and editProfile should be false
    final existingKeysRepo = context.read<KeysRepository?>();
    final existingCloudRepo = context.read<CloudRepository?>();
    final existingRiderRepo = context.read<RiderProfileRepository?>();
    final existingHorseRepo = context.read<HorseProfileRepository?>();

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<KeysRepository>(
          create: (_) => existingKeysRepo ?? KeysRepository(),
        ),
        RepositoryProvider<CloudRepository>(
          create: (_) => existingCloudRepo ?? CloudRepository(),
        ),
        RepositoryProvider<RiderProfileRepository>(
          create: (_) => existingRiderRepo ?? RiderProfileRepository(),
        ),
        RepositoryProvider<HorseProfileRepository>(
          create: (_) => existingHorseRepo ?? HorseProfileRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => AddHorseDialogCubit(
          usersProfile: widget._usersProfile,
          horseProfile: widget._horseProfile,
          keysRepository: context.read<KeysRepository>(),
          cloudRepository: context.read<CloudRepository>(),
          horseProfileRepository: context.read<HorseProfileRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
        ),
        child: BlocBuilder<AddHorseDialogCubit, AddHorseDialogState>(
          builder: (context, state) {
            final cubit = context.read<AddHorseDialogCubit>();
            if (state.status == FormStatus.success) {
              Navigator.of(context).pop();
            }

            _syncController(_breedController, state.breed.value);
            _syncController(
              _dobController,
              state.dateOfBirth != null
                  ? DateFormat('MMMM dd yyyy').format(state.dateOfBirth!)
                  : '',
            );
            _syncController(_colorController, state.color.value);
            _syncController(
              _purchaseDateController,
              state.dateOfPurchase != null
                  ? DateFormat('MMMM dd yyyy').format(
                      DateTime.fromMillisecondsSinceEpoch(
                        state.dateOfPurchase as int,
                      ),
                    )
                  : '',
            );
            _syncController(_countryController, state.selectedCountry ?? '');
            _syncController(_stateController, state.selectedState ?? '');
            _syncController(_cityController, state.selectedCity ?? '');
            _syncController(_zipController, state.zipCode.value);

            return Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: ThemedAppBar(
                title: Text(
                  widget._editProfile
                      ? 'Edit Horse: ${state.horseProfile?.name}'
                      : 'Create New Horse Profile',
                ),
              ),
              body: FormPageBody(
                maxWidth: 800,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ///   Horse photo
                    _horsePhoto(context: context, size: 85, state: state),
                    gap(),

                    ///   Horse Name
                    _horseName(context: context, state: state),
                    gap(),

                    ///   Horse NickName
                    _horseNickName(context: context, state: state),
                    gap(),

                    ///  Horse Location
                    _horseLocation(
                      context: context,
                      state: state,
                      countryController: _countryController,
                      stateController: _stateController,
                      cityController: _cityController,
                      zipController: _zipController,
                    ),
                    gap(),

                    ///   Horse Gender
                    _horseGender(state: state, context: context),

                    ///   Horse Breed
                    _horseBreed(
                      state: state,
                      context: context,
                      breedController: _breedController,
                    ),
                    gap(),

                    ///   Horse Date of Birth
                    _horseDateOfBirth(
                      state: state,
                      cubit: cubit,
                      context: context,
                      dateText: _dobController,
                    ),
                    gap(),

                    ///   Horse Color
                    _horseColor(
                      state: state,
                      context: context,
                      controller: _colorController,
                    ),
                    gap(),

                    ///   Horse Height
                    HorseHeightField(controller: _heightController),
                    gap(),
                    _didPurchaseHorse(context: context, state: state),

                    gap(),

                    ///   Horse Purchase Date
                    _horsePurchaseDate(
                      cubit: cubit,
                      state: state,
                      context: context,
                      dateText: _purchaseDateController,
                    ),

                    gap(),

                    ///   HorsePurchase Price
                    _horsePurchasePrice(context: context, state: state),

                    errorText(state: state),
                    const SizedBox(height: 24),
                    OverflowBar(
                      alignment: MainAxisAlignment.end,
                      overflowAlignment: OverflowBarAlignment.end,
                      spacing: 8,
                      overflowSpacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                        _horseSubmitButton(
                          isEdit: widget._editProfile,
                          context: context,
                          state: state,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget errorText({required AddHorseDialogState state}) {
  if (state.status == FormStatus.failure) {
    return Text(
      state.error,
      style: const TextStyle(color: Colors.white, backgroundColor: Colors.red),
    );
  } else {
    return gap();
  }
}

Widget _didPurchaseHorse({
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  bool isPurchaced;

  state.isPurchacedStatus == IsPurchacedStatus.isPurchased
      ? isPurchaced = true
      : isPurchaced = false;
  return Material(
    color: Colors.transparent,
    child: CheckboxListTile(
      title: const Text('Did you purchse this horse?'),
      value: isPurchaced,
      onChanged: (value) {
        if (value != null) {
          context.read<AddHorseDialogCubit>().toogleIsPurchased(
            isPurchaced: value,
          );
        }
      },
    ),
  );
}

Widget _horseSubmitButton({
  required bool isEdit,
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return OutlinedButton(
    onPressed: state.horseName.value.isEmpty
        ? null
        : () {
            isEdit
                ? context.read<AddHorseDialogCubit>().editHorseProfile()
                : context.read<AddHorseDialogCubit>().createHorseProfile();
          },
    child: state.status == FormStatus.submitting
        ? const CircularProgressIndicator()
        : Text(
            isEdit
                ? "Update ${state.horseProfile?.name}'s Profile"
                : 'Submit Horse',
          ),
  );
}

Widget _horsePhoto({
  required BuildContext context,
  required double size,
  required AddHorseDialogState state,
}) {
  final isDark = SharedPrefs().isDarkMode;
  return InkWell(
    onTap: () => context.read<AddHorseDialogCubit>().horsePicButtonClicked(),
    child: Column(
      children: [
        ///   Image
        Visibility(
          visible: state.picStatus == PictureGetterStatus.picking,
          child: const CircularProgressIndicator(),
        ),
        Visibility(
          visible:
              state.picStatus == PictureGetterStatus.got ||
              state.picStatus == PictureGetterStatus.nothing,
          child: CachedNetworkImage(
            placeholderFadeInDuration: const Duration(milliseconds: 500),
            fadeOutDuration: const Duration(milliseconds: 500),
            imageUrl: state.picUrl,
            placeholder: (context, url) =>
                const Image(image: AssetImage('assets/horse_icon_01.png')),
            errorWidget: (context, url, error) =>
                const Image(image: AssetImage('assets/horse_icon_01.png')),
            height: size,
            width: size,
          ),
        ),
        smallGap(),
        const Text(
          ' Tap to Add a Photo of your Horse',
          style: TextStyle(fontSize: 12),
        ),
        smallGap(),
        Divider(
          color: isDark ? Colors.grey.shade300 : Colors.black87,
          endIndent: 20,
          indent: 20,
        ),
        smallGap(),
      ],
    ),
  );
}

Widget _horseName({
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<AddHorseDialogCubit>().horseNameChanged(value),
    keyboardType: TextInputType.name,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    initialValue: state.horseName.value,
    decoration: const InputDecoration(
      labelText: "Horse's Name",
      hintText: "Enter New Horse's Name",
      icon: Icon(HorseAndRiderIcons.horseIcon),
    ),
  );
}

Widget _horseNickName({
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return TextFormField(
    initialValue: state.horseNickname.value,
    onChanged: (value) =>
        context.read<AddHorseDialogCubit>().horseNicknameChanged(value),
    keyboardType: TextInputType.name,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    decoration: const InputDecoration(
      labelText: "Horse's NickName",
      hintText: "Enter New Horse's Nickname",
      icon: Icon(HorseAndRiderIcons.horseIcon),
    ),
  );
}

Widget _horseBreed({
  required AddHorseDialogState state,
  required BuildContext context,
  required TextEditingController breedController,
}) {
  return TypeAheadField<String>(
    hideOnEmpty: true,
    controller: breedController,
    suggestionsCallback: (pattern) {
      return HorseDetails.breeds
          .where((item) => item.toLowerCase().startsWith(pattern.toLowerCase()))
          .toList();
    },
    itemBuilder: (context, suggestion) {
      return ListTile(title: Text(suggestion));
    },
    onSelected: (suggestion) {
      breedController.text = suggestion;
      context.read<AddHorseDialogCubit>().horseBreedChanged(suggestion);
    },
    builder: (context, controller, focusNode) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          labelText: "Horse's Breed",
          hintText: "Enter Horse's Breed",
          icon: Icon(HorseAndRiderIcons.horseIcon),
        ),
      );
    },
    emptyBuilder: (context) => const Padding(
      padding: EdgeInsets.all(8),
      child: Text('No breeds found.'),
    ),
  );
}

Widget _horseDateOfBirth({
  required BuildContext context,
  required AddHorseDialogCubit cubit,
  required AddHorseDialogState state,
  required TextEditingController dateText,
}) {
  final initialDate = state.dateOfBirth ?? DateTime.now();

  return TextFormField(
    controller: dateText,
    keyboardType: TextInputType.datetime,
    textInputAction: TextInputAction.next,
    onTap: () async {
      FocusScope.of(context).unfocus();
      await showDatePicker(
        context: context,
        helpText: "Select Horse's Date of Birth",
        initialDate: initialDate,
        firstDate: DateTime(1995),
        lastDate: DateTime(2100),
      ).then((value) {
        debugPrint('DateofBirth: $value');
        if (value != null) {
          dateText.text = value.toString();
          if (state.horseProfile != null) {
            state.horseProfile?.dateOfBirth = value;
          }
          cubit.horseDateOfBirthChanged(value);
        }
      });
    },
    decoration: const InputDecoration(
      labelText: "Horse's Date of Birth",
      hintText: 'When was your Horse born',
      icon: Icon(Icons.date_range),
    ),
  );
}

Widget _horseColor({
  required BuildContext context,
  required AddHorseDialogState state,
  required TextEditingController controller,
}) {
  return TypeAheadField<String>(
    controller: controller,
    constraints: const BoxConstraints(maxHeight: 200),
    suggestionsCallback: (pattern) {
      return HorseDetails.colors
          .where((item) => item.toLowerCase().startsWith(pattern.toLowerCase()))
          .toList();
    },
    itemBuilder: (context, suggestion) {
      return ListTile(title: Text(suggestion));
    },
    onSelected: (suggestion) {
      controller.text = suggestion;
      context.read<AddHorseDialogCubit>().horseColorChanged(suggestion);
    },
    builder: (context, controller, focusNode) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          labelText: "Horse's Color",
          icon: Icon(Icons.color_lens),
        ),
      );
    },
    emptyBuilder: (context) => const Padding(
      padding: EdgeInsets.all(8),
      child: Text('No Suggestions'),
    ),
  );
}

//Widget that allows user to pick the gender of the horse and offers a list of
//options to choose from  Mare, Filly, Colt, Gelding, Stallion,
Widget _horseGender({
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return DropdownButtonFormField(
    initialValue: state.horseProfile?.gender ?? 'Mare',
    onChanged: (value) =>
        context.read<AddHorseDialogCubit>().horseGenderChanged(value as String),
    items: HorseDetails.genders
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    decoration: const InputDecoration(
      labelText: "Horse's Gender",
      hintText: "Choose Horse's Gender",
      icon: Icon(Icons.female),
    ),
  );
}

Widget _horsePurchaseDate({
  required BuildContext context,
  required AddHorseDialogCubit cubit,
  required AddHorseDialogState state,
  required TextEditingController dateText,
}) {
  final initialDate = state.dateOfPurchase != null
      ? DateTime.fromMillisecondsSinceEpoch(state.dateOfPurchase as int)
      : DateTime.now();

  return Visibility(
    visible: state.isPurchacedStatus == IsPurchacedStatus.isPurchased,
    child: TextFormField(
      controller: dateText,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      onTap: () async {
        FocusScope.of(context).unfocus();
        await showDatePicker(
          context: context,
          helpText: 'Select when you purchased horse',
          initialDate: initialDate,
          firstDate: DateTime(1995),
          lastDate: DateTime(2100),
        ).then((value) {
          if (value != null) {
            dateText.text = value.toString();
            if (state.horseProfile != null) {
              state.horseProfile?.dateOfPurchase = value;
            }
            cubit.horseDateOfPurchaseChanged(value);
          }
        });
      },
      decoration: const InputDecoration(
        labelText: "Horse's Date of Purchase",
        hintText: 'When did you get your Horse',
        icon: Icon(Icons.date_range),
      ),
    ),
  );
}

Widget _horseLocation({
  required BuildContext context,
  required AddHorseDialogState state,
  required TextEditingController countryController,
  required TextEditingController stateController,
  required TextEditingController cityController,
  required TextEditingController zipController,
}) {
  return Column(
    children: [
      // Country selection
      TypeAheadField<Country>(
        controller: countryController,
        constraints: const BoxConstraints(maxHeight: 200),
        suggestionsCallback: (pattern) async {
          final countries = await context
              .read<AddHorseDialogCubit>()
              .getCountries();
          // Filter the country names based on the pattern
          return countries
              .where(
                (country) => country.name.toLowerCase().startsWith(
                  pattern.toLowerCase(),
                ),
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
              labelText: state.horseProfile?.countryName ?? 'Select Country',
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
          context.read<AddHorseDialogCubit>().countryChanged(
            countryIso: country.iso2,
            countryName: country.name,
          );
        },
      ),

      // State selection (visible if a country is selected)
      if (state.selectedCountry != null)
        TypeAheadField<StateLocation>(
          controller: stateController,
          constraints: const BoxConstraints(maxHeight: 200),
          suggestionsCallback: (pattern) async {
            final states = await context.read<AddHorseDialogCubit>().getStates(
              countryIso: state.countryIso!,
            );
            // Filter the state names based on the pattern
            return states
                .where(
                  (state) => state.name.toLowerCase().startsWith(
                    pattern.toLowerCase(),
                  ),
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
            context.read<AddHorseDialogCubit>().stateChanged(
              stateName: state.name,
              stateId: state.iso2!,
            );
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
                final cities = await context
                    .read<AddHorseDialogCubit>()
                    .getCities(
                      countryIso: state.countryIso!,
                      stateIso: state.stateId!,
                    );
                // Filter the city names based on the pattern
                return cities
                    .where(
                      (city) => city.name.toLowerCase().startsWith(
                        pattern.toLowerCase(),
                      ),
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
                context.read<AddHorseDialogCubit>().cityChanged(
                  city: city.name,
                );
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
                  return ListTile(title: Text(zip));
                },
                onSelected: (zip) {
                  zipController.text = zip;
                  context.read<AddHorseDialogCubit>().zipCodeChanged(zip);
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
                    final controller = ExpansibleController();
                    return ExpansionTile(
                      controller: controller,
                      initiallyExpanded: true,
                      title: Text('Postal Code: $postalCode'),
                      children:
                          locations
                              ?.map(
                                (location) => ListTile(
                                  title: Text(location.city),
                                  subtitle: Text(
                                    '${location.city}, ${location.state}',
                                  ),
                                  onTap: () {
                                    context
                                        .read<AddHorseDialogCubit>()
                                        .toggleLocationSearch();
                                    controller.collapse();
                                    debugPrint(
                                      'Location Selected ${location.city}',
                                    );
                                    context
                                        .read<AddHorseDialogCubit>()
                                        .locationSelected(
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

Widget _horsePurchasePrice({
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return Visibility(
    visible: state.isPurchacedStatus == IsPurchacedStatus.isPurchased,
    child: TextFormField(
      initialValue: state.horseProfile?.purchasePrice.toString(),
      onChanged: (value) {
        final price = int.tryParse(value.trim()) ?? 0;
        context.read<AddHorseDialogCubit>().horsePurchasePriceChanged(price);
      },
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Purchase Price',
        hintText: "Enter Horse's Purchase Price",
        icon: Icon(Icons.attach_money_sharp),
      ),
    ),
  );
}
