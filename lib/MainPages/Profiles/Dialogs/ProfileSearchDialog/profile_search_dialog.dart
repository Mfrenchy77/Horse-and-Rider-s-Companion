import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_item.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/ProfileSearchDialog/Cubit/profile_search_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

/// A Dialog that allows the user to search for a Rider or Horse Profile, by
/// name email or horse name or horse id or location for either a Rider or Horse
class ProfileSearchDialog extends StatelessWidget {
  const ProfileSearchDialog({super.key, required this.homeContext});
  final BuildContext homeContext;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => RiderProfileRepository(),
        ),
        RepositoryProvider(
          create: (context) => HorseProfileRepository(),
        ),
        RepositoryProvider(create: (context) => KeysRepository()),
      ],
      child: BlocProvider(
        create: (context) => ProfileSearchCubit(
          horseProfileRepository: context.read<HorseProfileRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
          keysRepository: context.read<KeysRepository>(),
        ),
        child: BlocListener<ProfileSearchCubit, ProfileSearchState>(
          listener: (context, state) {
            /// Show a snackbar if there is an error
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(state.error),
                  ),
                ).closed.then((_) {
                  context.read<ProfileSearchCubit>().clearError();
                });
            }
          },
          child: BlocBuilder<ProfileSearchCubit, ProfileSearchState>(
            builder: (context, state) {
              final cubit = context.read<ProfileSearchCubit>();
              return AlertDialog(
                title: Text(_getSearchType(state.searchType)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        validator: (value) {
                          //Validate based on the search type
                          if (value == null) {
                            return null;
                          } else {
                            switch (state.searchType) {
                              case SearchType.name:
                                return state.searchValue.validator(value);

                              case SearchType.email:
                                return state.email.validator(value);

                              case SearchType.horse:
                                return state.searchValue.validator(value);
                              case SearchType.horseId:
                                return state.searchValue.value.isEmpty
                                    ? 'Please enter a horse id'
                                    : null;
                              case SearchType.horseNickName:
                                return state.searchValue.validator(value);
                              case SearchType.horseLocation:
                                return state.zipCode.validator(value);

                              case SearchType.riderLocation:
                                return state.zipCode.validator(value);
                            }
                          }
                        },
                        onFieldSubmitted: !_isSearchValid(state)
                            ? null
                            : (value) {
                                initiateSearch(cubit: cubit, state: state);
                              },
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(40)),
                          ),
                          labelText: 'Search',
                          hintText: _getHintText(state.searchType),
                          suffixIcon: IconButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onChanged: (value) {
                          switch (state.searchType) {
                            case SearchType.name:
                              cubit.nameChanged(value);
                              break;
                            case SearchType.email:
                              cubit.emailChanged(value);
                              break;
                            case SearchType.horse:
                              cubit.nameChanged(value);
                              break;
                            case SearchType.horseId:
                              cubit.nameChanged(value);
                              break;
                            case SearchType.horseNickName:
                              cubit.nameChanged(value);
                              break;
                            case SearchType.horseLocation:
                              cubit.nameChanged(value);
                              break;
                            case SearchType.riderLocation:
                              cubit.nameChanged(value);
                              break;
                          }
                        },
                      ),
                      smallGap(),
                      // Search Button
                      _searchButton(cubit: cubit, state: state),
                      gap(),
                      const Divider(
                        height: 2,
                        indent: 20,
                        endIndent: 20,
                      ),
                      gap(),
                      _horseOrRiderSelctor(state: state, cubit: cubit),
                      gap(),
                      _searchSelectorChips(
                        state: state,
                        cubit: cubit,
                      ),
                      gap(),
                      // // Drop down for location search area,
                      // // visible only when search type is location
                      // _locationDropDown(
                      //   cubit: cubit,
                      //   state: state,
                      //   context: context,
                      // ),
                      gap(),
                      const Divider(
                        height: 2,
                        indent: 20,
                        endIndent: 20,
                      ),
                      gap(),
                      _resultList(
                        cubit: cubit,
                        state: state,
                        context: context,
                        homeContext: homeContext,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Widget that is the search button for the search dialog,
  /// but when status is in progress, it shows a circular progress indicator
  Widget _searchButton({
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    return state.status.isSubmissionInProgress
        ? const CircularProgressIndicator()
        : ElevatedButton.icon(
            icon: const Icon(Icons.search),
            onPressed: !_isSearchValid(state)
                ? null
                : () => initiateSearch(cubit: cubit, state: state),
            label: const Text('Search'),
          );
  }

  /// Initiate Search depending on the search type
  void initiateSearch({
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    switch (state.searchType) {
      case SearchType.name:
        cubit.searchProfilesByName();
        break;
      case SearchType.email:
        cubit.searchProfileByEmail();
        break;
      case SearchType.horse:
        cubit.searchForHorseByName();
        break;
      case SearchType.horseId:
        cubit.searchForHorseById();
        break;
      case SearchType.horseNickName:
        cubit.searchForHorseByNickName();
        break;
      case SearchType.horseLocation:
        cubit.searchForHorseByLocation();
        break;
      case SearchType.riderLocation:
        cubit.searchRiderByZipCode();
        break;
    }
  }

  /// Drop down for location search area,
  ///  visible only when search type is location
  Widget _locationDropDown({
    required BuildContext context,
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    final items = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]
        .map(
          (location) => DropdownMenuItem<int>(
            value: location,
            child: Text(location.toString()),
          ),
        )
        .toList();
    return state.searchType == SearchType.horseLocation ||
            state.searchType == SearchType.riderLocation
        ? DropdownButton<int>(
            hint: const Text('Select Search Range'),
            value: state.locationRange.value,
            items: items,
            onChanged: (value) {
              cubit.locationRangeChanged(value);
            },
          )
        : const SizedBox();
  }

  /// Hint Text for the search field depending on the search type
  String _getHintText(SearchType searchType) {
    switch (searchType) {
      case SearchType.name:
        return 'Search for Rider by Name(Case Sensitive)';
      case SearchType.email:
        return 'Search for Rider by Email';
      case SearchType.horse:
        return 'Search for Horse by Full name(Case Sensitive)';
      case SearchType.horseId:
        return 'Search for Horse by ID';
      case SearchType.horseNickName:
        return 'Search for Horse by Nick Name(Case Sensitive)';
      case SearchType.horseLocation:
        return 'Enter the zip code you want to search for horses in';
      case SearchType.riderLocation:
        return 'Enter the zip code you want to search for riders in';
    }
  }

  /// Get the search type as a string
  String _getSearchType(SearchType searchType) {
    switch (searchType) {
      case SearchType.name:
        return 'Search for Rider by Name';
      case SearchType.email:
        return 'Search for Rider by Email';
      case SearchType.horse:
        return 'Search for Horse by Full Name';
      case SearchType.horseId:
        return 'Search for Horse by ID';
      case SearchType.horseNickName:
        return 'Search for Horse by Nick Name';
      case SearchType.horseLocation:
        return 'Search for Horse by Location';
      case SearchType.riderLocation:
        return 'Search for Rider by Location';
    }
  }

  /// Segemented button that toggles whether the search is for a
  /// rider or horse
  Widget _horseOrRiderSelctor({
    required ProfileSearchState state,
    required ProfileSearchCubit cubit,
  }) {
    return SegmentedButton<bool>(
      segments: const [
        ButtonSegment<bool>(
          tooltip: 'Search for Rider',
          value: true,
          icon: Icon(Icons.person),
          label: Text('Rider'),
        ),
        ButtonSegment<bool>(
          tooltip: 'Search for Horse',
          value: false,
          icon: Icon(HorseAndRiderIcons.horseIcon),
          label: Text('Horse'),
        ),
      ],
      selected: <bool>{state.isSearchRider},
      onSelectionChanged: (p0) => cubit.toggleForRider(),
    );
  }

  /// Widget that shows the search selector chips
  Widget _searchSelectorChips({
    required ProfileSearchState state,
    required ProfileSearchCubit cubit,
  }) {
    return state.isSearchRider
        ? Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              //name
              ChoiceChip(
                label: const Text('Name'),
                selected: state.searchType == SearchType.name,
                onSelected: (value) {
                  cubit.searchTypeChanged(SearchType.name);
                },
              ),
              //email
              ChoiceChip(
                label: const Text('Email'),
                selected: state.searchType == SearchType.email,
                onSelected: (value) {
                  cubit.searchTypeChanged(SearchType.email);
                },
              ),
              //location
              // ChoiceChip(
              //   label: const Text('Location'),
              //   selected: state.searchType == SearchType.riderLocation,
              //   onSelected: (value) {
              //     cubit.searchTypeChanged(SearchType.riderLocation);
              //   },
              // ),
            ],
          )
        : Wrap(
            spacing: 2,
            runSpacing: 2,
            alignment: WrapAlignment.center,
            children: [
              // horse name
              ChoiceChip(
                label: const Text('Name'),
                selected: state.searchType == SearchType.horse,
                onSelected: (value) {
                  cubit.searchTypeChanged(SearchType.horse);
                },
              ),
              // horse nick name
              ChoiceChip(
                label: const Text('Nick Name'),
                selected: state.searchType == SearchType.horseNickName,
                onSelected: (value) {
                  cubit.searchTypeChanged(SearchType.horseNickName);
                },
              ),
              // horse id
              ChoiceChip(
                label: const Text('ID'),
                selected: state.searchType == SearchType.horseId,
                onSelected: (value) {
                  cubit.searchTypeChanged(SearchType.horseId);
                },
              ),
              // horse location
              // ChoiceChip(
              //   label: const Text('Location'),
              //   selected: state.searchType == SearchType.horseLocation,
              //   onSelected: (value) {
              //     cubit.searchTypeChanged(SearchType.horseLocation);
              //   },
              // ),
            ],
          );
  }

  Widget _resultList({
    required BuildContext context,
    required BuildContext homeContext,
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    return state.searchType == SearchType.name ||
            state.searchType == SearchType.email ||
            state.searchType == SearchType.riderLocation
        ? _riderList(
            homeContext: homeContext,
            context: context,
            cubit: cubit,
            state: state,
          )
        : _horseList(
            homeContext: homeContext,
            context: context,
            cubit: cubit,
            state: state,
          );
  }

  Widget _riderList({
    required BuildContext homeContext,
    required BuildContext context,
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    return state.riderProfiles.isNotEmpty
        ? SingleChildScrollView(
            child: Wrap(
              children: cubit
                  .removeUserProfile(
                    context.read<AppCubit>().state.usersProfile,
                  )
                  .map(
                    (profile) => profileItem(
                      profileName: profile.name,
                      profilePicUrl: profile.picUrl ?? '',
                      context: context,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.goNamed(
                          ViewingProfilePage.name,
                          pathParameters: {'id': profile.email},
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          )
        : const Center(child: Text('No Results'));
  }

  Widget _horseList({
    required BuildContext homeContext,
    required BuildContext context,
    required ProfileSearchCubit cubit,
    required ProfileSearchState state,
  }) {
    return state.horseProfiles.isNotEmpty
        ? SingleChildScrollView(
            child: Wrap(
              children: state.horseProfiles
                  .map(
                    (horseProfile) => profileItem(
                      profileName: horseProfile.name,
                      profilePicUrl: horseProfile.picUrl ?? '',
                      context: context,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.goNamed(
                          HorseProfilePage.name,
                          pathParameters: {
                            HorseProfilePage.pathParams: horseProfile.id,
                          },
                        );
                      },
                      //   homeContext
                      //       .read<HomeCubit>()
                      //       .horseProfileSelected(id: horseProfile.id);
                      // },
                    ),
                  )
                  .toList(),
            ),
          )
        : const Center(child: Text('No Results'));
  }
}

/// detemine if the search field is valid and can be submitted
bool _isSearchValid(ProfileSearchState state) {
  switch (state.searchType) {
    case SearchType.name:
      return state.searchValue.valid;
    case SearchType.email:
      return state.email.valid;
    case SearchType.horse:
      return state.searchValue.valid;
    case SearchType.horseId:
      return state.searchValue.valid;
    case SearchType.horseNickName:
      return state.searchValue.valid;
    case SearchType.horseLocation:
      return state.zipCode.valid;
    case SearchType.riderLocation:
      return state.zipCode.valid;
  }
}
