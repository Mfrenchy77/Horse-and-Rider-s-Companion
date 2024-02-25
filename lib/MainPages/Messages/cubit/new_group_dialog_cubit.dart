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
    required MessagesRepository groupsRespository,
    required RiderProfileRepository riderProfileRepository,
    required this.user,
  })  : _groupsRespository = groupsRespository,
        _riderProfileRepository = riderProfileRepository,
        super(const NewGroupDialogState());

  final MessagesRepository _groupsRespository;
  final RiderProfileRepository _riderProfileRepository;
  final RiderProfile user;

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
      emit(state.copyWith(searchResult: results));
    });
  }

  void removeFromSearchList({required RiderProfile riderProfile}) {
    final searchResult = state.searchResult.toList()..remove(riderProfile);
    emit(state.copyWith(searchResult: searchResult));
  }

  void removeGrouopList({required RiderProfile riderProfile}) {
    final groupList = state.groupMembers.toList()..remove(riderProfile);
    emit(state.copyWith(groupMembers: groupList));
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
    final profileResults = <RiderProfile?>[];
    _riderProfileRepository
        .getRiderProfile(email: state.email.value.toLowerCase())
        .listen((event) {
      final profile = event.data() as RiderProfile?;
      profileResults.add(profile);
      debugPrint('Result Name: ${profile?.name}');
      emit(state.copyWith(searchResult: profileResults));
    });
  }

  void addToGroupList({
    required RiderProfile riderProfile,
  }) {
//only add to the group list if it is not already in the list
    if (state.groupMembers.contains(riderProfile)) {
      emit(
        state.copyWith(
          error: '${riderProfile.name} is already in the group',
          isError: true,
        ),
      );

      return;
    }

    debugPrint('Add ${riderProfile.name} to Message Group');
    final groupMembers = state.groupMembers.toList()..add(riderProfile);
    debugPrint('Group Member Size: ${groupMembers.length}');
    emit(state.copyWith(groupMembers: groupMembers));
  }

  void createGroup() {
    emit(state.copyWith(status: FormzStatus.submissionInProgress));

    final id = StringBuffer()..write(convertEmailToPath(user.email));
    final memberNames = <String>[user.name];
    final memberIds = <String>[user.email.toLowerCase()];
    List<RiderProfile> groupMembers;
    if (state.groupMembers.isNotEmpty) {
      groupMembers = state.groupMembers as List<RiderProfile>;
      for (final riderProfile in groupMembers) {
        id.write(
          convertEmailToPath(riderProfile.email.toLowerCase()),
        );
        memberIds.add(riderProfile.email.toLowerCase());
        memberNames.add(riderProfile.name);
      }
    }
    debugPrint('Id: $id');
    final group = Group(
      id: id.toString(),
      type: state.groupType,
      parties: memberNames,
      partiesIds: memberIds,
      createdBy: user.name,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      lastEditBy: user.name,
      recentMessage: null,
    );

    try {
      _groupsRespository.createOrUpdateGroup(group: group);
      emit(state.copyWith(status: FormzStatus.submissionSuccess));
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          isError: true,
          error: 'Problem Creating New Message: $e',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: FormzStatus.submissionFailure,
          isError: true,
          error: 'Problem Creating New Message: $e',
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
