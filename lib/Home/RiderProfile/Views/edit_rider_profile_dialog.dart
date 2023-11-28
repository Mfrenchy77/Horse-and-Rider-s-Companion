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
  required RiderProfile riderProfile,
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
  required RiderProfile riderProfile,
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
    initialValue: state.bio,
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
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Visibility(
        visible: !state.isLocationSearch,
        child: InkWell(
          onTap: () {
            context.read<EditRiderProfileCubit>().toggleLocationSearch();
          },
          child: Row(
            children: [
              const Icon(Icons.location_on),
              smallGap(),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(state.locationName),
              ),
            ],
          ),
        ),
      ),
      Visibility(
        visible: state.isLocationSearch,
        child: TextFormField(
          enabled: true,
          onChanged: (value) {
            context
                .read<EditRiderProfileCubit>()
                .riderLocationChanged(value: value);
          },
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            labelText: "Rider's Location",
            hintText: 'Enter Zip Code',
            prefixIcon: IconButton(
              onPressed: () {
                context.read<EditRiderProfileCubit>().toggleLocationSearch();
              },
              icon: const Icon(Icons.close),
            ),
            icon: const Icon(Icons.location_on),
            suffixIcon: IconButton(
              onPressed: () {
// search for location
                context
                    .read<EditRiderProfileCubit>()
                    .searchForLocation()
                    .then((value) {
                  debugPrint('Search for location completed');
                });
              },
              icon: const Icon(Icons.search),
            ),
          ),
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
                                  .read<EditRiderProfileCubit>()
                                  .toggleLocationSearch();
                              controller.collapse();
                              debugPrint('Location Selected ${location.city}');
                              context
                                  .read<EditRiderProfileCubit>()
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
          riderProfile.picUrl != null
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
