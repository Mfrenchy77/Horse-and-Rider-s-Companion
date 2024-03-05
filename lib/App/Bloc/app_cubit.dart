import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_page.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({
    required MessagesRepository messagesRepository,
    required SkillTreeRepository skillTreeRepository,
    required ResourcesRepository resourcesRepository,
    required RiderProfileRepository riderProfileRepository,
    required HorseProfileRepository horseProfileRepository,
    required AuthenticationRepository authenticationRepository,
  })  : _messagesRepository = messagesRepository,
        _skillTreeRepository = skillTreeRepository,
        _resourcesRepository = resourcesRepository,
        _riderProfileRepository = riderProfileRepository,
        _horseProfileRepository = horseProfileRepository,
        _authenticationRepository = authenticationRepository,
        super(
          authenticationRepository.currentUser.isNotEmpty
              ? AppState.authenticated(authenticationRepository.currentUser)
              : const AppState.unauthenticated(),
        ) {
    _beginListeningForUserChanges();
  }

  /// Repositories
  final MessagesRepository _messagesRepository;
  final SkillTreeRepository _skillTreeRepository;
  final ResourcesRepository _resourcesRepository;
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  final AuthenticationRepository _authenticationRepository;

  ///Streams
  late final StreamSubscription<User?> _userSubscription;
  StreamSubscription<DocumentSnapshot<Object?>>? _usersProfileSubscription;
  StreamSubscription<DocumentSnapshot<Object?>>? _horseProfileSubscription;
  late final StreamSubscription<RiderProfile?> _viewingProfileSubscription;
  late final StreamSubscription<List<Skill>> _skillsSubscription;
  late final StreamSubscription<List<Resource>> _resourcesSubscription;

/* **************************************************************************

******************************* User's Profile *********************************

***************************************************************************** */
  void _beginListeningForUserChanges() {
    _userSubscription = _authenticationRepository.user.listen((user) {
      debugPrint('Listening for user changes: '
          '\nUserEmail: ${user?.email} '
          '\nUserGuest: ${user?.isGuest} '
          '\nUserId: ${user?.id}');
      if (user != null && user.id.isNotEmpty) {
        debugPrint('User is authenticated');
        _getRiderProfile(user: user);
      } else {
        debugPrint('User is unauthenticated or email not verified');
        emit(state.copyWith(pageStatus: AppPageStatus.auth));
      }
    });
  }

  void _getRiderProfile({required User user}) {
    if (user.isGuest) {
      debugPrint('Guest User');
      emit(
        state.copyWith(
          isGuest: true,
          pageStatus: AppPageStatus.profile,
          user: user,
        ),
      );
    } else if (!user.emailVerified) {
      debugPrint('User Email Not Verified');
      emit(
        state.copyWith(
          isGuest: false,
          pageStatus: AppPageStatus.awitingEmailVerification,
          user: user,
        ),
      );
    } else {
      debugPrint('Fetching Rider Profile for ${user.email}');
      _usersProfileSubscription = _riderProfileRepository
          .getRiderProfile(email: user.email)
          .listen((event) {
        final profile = event.data() as RiderProfile?;
        if (profile != null) {
          debugPrint('User Profile exists: ${profile.email}');
          emit(
            state.copyWith(
              user: user,
              isGuest: false,
              usersProfile: profile,
              pageStatus: AppPageStatus.profile,
            ),
          );
        } else {
          debugPrint('No User Profile, needs setup');
          emit(
            state.copyWith(
              user: user,
              pageStatus: AppPageStatus.profileSetup,
            ),
          );
        }
      });
    }
  }

  /// Set viewingProfile to Null
  void clearViewingProfile() {
    emit(
      state.copyWith(
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        // ignore: avoid_redundant_argument_values
        horseProfile: null,
        isForRider: true,
      ),
    );
  }

  bool isAuthorized() {
    final viewingProfile = state.viewingProfile;
    final usersProfile = state.usersProfile;
    if (viewingProfile == null) {
      return true;
    }
    if (usersProfile == null) {
      return false;
    }
    return viewingProfile.instructors
            ?.any((element) => element.id == usersProfile.id) ??
        false;
  }

  /// Opens a Rider Profile Page for  [toBeViewedEmail]
  void gotoProfilePage({
    required BuildContext context,
    required String toBeViewedEmail,
  }) {
    debugPrint(
      'gotoProfilePage for $toBeViewedEmail, for User: '
      '${state.usersProfile?.email}',
    );
    if (state.usersProfile?.email != toBeViewedEmail) {
      _riderProfileRepository
          .getRiderProfile(email: toBeViewedEmail.toLowerCase())
          .first
          .then((value) {
        if (value.data() != null) {
          final viewingProfile = value.data()! as RiderProfile;
          emit(
            state.copyWith(
              viewingProfile: viewingProfile,
              isViewing: true,
            ),
          );
          Navigator.of(context, rootNavigator: true).pushNamed(
            RiderProfilePage.routeName,
          );
        } else {
          emit(
            state.copyWith(
              isError: true,
              errorMessage: 'Profile Not Found',
            ),
          );
        }
      });
    } else {
      debugPrint('Returning to Users Profile');
      // goBackToUsersProfile(context);
    }
  }

  /// Called when User finishes setting up their profile
  void resetProfileSetup() {
    debugPrint('Changing showingProfileSetup to false');
    emit(state.copyWith(pageStatus: AppPageStatus.profile));
  }

  void test(String test) {
    debugPrint('Testing From $test');
  }

  Future<void> logOutRequested() async {
    emit(
      state.copyWith(
        user: User.empty,
        // ignore: avoid_redundant_argument_values
        usersProfile: null,
        // ignore: avoid_redundant_argument_values
        horseProfile: null,
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        pageStatus: AppPageStatus.auth,
        isGuest: false,
      ),
    );

    await _authenticationRepository.logOut();
  }

