// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/horse_details.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/EditProfile/Cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:responsive_framework/responsive_framework.dart';

class AddHorseDialog extends StatelessWidget {
  const AddHorseDialog({
    super.key,
    required bool editProfile,
    required RiderProfile userProfile,
    required HorseProfile? horseProfile,
  })  : _editProfile = editProfile,
        _usersProfile = userProfile,
        _horseProfile = horseProfile;

  final bool _editProfile;
  final RiderProfile _usersProfile;
  final HorseProfile? _horseProfile;

  @override
  Widget build(BuildContext context) {
// if horseProfile is null then we are creating a new horse profile
// and editProfile should be false

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => KeysRepository()),
        RepositoryProvider(create: (context) => CloudRepository()),
        RepositoryProvider(create: (context) => RiderProfileRepository()),
        RepositoryProvider(create: (context) => HorseProfileRepository()),
      ],
      child: BlocProvider(
        create: (context) => AddHorseDialogCubit(
          usersProfile: _usersProfile,
          horseProfile: _horseProfile,
          keysRepository: context.read<KeysRepository>(),
          horseProfileRepository: context.read<HorseProfileRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
        ),
        child: BlocBuilder<AddHorseDialogCubit, AddHorseDialogState>(
          builder: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              Navigator.of(context).pop();
            }

            return Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                title: Text(
                  _editProfile
                      ? 'Edit Horse: ${state.horseProfile?.name}'
                      : 'Create New Horse Profile',
                ),
              ),
              body: AlertDialog(
                insetPadding: const EdgeInsets.all(10),
                scrollable: true,
                // titleTextStyle: FONT_CONST.MEDIUM_WHITE,
                // title: const Text('Create New Horse Profile'),
                content: MaxWidthBox(
                  maxWidth: 800,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ///   Horse photo
                      _horsePhoto(context: context, size: 85, state: state),
                      gap(),

                      ///   Horse Name
                      _horseName(
                        context: context,
                        state: state,
                      ),
                      gap(),

                      ///   Horse NickName
                      _horseNickName(
                        context: context,
                        state: state,
                      ),
                      gap(),

                      ///  Horse Location
                      _horseLocation(
                        context: context,
                        state: state,
                      ),
                      gap(),

                      ///   Horse Gender
                      _horseGender(
                        state: state,
                        context: context,
                      ),

                      ///   Horse Breed
                      _horseBreed(
                        state: state,
                        context: context,
                      ),
                      gap(),

                      ///   Horse Date of Birth

                      _horseDateOfBirth(
                        state: state,
                        context: context,
                      ),
                      gap(),

                      ///   Horse Color
                      _horseColor(
                        state: state,
                        context: context,
                      ),
                      gap(),

                      ///   Horse Height
                      _horseHeight(
                        state: state,
                        buildContext: context,
                      ),
                      gap(),
                      _didPurchaseHorse(context: context, state: state),

                      gap(),

                      ///   Horse Purchase Date
                      _horsePurchaseDate(
                        context: context,
                        state: state,
                      ),

                      gap(),

                      ///   HorsePurchase Price
                      _horsePurchasePrice(
                        context: context,
                        state: state,
                      ),

                      errorText(state: state),
                    ],
                  ),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  _horseSubmitButton(
                    isEdit: _editProfile,
                    context: context,
                    state: state,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

Widget errorText({required AddHorseDialogState state}) {
  if (state.status == FormzStatus.submissionFailure) {
    return Text(
      state.error,
      style: const TextStyle(
        color: Colors.white,
        backgroundColor: Colors.red,
      ),
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
  return CheckboxListTile(
    title: const Text('Did you purchse this horse?'),
    value: isPurchaced,
    onChanged: (value) {
      if (value != null) {
        context
            .read<AddHorseDialogCubit>()
            .toogleIsPurchased(isPurchaced: value);
      }
    },
  );
}

Widget _horseSubmitButton({
  required bool isEdit,
  required BuildContext context,
  required AddHorseDialogState state,
}) {
  return FilledButton(
    onPressed: state.horseName.value.isEmpty
        ? null
        : () {
            isEdit
                ? context.read<AddHorseDialogCubit>().editHorseProfile()
                : context.read<AddHorseDialogCubit>().createHorseProfile();
          },
    child: state.status == FormzStatus.submissionInProgress
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
          visible: state.picStatus == PictureGetterStatus.got ||
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
}) {
  final breedController = TextEditingController()..text = state.breed.value;
  return TypeAheadField<String>(
    controller: breedController,
    suggestionsCallback: (pattern) {
      return HorseDetails.breeds
          .where(
            (item) => item.toLowerCase().startsWith(pattern.toLowerCase()),
          )
          .toList();
    },
    itemBuilder: (context, suggestion) {
      return ListTile(
        title: Text(suggestion),
      );
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
  required AddHorseDialogState state,
}) {
  final initialDate = state.dateOfBirth ?? DateTime.now();

  final dateText = TextEditingController(
    text: state.dateOfBirth != null
        ? DateFormat('MMMM dd yyyy').format(state.dateOfBirth!)
        : null,
  );

  return TextFormField(
    controller: dateText,
    keyboardType: TextInputType.datetime,
    textInputAction: TextInputAction.next,
    onTap: () async {
      FocusScope.of(context).requestFocus(FocusNode());
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
          context.read<AddHorseDialogCubit>().horseDateOfBirthChanged(value);
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
}) {
  final controller = TextEditingController()..text = state.color.value;
  return TypeAheadField<String>(
    controller: controller,
    constraints: const BoxConstraints(maxHeight: 200),
    suggestionsCallback: (pattern) {
      return HorseDetails.colors
          .where(
            (item) => item.toLowerCase().startsWith(pattern.toLowerCase()),
          )
          .toList();
    },
    itemBuilder: (context, suggestion) {
      return ListTile(
        title: Text(suggestion),
      );
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
    value: state.horseProfile?.gender ?? 'Mare',
    onChanged: (value) =>
        context.read<AddHorseDialogCubit>().horseGenderChanged(value as String),
    items: HorseDetails.genders
        .map(
          (e) => DropdownMenuItem(
            value: e,
            child: Text(e),
          ),
        )
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
  required AddHorseDialogState state,
}) {
  final initialDate = state.dateOfPurchase != null
      ? DateTime.fromMillisecondsSinceEpoch(state.dateOfPurchase as int)
      : DateTime.now();
  if (state.horseProfile != null) {
    context
        .read<AddHorseDialogCubit>()
        .horseDateOfPurchaseChanged(state.horseProfile?.dateOfPurchase);
  }

  final dateOfPurchase = state.dateOfPurchase != null
      ? DateFormat('MMMM dd yyyy').format(
          DateTime.fromMillisecondsSinceEpoch(
            state.dateOfPurchase as int,
          ),
        )
      : '';

  final dateText = TextEditingController(text: dateOfPurchase);

  return Visibility(
    visible: state.isPurchacedStatus == IsPurchacedStatus.isPurchased,
    child: TextFormField(
      controller: dateText,
      keyboardType: TextInputType.datetime,
      textInputAction: TextInputAction.next,
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode());
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
            context
                .read<AddHorseDialogCubit>()
                .horseDateOfPurchaseChanged(value);
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
          final countries =
              await context.read<AddHorseDialogCubit>().getCountries();
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
            final states = await context
                .read<AddHorseDialogCubit>()
                .getStates(countryIso: state.countryIso!);
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
                final cities =
                    await context.read<AddHorseDialogCubit>().getCities(
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
                  return ListTile(
                    title: Text(zip),
                  );
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
        final price = int.parse(value);
        context.read<AddHorseDialogCubit>().horsePurchasePriceChanged(price);
      },
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: 'Purchase Price',
        hintText: "Enter Horse's Purchase Price",
        icon: Icon(Icons.attach_money_sharp),
      ),
    ),
  );
}

//FIXME: Lets make this centemeter by default and hands by choice in the settings
Widget _horseHeight({
  required BuildContext buildContext,
  required AddHorseDialogState state,
}) {
  final isDark = SharedPrefs().isDarkMode;
  final heightText = TextEditingController(
    text: state.horseProfile != null
        ? state.horseProfile?.height
        : state.height.value,
  );

  var handsValue = state.horseProfile != null
      ? int.parse(
          state.horseProfile?.height?.toString().substring(0, 2) ?? '14',
        )
      : state.handsValue;

  var inchesValue = state.horseProfile != null
      ? int.parse(
          state.horseProfile?.height?.toString().substring(3) ?? '0',
        )
      : state.inchesValue;

  return TextFormField(
    keyboardType: TextInputType.name,
    textInputAction: TextInputAction.next,
    decoration: const InputDecoration(
      labelText: "Horse's Height",
      hintText: "Enter Horse's Height",
      icon: Icon(HorseAndRiderIcons.ruler),
    ),
    controller: heightText,
    onTap: () async {
      FocusScope.of(buildContext).requestFocus(FocusNode());

      String height;
      await showDialog<String>(
        context: buildContext,
        builder: (context) {
          return AlertDialog(
            actions: [
              ElevatedButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(buildContext).pop();
                  heightText.text = state.height.value;
                },
              ),
            ],
            backgroundColor:
                HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
            title: Text(
              "Choose Horse's Height",
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            content: StatefulBuilder(
              builder: (context, setState) {
                return IntrinsicHeight(
                  child: Row(
                    children: [
                      ///Hands
                      Card(
                        elevation: 8,
                        color: HorseAndRidersTheme()
                            .getTheme()
                            .scaffoldBackgroundColor,
                        child: NumberPicker(
                          minValue: 5,
                          maxValue: 19,
                          value: handsValue,
                          onChanged: (value) {
                            setState(
                              () {
                                buildContext
                                    .read<AddHorseDialogCubit>()
                                    .handsChanged(value);
                                handsValue = value;
                                height = '$handsValue.$inchesValue';
                                if (state.horseProfile != null) {
                                  state.horseProfile?.height = height;
                                }
                                buildContext
                                    .read<AddHorseDialogCubit>()
                                    .horseHeightChanged(height);
                              },
                            );
                          },
                        ),
                      ),
                      VerticalDivider(
                        color: isDark ? Colors.white : Colors.black,
                        endIndent: 20,
                        indent: 20,
                      ),

                      ///   Inches
                      Card(
                        elevation: 8,
                        color: HorseAndRidersTheme()
                            .getTheme()
                            .scaffoldBackgroundColor,
                        child: NumberPicker(
                          minValue: 0,
                          maxValue: 3,
                          value: inchesValue,
                          onChanged: (value) {
                            setState(
                              () {
                                buildContext
                                    .read<AddHorseDialogCubit>()
                                    .inchesChanged(value);
                                inchesValue = value;

                                height = '$handsValue.$inchesValue';
                                debugPrint(height);
                                heightText.text = height;
                                final horseProfile = state.horseProfile;
                                if (horseProfile != null) {
                                  horseProfile.height = height;
                                }
                                buildContext
                                    .read<AddHorseDialogCubit>()
                                    .horseHeightChanged(height);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ).then((value) {
        debugPrint('Value: $value');
        height = '$handsValue.$inchesValue';
        state.horseProfile?.copyWith(height: height);
        buildContext.read<AddHorseDialogCubit>().horseHeightChanged(height);
        heightText.text = state.height.value;
        // setState(() {
        //   heightText.text = height;
        // });
      });
    },
  );
}
