// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class SearchDialog extends StatelessWidget {
  const SearchDialog({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final user = context.select((AppBloc bloc) => bloc.state.user);
    return BlocProvider(
      create: (context) => HomeCubit(
        viewingProfile: null,
        user: user,
        horseProfileRepository: context.read<HorseProfileRepository>(),
        riderProfileRepository: context.read<RiderProfileRepository>(),
        skillTreeRepository: context.read<SkillTreeRepository>(),
        messagesRepository: context.read<MessagesRepository>(),
        resourcesRepository: context.read<ResourcesRepository>(),
      ),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: AlertDialog(
              insetPadding: const EdgeInsets.all(1),
              scrollable: true,
              title: Text(
                state.searchState == SearchState.email
                    ? 'Search for Contact By Email'
                    : state.searchState == SearchState.name
                        ? 'Search for Contact By Name'
                        : state.searchState == SearchState.horse
                            ? 'Search for Horse By Official Name'
                            : 'Search for Horse By NickName',
                textAlign: TextAlign.center,
              ),
              actions: [
                Visibility(
                  visible: state.searchResult.isNotEmpty ||
                      state.horseSearchResult.isNotEmpty,
                  child: _clearResults(context: context),
                ),
                _close(context: context),
              ],
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _searchField(
                    context: context,
                    state: state,
                  ),
                  gap(),
                  const Center(
                    child: Text(
                      'Search Filters',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                  const Divider(),
                  _searchButtons(
                    context: context,
                    state: state,
                  ),
                  gap(),
                  const Divider(),
                  if (state.formzStatus == FormzStatus.submissionInProgress)
                    const CircularProgressIndicator()
                  else if (state.formzStatus == FormzStatus.submissionFailure)
                    ColoredBox(
                      color: Colors.red,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          state.error,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    )
                  else
                    state.formzStatus == FormzStatus.submissionSuccess
                        ? _resultList(context: context, state: state)
                        : Center(
                            child: Text(
                              state.searchState == SearchState.horse
                                  ? 'Horse Results'
                                  : state.searchState ==
                                          SearchState.horseNickName
                                      ? 'Horse Results'
                                      : 'Search Results',
                            ),
                          ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget _searchField({
  required BuildContext context,
  required HomeState state,
}) {
  bool hasText;
  switch (state.searchState) {
    case SearchState.email:
      hasText = state.email.value.isNotEmpty;
      break;
    case SearchState.name:
      hasText = state.name.value.isNotEmpty;
      break;
    case SearchState.horse:
      hasText = state.name.value.isNotEmpty;
      break;
    case SearchState.horseNickName:
      hasText = state.name.value.isNotEmpty;
      break;
  }

  return TextFormField(
    textInputAction: TextInputAction.search,
    onFieldSubmitted: !hasText
        ? null
        : (value) => value.isNotEmpty
            ? state.searchState == SearchState.email
                ? context.read<HomeCubit>().getProfileByEmail()
                : state.searchState == SearchState.name
                    ? context.read<HomeCubit>().searchProfilesByName()
                    : state.searchState == SearchState.horse
                        ? context.read<HomeCubit>().searchForHorseByName()
                        : context.read<HomeCubit>().searchForHorseByNickName()
            : null,
    validator: (value) => state.searchState == SearchState.email
        ? state.email.invalid
            ? 'Invalid Email'
            : null
        : state.searchState == SearchState.name
            ? state.name.invalid
                ? 'Invalid Name'
                : null
            : state.searchState == SearchState.horseNickName
                ? state.name.invalid
                    ? 'Invalid Horse Nick Name'
                    : null
                : state.name.invalid
                    ? 'Invalid Horse Official Name'
                    : null,
    initialValue: state.searchState == SearchState.email
        ? state.email.value
        : state.name.value,
    textCapitalization: state.searchState == SearchState.email
        ? TextCapitalization.none
        : TextCapitalization.words,
    keyboardType: state.searchState == SearchState.email
        ? TextInputType.emailAddress
        : TextInputType.name,
    onChanged: (value) => state.searchState == SearchState.email
        ? context.read<HomeCubit>().emailChanged(value)
        : context.read<HomeCubit>().nameChanged(value),
    decoration: InputDecoration(
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      labelText: state.searchState == SearchState.email
          ? 'Search by email'
          : state.searchState == SearchState.name
              ? 'Search by Name'
              : state.searchState == SearchState.horseNickName
                  ? 'Search by Horse Nick Name'
                  : 'Search by Horse Official Name',
      hintText: state.searchState == SearchState.email
          ? 'Search by email'
          : state.searchState == SearchState.name
              ? 'Search by Name'
              : state.searchState == SearchState.horseNickName
                  ? 'Search by Horse Nick Name'
                  : 'Search by Horse Official Name',
      hintStyle: const TextStyle(
        color: Colors.grey,
        fontSize: 18,
      ),
      suffixIcon: Visibility(
        visible: hasText,
        child: IconButton(
          icon: const Icon(Icons.search),
          onPressed: () => state.searchState == SearchState.email
              ? context.read<HomeCubit>().getProfileByEmail()
              : state.searchState == SearchState.name
                  ? context.read<HomeCubit>().searchProfilesByName()
                  : state.searchState == SearchState.horse
                      ? context.read<HomeCubit>().searchForHorseByName()
                      : context.read<HomeCubit>().searchForHorseByNickName(),
        ),
      ),
    ),
  );
}

Widget _searchButtons({
  required BuildContext context,
  required HomeState state,
}) {
  bool personVisible;

  bool horseVisible;

  final isDark = SharedPrefs().isDarkMode;

  switch (state.searchType) {
    case SearchType.rider:
      personVisible = true;
      horseVisible = false;
      break;
    case SearchType.ititial:
      personVisible = true;
      horseVisible = true;
      break;
    case SearchType.horse:
      personVisible = false;
      horseVisible = true;
      break;
  }

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Visibility(
        visible: horseVisible,
        child: Row(
          children: [
            Column(
              children: [
                IconButton(
                  onPressed: () => context
                      .read<HomeCubit>()
                      .changeSearchType(searchType: SearchType.horse),
                  icon: const Icon(HorseAndRiderIcons.horseIcon),
                ),
                const Text(
                  'Horse',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            smallGap(),
            Divider(
              color: isDark ? Colors.white : Colors.black,
            ),
            Visibility(
              visible: state.searchType == SearchType.horse,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Official Name'),
                    selected: state.searchState == SearchState.horse,
                    onSelected: (value) =>
                        context.read<HomeCubit>().toggleSearchState(
                              searchState: SearchState.horse,
                            ),
                  ),
                  smallGap(),
                  ChoiceChip(
                    label: const Text('Nick Name'),
                    selected: state.searchState == SearchState.horseNickName,
                    onSelected: (value) =>
                        context.read<HomeCubit>().toggleSearchState(
                              searchState: SearchState.horseNickName,
                            ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      Visibility(
        visible: personVisible,
        child: Row(
          children: [
            Column(
              children: [
                IconButton(
                  onPressed: () => context
                      .read<HomeCubit>()
                      .changeSearchType(searchType: SearchType.rider),
                  icon: const Icon(Icons.person),
                  isSelected: state.searchType == SearchType.rider,
                ),
                const Text(
                  'Rider',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            smallGap(),
            Divider(
              color: isDark ? Colors.white : Colors.black,
            ),
            Visibility(
              visible: state.searchType == SearchType.rider,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Name'),
                    selected: state.searchState == SearchState.name,
                    onSelected: (value) => context
                        .read<HomeCubit>()
                        .toggleSearchState(searchState: SearchState.name),
                  ),
                  smallGap(),
                  ChoiceChip(
                    label: const Text('Email'),
                    selected: state.searchState == SearchState.email,
                    onSelected: (value) => context
                        .read<HomeCubit>()
                        .toggleSearchState(searchState: SearchState.email),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

Widget _resultList({
  required BuildContext context,
  required HomeState state,
}) {
  final isDark = SharedPrefs().isDarkMode;
  final halfTheScreen = MediaQuery.of(context).size.height / 2;
  var height = 0.0;
  if (state.searchState == SearchState.horse ||
      state.searchState == SearchState.horseNickName) {
    height = state.horseSearchResult.length * 60;
  } else {
    height = state.searchResult.length * 80;
  }
  if (height > halfTheScreen) {
    height = halfTheScreen;
  }
  return SizedBox(
    width: 300,
    height: height,
    child: ListView.builder(
      itemCount: state.searchState == SearchState.horse ||
              state.searchState == SearchState.horseNickName
          ? state.horseSearchResult.length
          : state.searchResult.length,
      itemBuilder: (BuildContext context, int index) {
        if (state.searchState == SearchState.horse ||
            state.searchState == SearchState.horseNickName) {
          final searchResult = state.horseSearchResult[index];
          debugPrint('Search Result: : $searchResult');
          return _resultItem(
            isDark: isDark,
            context: context,
            horseProfile: searchResult,
            profile: null,
          );
        } else {
          final searchResult = state.searchResult[index];

          debugPrint('Search Result: : $searchResult');
          return _resultItem(
            isDark: isDark,
            context: context,
            profile: searchResult,
            horseProfile: null,
          );
        }
      },
    ),
  );
}

Widget _resultItem({
  required BuildContext context,
  required RiderProfile? profile,
  required HorseProfile? horseProfile,
  required bool isDark,
}) {
  return profile != null
      ? Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Card(
            elevation: 5,
            margin: const EdgeInsets.only(bottom: 8, top: 8),
            child: ListTile(
              title: profile.name != null
                  ? Text(
                      profile.name!,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white
                            : HorseAndRidersTheme()
                                .getTheme()
                                .colorScheme
                                .primary,
                      ),
                    )
                  : const Text('No Name'),
              onTap: () {
                debugPrint(
                  'Open  Profile Page For: ${profile.name}',
                );
                context.read<HomeCubit>().gotoProfilePage(
                      context: context,
                      toBeViewedEmail: profile.email as String,
                    );
              },
              leading: profile.picUrl != null && profile.picUrl!.isNotEmpty
                  ? CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(profile.picUrl!),
                    )
                  : CircleAvatar(
                      radius: 24,
                      backgroundImage: AssetImage(
                        isDark
                            ? 'assets/horse_icon_circle_dark.png'
                            : 'assets/horse_icon_circle.png',
                      ),
                    ),
            ),
          ),
        )

      /// Horse Profile
      : horseProfile != null
          ? ListTile(
              title: Text(
                horseProfile.name,
                style: TextStyle(
                  color: isDark
                      ? Colors.white
                      : HorseAndRidersTheme().getTheme().colorScheme.primary,
                ),
              ),
              onTap: () {
                debugPrint(
                  'Open Horse Profile Page For: ${horseProfile.name}',
                );
                context.read<HomeCubit>().horseSelected(
                      context: context,
                      horseProfileId: horseProfile.id,
                    );
              },
              leading:
                  horseProfile.picUrl != null && horseProfile.picUrl!.isNotEmpty
                      ? CircleAvatar(
                          radius: 24,
                          backgroundImage: NetworkImage(horseProfile.picUrl!),
                        )
                      : CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                            isDark
                                ? 'assets/horse_icon_circle_dark.png'
                                : 'assets/horse_icon_circle.png',
                          ),
                        ),
            )
          : const Center(child: Text('No Results'));
}

Widget _clearResults({required BuildContext context}) {
  return TextButton(
    onPressed: () => context.read<HomeCubit>().clearSearchResults(),
    child: const Text('Clear Search'),
  );
}

Widget _close({required BuildContext context}) {
  return TextButton(
    onPressed: () => Navigator.of(context).pop(),
    child: const Text('Close'),
  );
}