/* ***************************************************************************

******************************* Horse Profile**********************************

***************************************************************************** */

  /// Handles the selection of a Horse Profile
  void horseProfileSelected({
    required String id,
  }) {
    emit(state.copyWith(index: 0, isForRider: false, horseId: id));
    _getHorseProfile(id: id);
  }

  /// Retrieves the Horse Profile from the database if needed
  Future<void> _getHorseProfile({required String id}) async {
    debugPrint('getHorseProfile for $id');
    if (state.horseProfile?.id == id) {
      debugPrint('Horse Profile already retrieved');
      emit(
        state.copyWith(
          index: 0,
          isForRider: false,
          horseId: state.horseProfile?.id,
          horseProfile: state.horseProfile,
        ),
      );
    } else {
      debugPrint('Horse Profile not retrieved, getting now');
      try {
        _horseProfileSubscription =
            _horseProfileRepository.getHorseProfile(id: id).listen((event) {
          final horseProfile = event.data() as HorseProfile?;
          debugPrint('Horse Profile Retrieved: ${horseProfile?.name}');
          if (horseProfile != null) {
            if (!isOwner()) {
              debugPrint('Not Owner');
              _riderProfileRepository
                  .getRiderProfile(email: horseProfile.currentOwnerId)
                  .first
                  .then((value) {
                final ownerProfile = value.data() as RiderProfile?;
                debugPrint('Owner Profile Retrieved: ${ownerProfile?.name}');
                emit(
                  state.copyWith(
                    index: 0,
                    isForRider: false,
                    horseId: horseProfile.id,
                    horseProfile: horseProfile,
                    ownersProfile: ownerProfile,
                  ),
                );
              });
            } else {
              debugPrint('Owner');
              emit(
                state.copyWith(
                  index: 0,
                  isForRider: false,
                  horseId: horseProfile.id,
                  horseProfile: horseProfile,
                ),
              );
            }
          }
        });
      } on FirebaseException catch (e) {
        debugPrint('Failed to get Horse Profile: $e');
        emit(state.copyWith(errorMessage: e.message.toString()));
      }
    }
  }

  /// Returns if the current user is the owner of the horse profile
  bool isOwner() {
    return state.usersProfile?.email == state.horseProfile?.currentOwnerId;
  }

  /// Determines if the Horse Profile is a Student Horse of the current user
  bool isStudentHorse() {
    return state.horseProfile?.instructors
            ?.any((instructor) => instructor.id == state.usersProfile?.email) ??
        false;
  }

  /// Create a request to the owner of the horse
  /// to add user as trainer and add horse as student horse
  /// or remove the horse as a student horse if already added
  void requestToBeStudentHorse() {
    if (isStudentHorse()) {
      _removeStudentHorse(state.horseProfile!);
    } else {
      _addStudentHorseRequest();
    }
  }

  ///  Removes the horse from the users student horse list
  void _removeStudentHorse(HorseProfile horseProfile) {
    debugPrint('Remove Student Horse');
    state.usersProfile?.studentHorses
        ?.removeWhere((element) => element.id == horseProfile.id);
    horseProfile.instructors
        ?.removeWhere((element) => element.id == state.usersProfile?.email);

    if (state.usersProfile != null) {
      try {
        _horseProfileRepository.createOrUpdateHorseProfile(
          horseProfile: horseProfile,
        );
        _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: state.usersProfile!,
        );
      } on FirebaseException catch (e) {
        debugPrint('Error: $e');
      }
    } else {
      debugPrint('Error: No User Profile Found to remove Student Horse');
    }
  }

  ///  Creates a request to add the horse as a student horse
  void _addStudentHorseRequest() {
    debugPrint('Request to add horse as student horse');
    if (state.ownersProfile == null) {
      debugPrint('Something went Wrong, No owner profile found');
      return;
    } else {
      final requestHorse = _createRequestHorse();
      final group = _createStudentHorseRequestGroup(requestHorse);
      final message = _createStudentHorseRequestMessage(requestHorse, group.id);

      _messagesRepository
        ..createOrUpdateGroup(group: group)
        ..createOrUpdateMessage(message: message, id: message.messsageId);
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Request to add '
              '${state.horseProfile?.name} as a student horse has been sent to '
              '${state.ownersProfile?.name}',
        ),
      );

      // navigateToMessagesPage(context, group);
    }
  }

  BaseListItem _createRequestHorse() {
    return BaseListItem(
      id: state.horseProfile?.id,
      name: state.horseProfile?.name,
      imageUrl: state.horseProfile?.picUrl,
      parentId: state.horseProfile?.currentOwnerId,
      message: state.horseProfile?.currentOwnerName,
      isCollapsed: false,
      isSelected: false,
    );
  }

  Group _createStudentHorseRequestGroup(
    BaseListItem requestHorse,
  ) {
    final id = _createGroupId().toString();
    final memberNames = [state.usersProfile?.name, state.ownersProfile?.name]
        .map((e) => e!)
        .toList();
    final memberIds = [state.usersProfile?.email, state.ownersProfile?.email]
        .map((e) => e!.toLowerCase())
        .toList();

    return Group(
      id: id,
      type: GroupType.private,
      parties: memberNames,
      partiesIds: memberIds,
      createdBy: state.usersProfile!.name,
      createdOn: DateTime.now(),
      lastEditBy: state.usersProfile?.name,
      lastEditDate: DateTime.now(),
      recentMessage: _createStudentHorseRequestMessage(
        requestHorse,
        id,
      ),
    );
  }

  Message _createStudentHorseRequestMessage(
    BaseListItem requestHorse,
    String groupId,
  ) {
    return Message(
      date: DateTime.now(),
      id: groupId,
      sender: state.usersProfile?.name,
      senderProfilePicUrl: state.usersProfile?.picUrl,
      messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: 'Student Horse Request',
      message: '${state.usersProfile?.name} has requested to add '
          '${state.horseProfile?.name} as a student horse.',
      recipients: [state.usersProfile?.name, state.ownersProfile?.name]
          .map((e) => e!)
          .toList(),
      messageType: MessageType.STUDENT_HORSE_REQUEST,
      requestItem: requestHorse,
    );
  }

  StringBuffer _createGroupId() {
    return StringBuffer()
      ..write(
        convertEmailToPath(
          state.usersProfile!.email.toLowerCase(),
        ),
      )
      ..write(
        convertEmailToPath(
          state.ownersProfile!.email.toLowerCase(),
        ),
      );
  }

  void navigateToMessagesPage(BuildContext context, Group group) {
    // Navigator.of(context, rootNavigator: true).restorablePushNamed(
    //   MessagesPage.routeName,
    //   arguments: MessageArguments(
    //     group: group,
    //     riderProfile: state.usersProfile,
    //   ),
    // );
  }

  void transferHorseProfile() {
    emit(
      state.copyWith(
        isMessage: true,
        errorMessage: 'Transfer Horse Profile Currently Not Available',
      ),
    );
    // TODO(mfrenchy77): Implement Transfer Horse Profile
    debugPrint('Transfer this dum horse!!');
  }

  Future<void> deleteHorseProfileFromUser() async {
    if (state.ownersProfile != null && state.horseProfile != null) {
      // Update owner's profile
      final updatedOwnersProfile = state.ownersProfile!
        ..ownedHorses
            ?.removeWhere((element) => element.id == state.horseProfile!.id);

      // Update horse profile
      final updatedHorseProfile = state.horseProfile!
        ..currentOwnerId = 'NONE'
        ..currentOwnerName = 'NONE'
        ..lastEditBy = state.ownersProfile!.name
        ..lastEditDate = DateTime.now();

      try {
        // Persist changes
        await _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: updatedOwnersProfile,
        );
        await _horseProfileRepository.createOrUpdateHorseProfile(
          horseProfile: updatedHorseProfile,
        );

        // Emit new state
        emit(
          state.copyWith(
            ownersProfile: updatedOwnersProfile,
            horseProfile: updatedHorseProfile,
          ),
        );
      } catch (e) {
        // Handle errors, perhaps by emitting an error state
        debugPrint('Error deleting horse profile: $e');
      }
    }
  }

  /* **************************************************************
   
   **************************    Navigation**************************

   **************************************************************** */

  /// Changes the [index] of the current page in the app.
  /// 0: RiderProfilePage/ HorseProfilePage
  /// 1: SkillTreePage
  /// 2: ResourcesPage
  void changeIndex(int index) {
    switch (index) {
      case 0:
        emit(
          state.copyWith(
            index: index,
            pageStatus: AppPageStatus.profile,
          ),
        );
        break;
      case 1:
        emit(
          state.copyWith(
            index: index,
            pageStatus: AppPageStatus.skillTree,
          ),
        );
        break;
      case 2:
        emit(
          state.copyWith(
            index: index,
            pageStatus: AppPageStatus.resource,
          ),
        );
        break;
    }
  }

  /// Handles the back button press
  void backPressed() {
    if (state.index == 2) {
      emit(state.copyWith(index: 1, pageStatus: AppPageStatus.skillTree));
    } else if (state.index == 1) {
      emit(state.copyWith(index: 0, pageStatus: AppPageStatus.profile));
    } else {
      emit(state.copyWith(index: 0, pageStatus: AppPageStatus.profile));
    }
  }

  void navigateToSkillsList() {
    debugPrint('navigateToSkillsList');
    emit(
      state.copyWith(
        index: 1,
        pageStatus: AppPageStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.SkillList,
        isFromTrainingPath: false,
        isFromTrainingPathList: false,
        isFromProfile: state.index == 0,
      ),
    );
  }

  /// Clears the Error Message and Snackbar
  void clearErrorMessage() {
    emit(state.copyWith(isMessage: false, errorMessage: ''));
  }

  /// Clear the MessageSnackbar
  void clearMessage() {
    emit(state.copyWith(isMessage: false, errorMessage: ''));
  }

  @override
  Future<void> close() {
    _resourcesSubscription.cancel();
    _skillsSubscription.cancel();
    _viewingProfileSubscription.cancel();
    _horseProfileSubscription?.cancel();
    _usersProfileSubscription?.cancel();

    _userSubscription.cancel();
    return super.close();
  }
}
