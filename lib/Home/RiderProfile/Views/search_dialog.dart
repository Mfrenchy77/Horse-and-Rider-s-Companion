// // ignore_for_file: cast_nullable_to_non_nullable, unnecessary_null_comparison

// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:formz/formz.dart';
// import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
// import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
// import 'package:horseandriderscompanion/Theme/theme.dart';
// import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
// import 'package:horseandriderscompanion/shared_prefs.dart';

// Widget searchDialog({required BuildContext context, required HomeState state}) {
//   return Scaffold(
//     backgroundColor: Colors.transparent,
//     body: AlertDialog(
//       insetPadding: const EdgeInsets.all(1),
//       scrollable: true,
//       title: Text(
//         _getSearchType(state.searchType),
//         textAlign: TextAlign.center,
//       ),
//       actions: [
//         Visibility(
//           visible: state.searchResult.isNotEmpty ||
//               state.horseSearchResult.isNotEmpty,
//           child: _clearResults(context: context),
//         ),
//         _close(context: context),
//       ],
//       content: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           _searchField(
//             context: context,
//             state: state,
//           ),
//           gap(),
//           const Center(
//             child: Text(
//               'Search Filters',
//               style: TextStyle(fontSize: 14),
//             ),
//           ),
//           const Divider(),
//           _searchButtons(
//             context: context,
//             state: state,
//           ),
//           gap(),
//           const Divider(),
//           if (state.formzStatus == FormzStatus.submissionInProgress)
//             const CircularProgressIndicator()
//           else if (state.formzStatus == FormzStatus.submissionFailure)
//             ColoredBox(
//               color: Colors.red,
//               child: Padding(
//                 padding: const EdgeInsets.all(8),
//                 child: Text(
//                   state.error,
//                   style: const TextStyle(color: Colors.white),
//                 ),
//               ),
//             )
//           else
//             state.formzStatus == FormzStatus.submissionSuccess
//                 ? _resultList(context: context, state: state)
//                 : Center(
//                     child: Text(
//                       _getSearchType(state.searchType),
//                     ),
//                   ),
//         ],
//       ),
//     ),
//   );
// }

// Widget _searchField({
//   required BuildContext context,
//   required HomeState state,
// }) {
//   bool hasText;
//   switch (state.searchType) {
//     case SearchType.email:
//       hasText = state.email.value.isNotEmpty;
//       break;
//     case SearchType.name:
//       hasText = state.name.value.isNotEmpty;
//       break;
//     case SearchType.horse:
//       hasText = state.name.value.isNotEmpty;
//       break;
//     case SearchType.horseNickName:
//       hasText = state.name.value.isNotEmpty;
//       break;
//     case SearchType.horseId:
//       hasText = state.name.value.isNotEmpty;

//       break;
//     case SearchType.horseLocation:
//       hasText = state.name.value.isNotEmpty;
//       break;
//     case SearchType.riderLocation:
//       hasText = state.name.value.isNotEmpty;
//       break;
//   }

//   return TextFormField(
//     textInputAction: TextInputAction.search,
//     onFieldSubmitted: !hasText
//         ? null
//         : (value) => value.isNotEmpty
//             ? _submitSearch(state: state, context: context)
//             : null,
//     validator: (value) => _validateSearchField(state: state, context: context),
//     initialValue: state.searchType == SearchType.email
//         ? state.email.value
//         : state.name.value,
//     textCapitalization: state.searchType == SearchType.email
//         ? TextCapitalization.none
//         : TextCapitalization.words,
//     keyboardType: state.searchType == SearchType.email
//         ? TextInputType.emailAddress
//         : TextInputType.name,
//     onChanged: (value) => state.searchType == SearchType.email
//         ? context.read<HomeCubit>().emailChanged(value)
//         : context.read<HomeCubit>().nameChanged(value),
//     decoration: InputDecoration(
//       border: const OutlineInputBorder(
//         borderRadius: BorderRadius.all(Radius.circular(10)),
//       ),
//       labelText: _getSearchType(state.searchType),
//       hintStyle: const TextStyle(
//         color: Colors.grey,
//         fontSize: 18,
//       ),
//       suffixIcon: Visibility(
//         visible: hasText,
//         child: IconButton(
//           icon: const Icon(Icons.search),
//           onPressed: () => _submitSearch(state: state, context: context),
//         ),
//       ),
//     ),
//   );
// }

// String? _validateSearchField({
//   required HomeState state,
//   required BuildContext context,
// }) {
//   switch (state.searchType) {
//     case SearchType.email:
//       return state.email.invalid ? 'Invalid Email' : null;
//     case SearchType.name:
//       return state.name.invalid ? 'Invalid Name' : null;
//     case SearchType.horse:
//       return state.name.invalid ? 'Invalid Horse Official Name' : null;
//     case SearchType.horseNickName:
//       return state.name.invalid ? 'Invalid Horse Nick Name' : null;
//     case SearchType.horseId:
//       return state.name.invalid ? 'Invalid Horse ID' : null;
//     case SearchType.horseLocation:
//       return state.name.invalid ? 'Invalid Horse Location' : null;
//     case SearchType.riderLocation:
//       return state.name.invalid ? 'Invalid Rider Location' : null;
//   }
// }
// /// Segmented button that allows user to select horse or rider
// Widget _profileSearchSelector({required HomeState state, required BuildContext context}){
//   return SegmentedButton(segments: <ButtonSegment>[ButtonSegment(value: ProfileSearchSelection.rider,icon: Icon(Icons.person),label: Text('Rider'),enabled: state.profileSearchSelection==ProfileSearchSelection.rider)], selected: context.read<HomeCubit>().profileSearchTypeChanged())
// }

