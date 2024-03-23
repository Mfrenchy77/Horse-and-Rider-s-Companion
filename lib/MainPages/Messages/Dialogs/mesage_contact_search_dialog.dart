// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_item.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/new_group_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/message_page.dart';

class MesssageContactsSearchDialog extends StatelessWidget {
  const MesssageContactsSearchDialog({
    super.key,
    required this.usersProfile,
  });
  final RiderProfile usersProfile;
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
          messagesRepository: context.read<MessagesRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
          usersProfile: usersProfile,
        ),
        child: BlocListener<NewGroupDialogCubit, NewGroupDialogState>(
          listener: (context, state) {
            if (state.status == FormzStatus.submissionSuccess) {
              context.read<AppCubit>().setConversation(state.id);
              context.goNamed(
                MessagePage.name,
                pathParameters: {MessagePage.pathParams: state.id},
              );
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
                    'Search for a New Message Recipient',
                  ),
                ),
                body: AlertDialog(
                  actions: [
                    _cancelButton(context: context),
                    //  _createMessageButton(state: state, context: context),
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
      smallGap(),
      SegmentedButton<SearchState>(
        segments: const [
          // Email
          ButtonSegment<SearchState>(
            tooltip: 'Search by Email',
            icon: Icon(Icons.email),
            value: SearchState.email,
            label: Text('Email'),
          ),
          // Name
          ButtonSegment<SearchState>(
            tooltip: 'Search by Name',
            icon: Icon(Icons.person),
            value: SearchState.name,
            label: Text('Name'),
          ),
        ],
        onSelectionChanged: (p0) =>
            context.read<NewGroupDialogCubit>().toggleSearchState(),
        selected: <SearchState>{state.searchState},
      ),
    ],
  );
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
  return profile != null
      ? profileItem(
          context: context,
          onTap: () =>
              context.read<NewGroupDialogCubit>().createConversation(profile),
          profilePicUrl: profile.picUrl ?? '',
          profileName: profile.name,
        )
      : const Text('No Results');
}

// Widget _createMessageButton({
//   required NewGroupDialogState state,
//   required BuildContext context,
// }) {
//   return TextButton(
//     onPressed: state.groupMembers.isEmpty
//         ? null
//         : () => context.read<NewGroupDialogCubit>().createConversation(),
//     child: const Text('Create a New Message'),
//   );
// }

Widget _cancelButton({
  required BuildContext context,
}) {
  return TextButton(
    onPressed: () => Navigator.pop(context),
    child: const Text('Cancel'),
  );
}
