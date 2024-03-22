// ignore_for_file: cast_nullable_to_non_nullable

import 'package:bloc/bloc.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'new_group_dialog_state.dart';

class NewGroupDialogCubit extends Cubit<NewGroupDialogState> {
  NewGroupDialogCubit({
    required MessagesRepository messagesRepository,
    required RiderProfileRepository riderProfileRepository,
    required RiderProfile usersProfile,
  })  : _messagesRepository = messagesRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const NewGroupDialogState()) {
    emit(state.copyWith(usersProfile: usersProfile));
  }

  final MessagesRepository _messagesRepository;
  final RiderProfileRepository _riderProfileRepository;

  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(state.copyWith(name: name, status: Formz.validate([name])));
  }

  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(state.copyWith(email: email, status: Formz.validate([email])));
  }

  void searchProfilesByName() {
    debugPrint('getProfile by Name for ${state.name.value}');
    _riderProfileRepository
        .getProfilesByName(name: state.name.value)
        .listen((event) {
      final results =
          event.docs.map((e) => (e.data()) as RiderProfile).toList();
      emit(state.copyWith(searchResult: _removeUsersProfile(results)));
    });
  }

  /// This method removes the user's profile from the list of search results
  List<RiderProfile> _removeUsersProfile(List<RiderProfile> profiles) {
    final adjustedList = profiles.toList();
    final index = adjustedList
        .indexWhere((profile) => profile.email == state.usersProfile?.email);
    if (index != -1) {
      adjustedList.removeAt(index);
    }
    return adjustedList;
  }

  void clearResults() {
    final clearedList = <RiderProfile>[];
    emit(
      state.copyWith(
        searchResult: clearedList,
      ),
    );
  }

  void toggleSearchState() {
    state.searchState == SearchState.email
        ? emit(state.copyWith(searchState: SearchState.name))
        : emit(state.copyWith(searchState: SearchState.email));
  }

  void getProfileByEmail() {
    debugPrint('getProfile by Email for ${state.email.value}');
    final profileResults = <RiderProfile>[];
    _riderProfileRepository
        .getRiderProfile(email: state.email.value.toLowerCase())
        .listen((event) {
      final profile = event.data() as RiderProfile;
      profileResults.add(profile);
      debugPrint('Result Name: ${profile.name}');
      emit(state.copyWith(searchResult: _removeUsersProfile(profileResults)));
    });
  }

//   void addToGroupList({
//     required RiderProfile riderProfile,
//   }) {
// //only add to the group list if it is not already in the list
//     if (state.groupMembers.contains(riderProfile)) {
//       emit(
//         state.copyWith(
//           error: '${riderProfile.name} is already in the group',
//           isError: true,
//         ),
//       );

//       return;
//     }

//     debugPrint('Add ${riderProfile.name} to Message Group');
//     final groupMembers = state.groupMembers.toList()..add(riderProfile);
//     debugPrint('Group Member Size: ${groupMembers.length}');
//     emit(state.copyWith(groupMembers: groupMembers));
//   }

  Future<void> createConversation(RiderProfile profile) async {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));
    final emails = <String>[
      state.usersProfile!.email.toLowerCase(),
      profile.email.toLowerCase(),
    ]..sort();

    final idbuff = StringBuffer()..write(emails.join('_'));
    final id = convertEmailToPath(idbuff.toString());
    final memberNames = <String>[state.usersProfile!.name, profile.name];
    final memberIds = <String>[
      state.usersProfile!.email.toLowerCase(),
      profile.email.toLowerCase(),
    ];

    final convesation = Conversation(
      id: id,
      recentMessage: null,
      parties: memberNames,
      partiesIds: memberIds,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      createdBy: state.usersProfile!.name,
      lastEditBy: state.usersProfile!.name,
    );

    try {
      await _messagesRepository
          .createOrUpdateConversation(
        conversation: convesation,
      )
          .then((value) {
        debugPrint('Conversation Created');
        emit(state.copyWith(status: FormzStatus.submissionSuccess, id: id));
      });
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          isError: true,
          status: FormzStatus.submissionFailure,
          error: 'Problem Creating New Conversation: $e',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          isError: true,
          error: 'Problem Creating New Conversation: $e',
        ),
      );
    }
  }

  void clearError() {
    emit(
      state.copyWith(
        error: '',
        isError: false,
      ),
    );
  }
}
