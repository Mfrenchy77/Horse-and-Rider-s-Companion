// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';

class MesssageContactsSearchDialog extends StatelessWidget {
  const MesssageContactsSearchDialog({
    super.key,
    required this.user,
  });
  final RiderProfile user;
  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => MessagesRepository(),
        ),
        RepositoryProvider(
          create: (context) => RiderProfileRepository(),
        ),
      ],
      child: BlocProvider(
        create: (context) => NewGroupDialogCubit(
          groupsRespository: context.read<MessagesRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
          user: user,
        ),
        child: BlocListener<NewGroupDialogCubit, NewGroupDialogState>(
          listener: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              Navigator.pop(context);
            }
            if (state.isError) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      state.error,
                      textAlign: TextAlign.center,
                    ),
                    backgroundColor: Colors.red,
                  ),
                ).closed.then(
                      (value) =>
                          context.read<NewGroupDialogCubit>().clearError(),
                    );
            }
          },
          child: BlocBuilder<NewGroupDialogCubit, NewGroupDialogState>(
            builder: (context, state) {
              return Scaffold(
                backgroundColor: Colors.transparent,
                appBar: AppBar(
                  title: const Text(
                    'New Message Recipient',
                  ),
                ),
                body: AlertDialog(
                  title: const Text(
                    'New Message Recipient',
                    textAlign: TextAlign.center,
                  ),
                  actions: [
                    _cancelButton(context: context),
                    _createMessageButton(state: state, context: context),
                  ],
                  insetPadding: const EdgeInsets.all(10),
                  scrollable: true,
                  content: state.status == FormzStatus.submissionInProgress
                      ? const CircularProgressIndicator()
                      : Column(
                          children: [
                            _searchField(context: context, state: state),
                            gap(),
                            Visibility(
                              visible: state.searchResult.isNotEmpty,
                              child:
                                  _resultList(context: context, state: state),
                            ),
                            const Divider(),
                            gap(),
                            Visibility(
                              visible: state.groupMembers.isNotEmpty,
                              child: _chosenContactList(
                                context: context,
                                state: state,
                              ),
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
}

Widget _searchField({
  required BuildContext context,
  required NewGroupDialogState state,
}) {
  return Column(
    children: [
      TextFormField(
        textInputAction: TextInputAction.search,
        onFieldSubmitted: (value) {
          FocusManager.instance.primaryFocus?.unfocus();
          if (state.searchState == SearchState.name) {
            context.read<NewGroupDialogCubit>().searchProfilesByName();
          } else {
            context.read<NewGroupDialogCubit>().getProfileByEmail();
          }
        },
        initialValue: state.searchState == SearchState.email
            ? state.email.value
            : state.name.value,
        textCapitalization: state.searchState == SearchState.name
            ? TextCapitalization.words
            : TextCapitalization.none,
        keyboardType: state.searchState == SearchState.name
            ? TextInputType.name
            : TextInputType.emailAddress,
        onChanged: (value) => state.searchState == SearchState.name
            ? context.read<NewGroupDialogCubit>().nameChanged(value)
            : context.read<NewGroupDialogCubit>().emailChanged(value),
        decoration: InputDecoration(
          labelText: state.searchState == SearchState.email
              ? 'Search by Email'
              : 'Search by Name',
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          hintText: state.searchState == SearchState.email
              ? 'Search by email'
              : 'Search by Name',
          hintStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 18,
          ),
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              state.searchState == SearchState.name
                  ? context.read<NewGroupDialogCubit>().searchProfilesByName()
                  : context.read<NewGroupDialogCubit>().getProfileByEmail();
            },
          ),
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ChoiceChip(
            selected: state.searchState == SearchState.name,
            onSelected: (value) {
              context.read<NewGroupDialogCubit>().toggleSearchState();
            },
            label: const Text('Name'),
          ),
          ChoiceChip(
            selected: state.searchState == SearchState.email,
            onSelected: (value) {
              context.read<NewGroupDialogCubit>().toggleSearchState();
            },
            label: const Text('Email'),
          ),
        ],
      ),
      // CheckboxListTile(
      //   value: false,
      //   title: Text(
      //     state.searchState == SearchState.email
      //         ? 'Click to Search by Name'
      //         : 'Click to Search by Email',
      //   ),
      //   onChanged: (value) =>
      //       context.read<NewGroupDialogCubit>().toggleSearchState(),
      // )
    ],
  );
}

Widget _chosenContactList({
  required BuildContext context,
  required NewGroupDialogState state,
}) {
  // ignore: omit_local_variable_types, prefer_final_locals
  double height = state.searchResult.length * 60;
  return state.groupMembers.isNotEmpty
      ? SizedBox(
          width: 300,
          height: height,
          child: ListView.builder(
            itemCount: state.groupMembers.length,
            itemBuilder: (BuildContext context, int index) {
              final searchResult = state.groupMembers[index];
              return _resultItem(
                isSearch: false,
                context: context,
                profile: searchResult,
              );
            },
          ),
        )
      : const Center(child: Text('No Chosen Contacts Yet'));
}

Widget _resultList({
  required BuildContext context,
  required NewGroupDialogState state,
}) {
  // ignore: prefer_final_locals, omit_local_variable_types
  double height = state.searchResult.length * 60;
  return state.searchResult.isNotEmpty
      ? Column(
          children: [
            SizedBox(
              width: 300,
              height: height,
              child: ListView.builder(
                itemCount: state.searchResult.length,
                itemBuilder: (BuildContext context, int index) {
                  final searchResult = state.searchResult[index];
                  return _resultItem(
                    isSearch: true,
                    context: context,
                    profile: searchResult,
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () =>
                  context.read<NewGroupDialogCubit>().clearResults(),
              child: const Text('Clear Results'),
            ),
          ],
        )
      : const Center(child: Text('No results'));
}

Widget _resultItem({
  required bool isSearch,
  required BuildContext context,
  required RiderProfile? profile,
}) {
  final isDark = SharedPrefs().isDarkMode;
  return profile != null
      ? ListTile(
          onTap: () => isSearch
              ? context
                  .read<NewGroupDialogCubit>()
                  .addToGroupList(riderProfile: profile)
              : context
                  .read<NewGroupDialogCubit>()
                  .removeGrouopList(riderProfile: profile),
          leading: profile.picUrl != null && profile.picUrl!.isNotEmpty
              ? CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage(profile.picUrl!),
                )
              : CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.transparent,
                  backgroundImage: AssetImage(
                    isDark
                        ? 'assets/horse_icon_circle_dark.png'
                        : 'assets/horse_icon_circle.png',
                  ),
                ),
          title: Text(
            profile.name ?? '',
            style: const TextStyle(
              fontSize: 18,
            ),
          ),
          trailing: isSearch
              ? IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => context
                      .read<NewGroupDialogCubit>()
                      .addToGroupList(riderProfile: profile),
                )
              : IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => context
                      .read<NewGroupDialogCubit>()
                      .removeGrouopList(riderProfile: profile),
                ),
        )
      : const Text('No Results');
}

Widget _createMessageButton({
  required NewGroupDialogState state,
  required BuildContext context,
}) {
  return TextButton(
    onPressed: state.groupMembers.isEmpty
        ? null
        : () => context.read<NewGroupDialogCubit>().createGroup(),
    child: const Text('Create a New Message'),
  );
}

Widget _cancelButton({
  required BuildContext context,
}) {
  return TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cancel'),
  );
}
