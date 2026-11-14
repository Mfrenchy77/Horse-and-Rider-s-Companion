// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/horse_details.dart';
import 'package:horseandriderscompanion/CommonWidgets/location_picker.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Widgets/horse_height.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:intl/intl.dart';

/// Dialog for adding a new horse profile or editing an existing one
class AddHorseDialog extends StatefulWidget {
  const AddHorseDialog({
    super.key,
    required bool editProfile,
    required RiderProfile userProfile,
    required HorseProfile? horseProfile,
  }) : _editProfile = editProfile,
       _usersProfile = userProfile,
       _horseProfile = horseProfile;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // if horseProfile is null then we are creating a new horse profile
    // and editProfile should be false
    return BlocProvider(
      create: (context) => AddHorseDialogCubit(
        usersProfile: widget._usersProfile,
        horseProfile: widget._horseProfile,
        keysRepository:
            context.read<ApiKeyProvider?>() ??
            context.read<KeysRepository?>() ??
            KeysRepository(),
        cloudRepository:
            context.read<MediaStorageRepository?>() ??
            context.read<CloudRepository?>() ??
            CloudRepository(),
        horseProfileRepository:
            context.read<HorseProfileStore?>() ??
            context.read<HorseProfileRepository?>() ??
            HorseProfileRepository(),
        riderProfileRepository:
            context.read<RiderProfileStore?>() ??
            context.read<RiderProfileRepository?>() ??
            RiderProfileRepository(),
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

            final isWide = MediaQuery.sizeOf(context).width >= 700;
            return AppGlassDialog(
              maxWidth: 600,
              density: AppGlassDensity.frosted,
              insetPadding: isWide
                  ? const EdgeInsets.symmetric(horizontal: 32, vertical: 36)
                  : const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
              padding: EdgeInsets.all(
                isWide ? AppTokens.spaceXl : AppTokens.spaceLg,
              ),
              title: Text(
                widget._editProfile
                    ? 'Edit Horse: ${state.horseProfile?.name}'
                    : 'Create New Horse Profile',
              ),
              content: Column(
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
                    _horseLocation(context: context, state: state),
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
                  ],
                ),
              actions: [
                AppOutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  label: 'Cancel',
                ),
                _horseSubmitButton(
                  isEdit: widget._editProfile,
                  context: context,
                  state: state,
                ),
              ],
            );
          },
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
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  final hasPhoto = state.picUrl.trim().isNotEmpty;
  final radius = BorderRadius.circular(AppTokens.radiusLg);
  final surfaceColors = isDark
      ? [
          AppTokens.midnightCardTop.withValues(alpha: 0.94),
          AppTokens.midnightCardBottom.withValues(alpha: 0.92),
        ]
      : [
          theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.95),
          theme.colorScheme.surfaceContainer.withValues(alpha: 0.92),
        ];
  final borderColor = isDark
      ? AppTokens.glassBorderDark
      : theme.colorScheme.outlineVariant;
  final iconColor = isDark
      ? AppTokens.coralAccent
      : theme.colorScheme.primary;

  Widget placeholderBadge() => Container(
    height: size,
    width: size,
    decoration: BoxDecoration(
      color: isDark
          ? AppTokens.midnightInputFill
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
      border: Border.all(
        color: isDark
            ? AppTokens.midnightButtonBorder
            : theme.colorScheme.outlineVariant,
      ),
    ),
    child: Icon(
      HorseAndRiderIcons.horseIcon,
      size: size * 0.48,
      color: iconColor,
    ),
  );

  return Material(
    type: MaterialType.transparency,
    child: InkWell(
      borderRadius: radius,
      onTap: () => context.read<AddHorseDialogCubit>().horsePicButtonClicked(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceMd,
        ),
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: surfaceColors,
          ),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.picStatus == PictureGetterStatus.picking)
              SizedBox(
                height: size,
                width: size,
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (hasPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                child: CachedNetworkImage(
                  placeholderFadeInDuration: const Duration(milliseconds: 500),
                  fadeOutDuration: const Duration(milliseconds: 500),
                  imageUrl: state.picUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => placeholderBadge(),
                  errorWidget: (context, url, error) => placeholderBadge(),
                  height: size,
                  width: size,
                ),
              )
            else
              placeholderBadge(),
            const SizedBox(height: AppTokens.spaceSm),
            Text(
              hasPhoto
                  ? 'Tap to change horse photo'
                  : 'Tap to add a photo of your horse',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTokens.secondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
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
    isExpanded: true,
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
}) {
  final cubit = context.read<AddHorseDialogCubit>();
  return LocationPicker(
    countryLabel: state.horseProfile?.countryName ?? 'Select Country',
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
    onCountrySelected: (country) => cubit.countryChanged(
      countryIso: country.iso2,
      countryName: country.name,
    ),
    onStateSelected: (selectedState) => cubit.stateChanged(
      stateName: selectedState.name,
      stateId: selectedState.iso2!,
    ),
    onCitySelected: (city) => cubit.cityChanged(city: city.name),
    onZipCodeChanged: cubit.zipCodeChanged,
    onLocationSelected: (locationName, postalCode) {
      cubit
        ..toggleLocationSearch()
        ..locationSelected(
          locationName: locationName,
          selectedZipCode: postalCode,
        );
    },
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
