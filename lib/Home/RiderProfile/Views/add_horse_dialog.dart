// ignore_for_file: cast_nullable_to_non_nullable

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/horse_details.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';

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

    final isSmallScreen = MediaQuery.of(context).size.width < 600;
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
                content: isSmallScreen
                    ? Column(
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

                          ///   Submit Horse Button
                          _horseSubmitButton(
                            isEdit: _editProfile,
                            context: context,
                            state: state,
                          ),
                        ],
                      )

                    ///LARRRGE SCREEN
                    : Card(
                        margin: const EdgeInsets.all(20),
                        elevation: 8,
                        child: SingleChildScrollView(
                          reverse: true,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              gap(),
                              _horsePhoto(
                                context: context,
                                size: 150,
                                state: state,
                              ),
                              gap(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  gap(),
                                  Expanded(
                                    child: _horseName(
                                      context: context,
                                      state: state,
                                    ),
                                  ),
                                  gap(),
                                  Expanded(
                                    child: _horseNickName(
                                      context: context,
                                      state: state,
                                    ),
                                  ),
                                  gap(),
                                ],
                              ),
                              gap(),
                              _horseLocation(
                                context: context,
                                state: state,
                              ),
                              gap(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _horseGender(
                                    state: state,
                                    context: context,
                                  ),
                                  gap(),
                                  Expanded(
                                    child: _horseBreed(
                                      state: state,
                                      context: context,
                                    ),
                                  ),
                                  gap(),
                                  Expanded(
                                    child: _horseDateOfBirth(
                                      context: context,
                                      state: state,
                                    ),
                                  ),
                                ],
                              ),
                              gap(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  gap(),
                                  Expanded(
                                    child: _horseColor(
                                      state: state,
                                      context: context,
                                    ),
                                  ),
                                  gap(),
                                  Expanded(
                                    child: _horseHeight(
                                      state: state,
                                      buildContext: context,
                                    ),
                                  ),
                                  // gap(),
                                  // _didPurchaseHorse(
                                  //   context: context,
                                  //   state: state,
                                  // ),
                                ],
                              ),
                              gap(),
                              _didPurchaseHorse(
                                context: context,
                                state: state,
                              ),
                              gap(),
                              Row(
                                children: [
                                  Expanded(
                                    child: _horsePurchasePrice(
                                      context: context,
                                      state: state,
                                    ),
                                  ),
                                  Expanded(
                                    child: _horsePurchaseDate(
                                      context: context,
                                      state: state,
                                    ),
                                  ),
                                ],
                              ),
                              errorText(state: state),
                              _horseSubmitButton(
                                isEdit: _editProfile,
                                context: context,
                                state: state,
                              ),
                              gap(),
                            ],
                          ),
                        ),
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
  return ElevatedButton(
    onPressed:
        // state.horseName.value.isEmpty
        //     ? null
        // :
        () {
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
        CachedNetworkImage(
          imageUrl: '${state.horseProfile?.picUrl}',
          placeholder: (context, url) =>
              const Image(image: AssetImage('assets/horse_icon_01.png')),
          errorWidget: (context, url, error) =>
              const Image(image: AssetImage('assets/horse_icon_01.png')),
          height: size,
          width: size,
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
  final breedController = TextEditingController()
    ..text = state.horseProfile?.breed ?? '';
  return TypeAheadField<String>(
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
  final initialDate = state.dateOfBirth != null
      ? DateTime.fromMillisecondsSinceEpoch(state.dateOfBirth as int)
      : DateTime.now();

  final dateText = TextEditingController(
    text: state.horseProfile?.dateOfBirth != null
        ? DateFormat('MMMM dd yyyy')
            .format(state.horseProfile?.dateOfBirth as DateTime)
        : state.dateOfBirth != null
            ? DateFormat('MMMM dd yyyy').format(
                DateTime.fromMillisecondsSinceEpoch(state.dateOfBirth as int),
              )
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
  final colorController = TextEditingController()
    ..text = state.horseProfile?.color ?? '';

  return TypeAheadField<String>(
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
      colorController.text = suggestion;
      context.read<AddHorseDialogCubit>().horseColorChanged(suggestion);
    },
    builder: (context, controller, focusNode) {
      return TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: const InputDecoration(
          labelText: "Horse's Color",
          hintText: "Enter Horse's color",
          icon: Icon(Icons.color_lens),
        ),
      );
    },
    emptyBuilder: (context) => const Padding(
      padding: EdgeInsets.all(8),
      child: Text('No colors found.'),
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
      constraints: BoxConstraints(maxWidth: 200),
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
  return Column(
    children: [
      // Country selection
      TypeAheadField<Country>(
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
            decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Country',
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
          context.read<AddHorseDialogCubit>().countryChanged(
                countryIso: country.iso2,
                countryName: country.name,
              );
        },
      ),

      // State selection (visible if a country is selected)
      if (state.selectedCountry != null)
        TypeAheadField<StateLocation>(
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
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
                border: UnderlineInputBorder(),
                labelText: 'State',
              ),
            );
          },
          itemBuilder: (context, state) {
            return ListTile(
              title: Text(state.name),
              subtitle: Text(state.iso2),
            );
          },
          onSelected: (state) {
            context.read<AddHorseDialogCubit>().stateChanged(
                  stateName: state.name,
                  stateId: state.id,
                );
          },
        ),

      // City selection (visible if a state is selected)
      if (state.selectedState != null)
        TypeAheadField<City>(
          suggestionsCallback: (pattern) async {
            final cities = await context.read<AddHorseDialogCubit>().getCities(
                  countryIso: state.countryIso!,
                  stateId: state.stateId!,
                );
            // Filter the city names based on the pattern
            return cities
                .where(
                  (city) =>
                      city.name.toLowerCase().startsWith(pattern.toLowerCase()),
                )
                .toList();
          },
          builder: (context, controller, focusNode) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              decoration: const InputDecoration(
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
            context.read<AddHorseDialogCubit>().cityChanged(
                  city: city.name,
                );
          },
        ),
    ],
  );

//   Column(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Visibility(
//         visible: !state.isLocationSearch,
//         child: InkWell(
//           onTap: () {
//             context.read<AddHorseDialogCubit>().toggleLocationSearch();
//           },
//           child: Row(
//             children: [
//               const Icon(Icons.location_on),
//               smallGap(),
//               Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Text(state.locationName),
//               ),
//             ],
//           ),
//         ),
//       ),
//       Visibility(
//         visible: state.isLocationSearch,
//         child: TextFormField(
//           enabled: true,
//           onChanged: (value) {
//             context.read<AddHorseDialogCubit>().horseZipChanged(value);
//           },
//           keyboardType: TextInputType.number,
//           textInputAction: TextInputAction.search,
//           decoration: InputDecoration(
//             labelText: "Horse's Location",
//             hintText: 'Enter Zip Code',
//             prefixIcon: IconButton(
//               onPressed: () {
//                 context.read<AddHorseDialogCubit>().toggleLocationSearch();
//               },
//               icon: const Icon(Icons.close),
//             ),
//             icon: const Icon(Icons.location_on),
//             suffixIcon: IconButton(
//               onPressed: () {
// // search for location
//                 context
//                     .read<AddHorseDialogCubit>()
//                     .searchForLocation()
//                     .then((value) {
//                   debugPrint('Search for location completed');
//                 });
//               },
//               icon: const Icon(Icons.search),
//             ),
//           ),
//         ),
//       ),
//       if (state.autoCompleteStatus == AutoCompleteStatus.loading)
//         const CircularProgressIndicator()
//       else if (state.autoCompleteStatus == AutoCompleteStatus.success)
//         SizedBox(
//           width: double.maxFinite,
//           height: 200,
//           child: ListView.builder(
//             shrinkWrap: true,
//             itemCount: state.prediction?.results.length ?? 0,
//             itemBuilder: (context, index) {
//               final postalCode =
//                   state.prediction?.results.keys.elementAt(index) ?? '';
//               final locations = state.prediction?.results[postalCode];
//               final controller = ExpansionTileController();
//               return ExpansionTile(
//                 controller: controller,
//                 initiallyExpanded: true,
//                 title: Text('Postal Code: $postalCode'),
//                 children: locations
//                         ?.map(
//                           (location) => ListTile(
//                             title: Text(location.city),
//                             subtitle: Text(
//                               '${location.city}, ${location.state}',
//                             ),
//                             onTap: () {
//                               context
//                                   .read<AddHorseDialogCubit>()
//                                   .toggleLocationSearch();
//                               controller.collapse();
//                               debugPrint('Location Selected ${location.city}');
//                               context
//                                   .read<AddHorseDialogCubit>()
//                                   .locationSelected(
//                                     locationName:
//                                         '${location.city}, ${location.state}',
//                                     selectedZipCode: postalCode,
//                                   );
//                             },
//                           ),
//                         )
//                         .toList() ??
//                     [const Text('No locations found')],
//               );
//             },
//           ),
//         )
//       else if (state.autoCompleteStatus == AutoCompleteStatus.error)
//         ColoredBox(
//           color: Colors.red,
//           child: Padding(
//             padding: const EdgeInsets.all(8),
//             child:
//                 Text(state.error, style: const TextStyle(color: Colors.white)),
//           ),
//         ),
//     ],
//   );
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