// void _submitSearch({required HomeState state, required BuildContext context}) {
//   switch (state.searchType) {
//     case SearchType.email:
//       context.read<HomeCubit>().searchProfileByEmail();
//       break;
//     case SearchType.name:
//       context.read<HomeCubit>().searchProfilesByName();
//       break;
//     case SearchType.horse:
//       context.read<HomeCubit>().searchForHorseByName();
//       break;
//     case SearchType.horseNickName:
//       context.read<HomeCubit>().searchForHorseByNickName();
//       break;
//     case SearchType.horseId:
//       context.read<HomeCubit>().searchForHorseById();
//       break;
//     case SearchType.horseLocation:
//       context.read<HomeCubit>().searchForHorseByLocation();
//       break;
//     case SearchType.riderLocation:
//       context.read<HomeCubit>().searchRiderByLocation();
//       break;
//   }
// }

// Widget _searchButtons({
//   required BuildContext context,
//   required HomeState state,
// }) {
//   bool personVisible;

//   bool horseVisible;

//   final isDark = SharedPrefs().isDarkMode;

//   switch (state.searchType) {
//     case SearchType.email:
//       personVisible = true;
//       horseVisible = false;
//       break;
//     case SearchType.name:
//       personVisible = true;
//       horseVisible = true;
//       break;
//     case SearchType.horse:
//       personVisible = false;
//       horseVisible = true;
//       break;
//     case SearchType.horseNickName:
//       personVisible = false;
//       horseVisible = true;
//       break;
//     case SearchType.horseId:
//       personVisible = false;
//       horseVisible = true;
//       break;
//     case SearchType.horseLocation:
//       personVisible = false;
//       horseVisible = true;
//       break;
//     case SearchType.riderLocation:
//       personVisible = true;
//       horseVisible = false;
//       break;
//   }

//   return Row(
//     mainAxisSize: MainAxisSize.min,
//     children: [
//       Visibility(
//         visible: horseVisible,
//         child: Row(
//           children: [
//             Column(
//               children: [
//                 IconButton(
//                   onPressed: () => context
//                       .read<HomeCubit>()
//                       .changeSearchType(searchType: SearchType.horse),
//                   icon: const Icon(HorseAndRiderIcons.horseIcon),
//                 ),
//                 const Text(
//                   'Horse',
//                   style: TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//             smallGap(),
//             Divider(
//               color: isDark ? Colors.white : Colors.black,
//             ),
//             Visibility(
//               visible: state.searchType == SearchType.horse,
//               child: Row(
//                 children: [
//                   ChoiceChip(
//                     label: const Text('Official Name'),
//                     selected: state.searchState == SearchState.horse,
//                     onSelected: (value) =>
//                         context.read<HomeCubit>().toggleSearchState(
//                               searchState: SearchState.horse,
//                             ),
//                   ),
//                   smallGap(),
//                   ChoiceChip(
//                     label: const Text('Nick Name'),
//                     selected: state.searchState == SearchState.horseNickName,
//                     onSelected: (value) =>
//                         context.read<HomeCubit>().toggleSearchState(
//                               searchState: SearchState.horseNickName,
//                             ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       Visibility(
//         visible: personVisible,
//         child: Row(
//           children: [
//             Column(
//               children: [
//                 IconButton(
//                   onPressed: () => context
//                       .read<HomeCubit>()
//                       .changeSearchType(searchType: SearchType.rider),
//                   icon: const Icon(Icons.person),
//                   isSelected: state.searchType == SearchType.rider,
//                 ),
//                 const Text(
//                   'Rider',
//                   style: TextStyle(fontSize: 12),
//                 ),
//               ],
//             ),
//             smallGap(),
//             Divider(
//               color: isDark ? Colors.white : Colors.black,
//             ),
//             Visibility(
//               visible: state.searchType == SearchType.rider,
//               child: Row(
//                 children: [
//                   ChoiceChip(
//                     label: const Text('Name'),
//                     selected: state.searchState == SearchState.name,
//                     onSelected: (value) => context
//                         .read<HomeCubit>()
//                         .toggleSearchState(searchState: SearchState.name),
//                   ),
//                   smallGap(),
//                   ChoiceChip(
//                     label: const Text('Email'),
//                     selected: state.searchState == SearchState.email,
//                     onSelected: (value) => context
//                         .read<HomeCubit>()
//                         .toggleSearchState(searchState: SearchState.email),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }

