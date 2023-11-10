// ignore_for_file: lines_longer_than_80_chars

import 'package:cached_network_image/cached_network_image.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/cubit/edit_rider_profile_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
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
        child: BlocBuilder<EditRiderProfileCubit, EditRiderProfileState>(
          builder: (context, state) {
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
                          context: context,
                          riderProfile: riderProfile,
                          size: isSmallScreen ? 85 : 150,
                        ),
                        gap(),
                        _riderName(
                          context: context,
                          state: state,
                          riderProfile: riderProfile,
                        ),
                        gap(),
                        _riderBio(
                          context: context,
                          state: state,
                          riderProfile: riderProfile,
                        ),
                        gap(),
                        _riderHomeUrl(
                          context: context,
                          state: state,
                          riderProfile: riderProfile,
                        ),
                        gap(),
                        _riderLocation(
                          context: context,
                          riderProfile: riderProfile,
                          state: state,
                        ),
                        gap(),
                      ],
                    ),
                  ),
                ),
                actions: [
                  // cancel button with same color as background, teext color is primary text color
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HorseAndRidersTheme()
                          .getTheme()
                          .colorScheme
                          .background,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Cancel',
                     style: TextStyle(
                        color: HorseAndRidersTheme()
                            .getTheme()
                            .colorScheme
                            .secondary,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          HorseAndRidersTheme().getTheme().primaryColor,
                    ),
                    onPressed: () {
                      context
                          .read<EditRiderProfileCubit>()
                          .updateRiderProfile();
                    },
                    child: state.status == SubmissionStatus.inProgress
                        ? const CircularProgressIndicator()
                        : const Text('Submit'),
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

Widget _riderName({
  required BuildContext context,
  required EditRiderProfileState state,
  required RiderProfile riderProfile,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderNameChanged(value: value),
    keyboardType: TextInputType.name,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.words,
    initialValue: riderProfile.name,
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
  required RiderProfile riderProfile,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderHomeUrlChanged(value: value),
    keyboardType: TextInputType.url,
    textInputAction: TextInputAction.next,
    initialValue: riderProfile.homeUrl ?? '',
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
  required RiderProfile riderProfile,
}) {
  return TextFormField(
    onChanged: (value) =>
        context.read<EditRiderProfileCubit>().riderBioChanged(value: value),
    keyboardType: TextInputType.multiline,
    maxLines: 12,
    minLines: 3,
    textInputAction: TextInputAction.next,
    textCapitalization: TextCapitalization.sentences,
    initialValue: riderProfile.bio ?? '',
    decoration: const InputDecoration(
      labelText: "Rider's Bio",
      hintText: "Enter Rider's Bio",
      icon: Icon(Icons.person),
    ),
  );
}

// create a widget that when the text form field is pressed
//a dialog opens that gets the users location using the
//geolocator package and them displays it in the text form field as a city name
Widget _riderLocation({
  required BuildContext context,
  required RiderProfile riderProfile,
  required EditRiderProfileState state,
}) {
  final searchController = TextEditingController();
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      TextFormField(
        controller: searchController,
        onChanged: (value) async {
          if (value.isNotEmpty) {
            await context
                .read<EditRiderProfileCubit>()
                .autoCompleteLocation(value: value);
          }
        },
        keyboardType: TextInputType.streetAddress,
        textInputAction: TextInputAction.next,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: "Rider's Location",
          hintText: "Enter Rider's Location",
          prefixIcon: Icon(Icons.my_location_rounded),
        ),
      ),
      if (state.autoCompleteStatus == AutoCompleteStatus.loading)
        const CircularProgressIndicator()
      else if (state.autoCompleteStatus == AutoCompleteStatus.success)
        SizedBox(
          width: double.maxFinite,
          height: 200,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: state.prediction.length,
            itemBuilder: (context, index) {
              return ListTile(
                onTap: () async {
                  await context
                      .read<EditRiderProfileCubit>()
                      .getGeoPoint(state.prediction[index]);

                  searchController.text =
                      state.prediction[index].description ?? '';
                  debugPrint('location name: ${state.locationName}');
                },
                title: Text(state.prediction[index].description ?? ''),
              );
            },
          ),
        )
      else if (state.autoCompleteStatus == AutoCompleteStatus.error)
        ColoredBox(
          color: Colors.red,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child:
                Text(state.error, style: const TextStyle(color: Colors.white)),
          ),
        ),
    ],
  );
}

Widget _profilePhoto({
  required BuildContext context,
  required RiderProfile riderProfile,
  required double size,
}) {
  final isDark = SharedPrefs().isDarkMode;
  return InkWell(
    onTap: () => context.read<EditRiderProfileCubit>().riderProfilePicClicked(),
    child: Column(
      children: [
        ///   Image
        CachedNetworkImage(
          imageUrl: '${riderProfile.picUrl}',
          placeholder: (context, url) =>
              const Image(image: AssetImage('assets/horse_icon_01.png')),
          errorWidget: (context, url, error) =>
              const Image(image: AssetImage('assets/horse_icon_01.png')),
          height: size,
          width: size,
        ),
        smallGap(),
        Text(
          riderProfile.picUrl != null
              ? 'Tap to Change your Photo'
              : ' Tap to Add a Photo',
          style: const TextStyle(fontSize: 12),
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