// Widget _resultList({
//   required BuildContext context,
//   required HomeState state,
// }) {
//   final isDark = SharedPrefs().isDarkMode;
//   final halfTheScreen = MediaQuery.of(context).size.height / 2;
//   var height = 0.0;
//   if (state.searchState == SearchState.horse ||
//       state.searchState == SearchState.horseNickName) {
//     height = state.horseSearchResult.length * 60;
//   } else {
//     height = state.searchResult.length * 80;
//   }
//   if (height > halfTheScreen) {
//     height = halfTheScreen;
//   }
//   return SizedBox(
//     width: 300,
//     height: height,
//     child: ListView.builder(
//       itemCount: state.searchState == SearchState.horse ||
//               state.searchState == SearchState.horseNickName
//           ? state.horseSearchResult.length
//           : state.searchResult.length,
//       itemBuilder: (BuildContext context, int index) {
//         if (state.searchState == SearchState.horse ||
//             state.searchState == SearchState.horseNickName) {
//           final searchResult = state.horseSearchResult[index];
//           debugPrint('Search Result: : $searchResult');
//           return _resultItem(
//             isDark: isDark,
//             context: context,
//             horseProfile: searchResult,
//             profile: null,
//           );
//         } else {
//           final searchResult = state.searchResult[index];

//           debugPrint('Search Result: : $searchResult');
//           return _resultItem(
//             isDark: isDark,
//             context: context,
//             profile: searchResult,
//             horseProfile: null,
//           );
//         }
//       },
//     ),
//   );
// }

// Widget _resultItem({
//   required BuildContext context,
//   required RiderProfile? profile,
//   required HorseProfile? horseProfile,
//   required bool isDark,
// }) {
//   return profile != null
//       ? Padding(
//           padding: const EdgeInsets.only(top: 8),
//           child: Card(
//             elevation: 5,
//             margin: const EdgeInsets.only(bottom: 8, top: 8),
//             child: ListTile(
//               title: profile.name != null
//                   ? Text(
//                       profile.name,
//                       style: TextStyle(
//                         color: isDark
//                             ? Colors.white
//                             : HorseAndRidersTheme()
//                                 .getTheme()
//                                 .colorScheme
//                                 .primary,
//                       ),
//                     )
//                   : const Text('No Name'),
//               onTap: () {
//                 debugPrint(
//                   'Open  Profile Page For: ${profile.name}',
//                 );
//                 context.read<HomeCubit>().gotoProfilePage(
//                       context: context,
//                       toBeViewedEmail: profile.email,
//                     );
//               },
//               leading: profile.picUrl != null && profile.picUrl!.isNotEmpty
//                   ? CircleAvatar(
//                       radius: 24,
//                       backgroundImage: NetworkImage(profile.picUrl!),
//                     )
//                   : CircleAvatar(
//                       radius: 24,
//                       backgroundImage: AssetImage(
//                         isDark
//                             ? 'assets/horse_icon_circle_dark.png'
//                             : 'assets/horse_icon_circle.png',
//                       ),
//                     ),
//             ),
//           ),
//         )

//       /// Horse Profile
//       : horseProfile != null
//           ? ListTile(
//               title: Text(
//                 horseProfile.name,
//                 style: TextStyle(
//                   color: isDark
//                       ? Colors.white
//                       : HorseAndRidersTheme().getTheme().colorScheme.primary,
//                 ),
//               ),
//               onTap: () {
//                 debugPrint(
//                   'Open Horse Profile Page For: ${horseProfile.name}',
//                 );
//                 context.read<HomeCubit>().horseProfileSelected(
//                       id: horseProfile.id,
//                     );
//               },
//               leading:
//                   horseProfile.picUrl != null && horseProfile.picUrl!.isNotEmpty
//                       ? CircleAvatar(
//                           radius: 24,
//                           backgroundImage: NetworkImage(horseProfile.picUrl!),
//                         )
//                       : CircleAvatar(
//                           radius: 24,
//                           backgroundImage: AssetImage(
//                             isDark
//                                 ? 'assets/horse_icon_circle_dark.png'
//                                 : 'assets/horse_icon_circle.png',
//                           ),
//                         ),
//             )
//           : const Center(child: Text('No Results'));
// }

// Widget _clearResults({required BuildContext context}) {
//   return TextButton(
//     onPressed: () => context.read<HomeCubit>().clearSearchResults(),
//     child: const Text('Clear Search'),
//   );
// }

// Widget _close({required BuildContext context}) {
//   return TextButton(
//     onPressed: () => Navigator.of(context).pop(),
//     child: const Text('Close'),
//   );
// }

// /// Get the search type as a string
// String _getSearchType(SearchType searchType) {
//   switch (searchType) {
//     case SearchType.name:
//       return 'Search for Rider by name';
//     case SearchType.email:
//       return 'Search for Rider by email';
//     case SearchType.horse:
//       return 'Search for Horse by full name';
//     case SearchType.horseId:
//       return 'Search for Horse by ID';
//     case SearchType.horseNickName:
//       return 'Search for Horse by Nick Name';
//     case SearchType.horseLocation:
//       return 'Search for Horse by Location';
//     case SearchType.riderLocation:
//       return 'Search for Rider by Location';
//   }
// }
