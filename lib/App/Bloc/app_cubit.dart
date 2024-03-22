// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
  StreamSubscription<QuerySnapshot<Object?>>? _messagesStream;
  StreamSubscription<QuerySnapshot<Object?>>? _resourcesStream;
  StreamSubscription<QuerySnapshot<Object?>>? _skillsSubscription;
  StreamSubscription<QuerySnapshot<Object?>>? _conversationsStream;
  StreamSubscription<QuerySnapshot<Object?>>? _trainingPathsStream;
  StreamSubscription<DocumentSnapshot<Object?>>? _usersProfileSubscription;
  StreamSubscription<DocumentSnapshot<Object?>>? _horseProfileSubscription;
  late final StreamSubscription<RiderProfile?> _viewingProfileSubscription;

  Timer? _emailVerificationTimer;

/* **************************************************************************

******************************* User's Profile *********************************

***************************************************************************** */
  void _beginListeningForUserChanges() {
    _getSkillTreeLists();
    _userSubscription = _authenticationRepository.user.listen((user) {
      debugPrint('Listening for user changes: '
          '\nUserEmail: ${user?.email} '
          '\nUserGuest: ${user?.isGuest} '
          '\nUserId: ${user?.id}');
      if (user != null && user.id.isNotEmpty) {
        emit(state.copyWith(pageStatus: AppPageStatus.loading));
        debugPrint('User is authenticated');
        _getRiderProfile(user: user);
      } else {
        debugPrint('User is unauthenticated or email not verified');
        emit(state.copyWith(isGuest: true, pageStatus: AppPageStatus.loaded));
      }
    });
  }

  void _getRiderProfile({required User user}) {
    if (user.isGuest) {
      debugPrint('Guest User');
      emit(
        state.copyWith(
          status: AppStatus.authenticated,
          pageStatus: AppPageStatus.loaded,
          isGuest: true,
          user: user,
        ),
      );
    } else if (!user.emailVerified) {
      debugPrint('User Email Not Verified');
      _checkEmailVerificationStatus();
      emit(
        state.copyWith(
          user: user,
          isGuest: true,
          isEmailVerification: true,
          pageStatus: AppPageStatus.loaded,
          status: AppStatus.unauthenticated,
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
              status: AppStatus.authenticated,
              pageStatus: AppPageStatus.loaded,
            ),
          );
        } else {
          debugPrint('No User Profile, needs setup');
          emit(
            state.copyWith(
              user: user,
              isProfileSetup: true,
              status: AppStatus.authenticated,
              pageStatus: AppPageStatus.loaded,
            ),
          );
        }
      });
    }
  }

  /// Resend the email verification
  Future<void> resendEmailVerification() async {
    await _authenticationRepository.resendEmailVerification();
    emit(
      state.copyWith(
        isMessage: true,
        errorMessage: 'Email Verification Sent',
      ),
    );
    await openEmail(state.user.email);
  }

  void clearProfileSetup() {
    debugPrint('Clearing Profile Setup');
    emit(state.copyWith(isProfileSetup: false));
  }

  Future<void> openEmail(String email) async {
    final emailProvider = email.split('@').last;
    final urlString = 'https://$emailProvider';

    // Correct way to parse the URL
    final url = Uri.parse(urlString);

    debugPrint('Opening Email: $url');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
      // Handle the case where the URL could not be launched.
    }
  }

  /// Peroiodically checks the email verification status.
  void _checkEmailVerificationStatus() {
    _emailVerificationTimer?.cancel();
    _emailVerificationTimer =
        Timer.periodic(const Duration(seconds: 10), (_) async {
      debugPrint('Checking Email Verification Status');
      await _authenticationRepository.reloadCurrentUser();
      final isVerified = _authenticationRepository.isEmailVerified();
      emit(
        state.copyWith(isEmailVerification: !isVerified),
      );

      if (isVerified) {
        _emailVerificationTimer?.cancel();
        debugPrint('Email is verified in Timer');
        emit(
          state.copyWith(
            isMessage: true,
            isEmailVerification: false,
            errorMessage: 'Email has been verified',
          ),
        );
      }
    });
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

  /// Opens a Rider Profile Page for  [email]
  void getProfileToBeViewed({
    required String email,
  }) {
    debugPrint('getting Profile for $email');

    if (state.usersProfile?.email != email) {
      _riderProfileRepository
          .getRiderProfile(email: email.toLowerCase())
          .first
          .then((value) {
        if (value.data() != null) {
          final viewingProfile = value.data()! as RiderProfile;
          debugPrint('Viewing Profile Retrieved: ${viewingProfile.name}');

          emit(
            state.copyWith(
              viewingProfile: viewingProfile,
              pageStatus: AppPageStatus.loaded,
            ),
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

  /// Back Button Pressed in the Viewing Profile or Horse Profile
  void profileBackButtonPressed() {
    debugPrint('Back to Users Profile/Guest Profile');

    if (!state.isForRider) {
      emit(
        state.copyWith(
          horseId: '',
          isForRider: true,
          // ignore: avoid_redundant_argument_values
          horseProfile: null,
        ),
      );
    }
    if (state.isViewing) {
      emit(
        state.copyWith(
          isViewing: false,
          // ignore: avoid_redundant_argument_values
          viewingProfile: null,
          viewingProfielEmail: '',
        ),
      );
    }

    // emit(
    //   state.copyWith(
    //     // ignore: avoid_redundant_argument_values
    //     viewingProfile: null,
    //     // ignore: avoid_redundant_argument_values
    //     horseProfile: null,
    //     viewingProfielEmail: '',
    //     isForRider: true,
    //     isViewing: false,
    //   ),
    // );
    // navigateToProfile();
  }

  /// Updates the skill level for the rider
  void _updateRiderSkillLevel(
    RiderProfile? riderProfile,
    LevelState levelState,
    BaseListItem note,
  ) {
    if (riderProfile != null) {
      if (state.skill != null) {
        final timestamp = DateTime.now();
        final skillLevel = riderProfile.skillLevels?.firstWhere(
              (element) => element.skillId == state.skill?.id,
              orElse: () => SkillLevel(
                lastEditDate: timestamp,
                skillId: state.skill!.id,
                skillName: state.skill!.skillName,
                lastEditBy: state.usersProfile?.name,
              ),
            ) ??
            SkillLevel(
              lastEditDate: timestamp,
              skillId: state.skill!.id,
              skillName: state.skill!.skillName,
              lastEditBy: state.usersProfile?.name,
            );

        riderProfile.skillLevels?.remove(skillLevel);
        riderProfile.skillLevels?.add(
          SkillLevel(
            levelState: levelState,
            lastEditDate: timestamp,
            skillId: state.skill!.id,
            skillName: state.skill!.skillName,
            lastEditBy: state.usersProfile?.name,
          ),
        );

        _addNoteToProfile(riderProfile, note);
      }
    } else {
      debugPrint('riderProfile is null');
    }
  }

// Adds a note to the rider's profile
  void _addNoteToProfile(RiderProfile riderProfile, BaseListItem note) {
    riderProfile.notes ??= []; // Ensure the notes list is initialized
    riderProfile.notes!.add(note);
    _persistRiderProfileChanges(riderProfile);
  }

  /// Persists the changes to the rider profile to the repository
  void _persistRiderProfileChanges(
    RiderProfile? riderProfile,
  ) {
    if (riderProfile != null) {
      try {
        _riderProfileRepository
            .createOrUpdateRiderProfile(riderProfile: riderProfile)
            .then(
              (value) => emit(
                state.copyWith(
                  isMessage: true,
                  errorMessage: "Updated ${riderProfile.name}'s profile",
                ),
              ),
            );
      } catch (error) {
        emit(
          state.copyWith(
            isError: true,
            errorMessage: "Failed to update ${riderProfile.name}'s profile  ",
          ),
        );
      }
    } else {
      debugPrint('riderProfile is null');
    }
  }

  /// Called when User finishes setting up their profile
  void resetProfileSetup() {
    debugPrint('Changing showingProfileSetup to false');
    emit(state.copyWith(pageStatus: AppPageStatus.profile, isForRider: true));
  }

  void test(String test) {
    debugPrint('Testing From $test');
  }

  /// Returns the current profile being viewed
  RiderProfile? determineCurrentProfile() {
    if (state.viewingProfile != null) {
      return state.viewingProfile!;
    } else if (state.usersProfile != null) {
      return state.usersProfile!;
    } else {
      return null;
    }
  }

  Future<void> logOutRequested() async {
    emit(
      state.copyWith(
        status: AppStatus.unauthenticated,
        user: User.empty,
        // ignore: avoid_redundant_argument_values
        usersProfile: null,
        // ignore: avoid_redundant_argument_values
        horseProfile: null,
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        isGuest: true,
      ),
    );

    await _authenticationRepository.logOut();
    navigateToAuth();
  }

  /// sends a message to the a riderProfile with a
  /// request to add them as your instructor
  Future<void> createInstructorRequest({
    required RiderProfile instructorProfile,
  }) async {
    final user = state.usersProfile!;
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final requestItem = BaseListItem(
      name: user.name,
      imageUrl: user.picUrl,
      isCollapsed: true,
      isSelected: false,
      id: user.email.toLowerCase(),
    );
    final sortedEmails = <String>[
      user.email.toLowerCase(),
      instructorProfile.email.toLowerCase(),
    ]..sort();

    final idbuff = sortedEmails.join('_');
    final conversationId = convertEmailToPath(idbuff);

    final message = Message(
      date: DateTime.now(),
      id: conversationId,
      sender: user.name,
      messsageId: messageId,
      requestItem: requestItem,
      subject: 'Instructor Request',
      senderProfilePicUrl: user.picUrl,
      messageType: MessageType.INSTRUCTOR_REQUEST,
      recipients: [user.name, instructorProfile.name],
      message: '${user.name} has requested '
          '${instructorProfile.name} to be their Instructor',
    );

    final conversation = Conversation(
      id: conversationId,
      createdBy: user.name,
      lastEditBy: user.name,
      recentMessage: message,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      parties: [user.name, instructorProfile.name],
      partiesIds: [
        user.email.toLowerCase(),
        instructorProfile.email.toLowerCase(),
      ],
    );

    try {
      await _messagesRepository.createOrUpdateConversation(
        conversation: conversation,
      );
      await _messagesRepository.createOrUpdateMessage(
        message: message,
        conversationId: conversationId,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Instructor request sent to ${instructorProfile.name}',
        ),
      );
    } catch (e) {
      debugPrint('Failed to send instructor request: $e');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to send request',
        ),
      );
    }
  }

  /// sends a message to a Viewing Profile with a
  /// request to add them as your student
  Future<void> createStudentRequest({
    required RiderProfile studentProfile,
  }) async {
    final user = state.usersProfile!;
    final requestItem = BaseListItem(
      name: user.name,
      isCollapsed: true,
      isSelected: false,
      imageUrl: user.picUrl,
      id: user.email.toLowerCase(),
    );

    final emails = <String>[
      user.email.toLowerCase(),
      studentProfile.email.toLowerCase(),
    ]..sort();

    final idbuff = emails.join('_');
    final conversationId = convertEmailToPath(idbuff);

    final message = Message(
      id: conversationId,
      sender: user.name,
      date: DateTime.now(),
      requestItem: requestItem,
      subject: 'Student Request',
      senderProfilePicUrl: user.picUrl,
      messageType: MessageType.STUDENT_REQUEST,
      recipients: [user.name, studentProfile.name],
      message: '${user.name} has requested '
          '${studentProfile.name} to be their Student',
      messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
    );

    final conversation = Conversation(
      id: conversationId,
      createdBy: user.name,
      lastEditBy: user.name,
      recentMessage: message,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      parties: [user.name, studentProfile.name],
      partiesIds: [
        user.email.toLowerCase(),
        studentProfile.email.toLowerCase(),
      ],
    );

    try {
      await _messagesRepository.createOrUpdateConversation(
        conversation: conversation,
      );
      await _messagesRepository.createOrUpdateMessage(
        message: message,
        conversationId: conversationId,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Student request sent to ${studentProfile.name}',
        ),
      );
    } catch (e) {
      debugPrint('Failed to send student request: $e');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to send request',
        ),
      );
    }
  }

  ///  removes a student from the your student list
  ///  and removes the your from the their instructor list
  ///  and adds a note to both users
  Future<void> removeStudent({
    required RiderProfile studentProfile,
  }) async {
    final user = state.usersProfile!;

    // Remove student from the user's list
    user.students?.removeWhere(
      (student) => student.id == studentProfile.email.toLowerCase(),
    );

    // Remove user from the student's instructor list
    studentProfile.instructors?.removeWhere(
      (instructor) => instructor.id == user.email.toLowerCase(),
    );

    // Add notes about the removal to both profiles
    final userNote = BaseListItem(
      message: user.name,
      date: DateTime.now(),
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      name: 'Removed ${studentProfile.name} as Student',
    );

    final studentNote = BaseListItem(
      message: user.name,
      date: DateTime.now(),
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      name: '${user.name} removed you as Instructor',
    );

    user.notes?.add(userNote);
    studentProfile.notes?.add(studentNote);

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: user,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: studentProfile,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Removed ${studentProfile.name} as a Student',
        ),
      );
    } catch (e) {
      debugPrint('Failed to remove student: $e');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to remove student',
        ),
      );
    }
  }

  ///  removes a Viewing Profile from your Instructor list
  ///  and removes you from their student list and adds a note to both users
  Future<void> removeInstructor({
    required RiderProfile instructorProfile,
  }) async {
    final user = state.usersProfile!;

    // Remove instructor from the user's list
    user.instructors?.removeWhere(
      (instructor) => instructor.id == instructorProfile.email.toLowerCase(),
    );

    // Remove user from the instructor's student list
    instructorProfile.students
        ?.removeWhere((student) => student.id == user.email.toLowerCase());

    // Add notes about the removal to both profiles
    final userNote = BaseListItem(
      message: user.name,
      date: DateTime.now(),
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      name: 'Removed ${instructorProfile.name} as Instructor',
    );

    final instructorNote = BaseListItem(
      id: DateTime.now().toString(),
      message: user.name,
      date: DateTime.now(),
      imageUrl: LogTag.Edit.toString(),
      name: '${user.name} removed you as Student',
    );

    user.notes?.add(userNote);
    instructorProfile.notes?.add(instructorNote);

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: user,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: instructorProfile,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Removed ${instructorProfile.name} as an Instructor',
        ),
      );
    } catch (e) {
      debugPrint('Failed to remove instructor: $e');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to remove instructor',
        ),
      );
    }
  }

  /// adds the Viewing Profile to the users contacts
  /// and adds a note to both users
  Future<void> addToContact({
    required RiderProfile riderProfile,
  }) async {
    final user = state.usersProfile!;
    final contact = BaseListItem(
      isCollapsed: true,
      isSelected: false,
      name: riderProfile.name,
      imageUrl: riderProfile.picUrl,
      id: riderProfile.email.toLowerCase(),
    );

    // Adding the contact to each other's savedProfilesList and notes
    user.savedProfilesList ??= [];
    user.savedProfilesList!.add(contact);
    user.notes?.add(
      BaseListItem(
        message: user.name,
        date: DateTime.now(),
        id: DateTime.now().toString(),
        imageUrl: LogTag.Edit.toString(),
        name: 'Added ${riderProfile.name} to contacts',
      ),
    );

    riderProfile.savedProfilesList ??= [];
    riderProfile.savedProfilesList!.add(
      BaseListItem(
        name: user.name,
        isCollapsed: true,
        isSelected: false,
        imageUrl: user.picUrl,
        id: user.email.toLowerCase(),
      ),
    );
    riderProfile.notes?.add(
      BaseListItem(
        message: user.name,
        date: DateTime.now(),
        id: DateTime.now().toString(),
        imageUrl: LogTag.Edit.toString(),
        name: '${user.name} added you to their contacts',
      ),
    );

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: riderProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: user,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Added ${riderProfile.name} to contacts',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to add contact: $e',
        ),
      );
    }
  }

  /// removes the Viewing Profile from the user's contacts
  Future<void> removeFromContacts({
    required RiderProfile riderProfile,
  }) async {
    final user = state.usersProfile!;

    user.savedProfilesList
        ?.removeWhere((item) => item.id == riderProfile.email.toLowerCase());
    user.notes?.add(
      BaseListItem(
        message: user.name,
        date: DateTime.now(),
        id: DateTime.now().toString(),
        imageUrl: LogTag.Edit.toString(),
        name: 'Removed ${riderProfile.name} from contacts',
      ),
    );

    riderProfile.savedProfilesList
        ?.removeWhere((item) => item.id == user.email.toLowerCase());
    riderProfile.notes?.add(
      BaseListItem(
        message: user.name,
        date: DateTime.now(),
        id: DateTime.now().toString(),
        imageUrl: LogTag.Edit.toString(),
        name: '${user.name} removed you from their contacts',
      ),
    );

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: riderProfile,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: user,
      );
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Removed ${riderProfile.name} from contacts',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to remove contact: $e',
        ),
      );
    }
  }

  /// Returns true if the viewingProfile is in the userProfile contacts
  bool isContact() {
    return state.usersProfile?.savedProfilesList
            ?.any((element) => element.id == state.viewingProfile?.email) ??
        false;
  }

  ///  Returns true if the userProfile is an instructor of the viewingProfile
  bool isInstuctor() {
    return state.viewingProfile?.instructors
            ?.any((element) => element.id == state.usersProfile?.email) ??
        false;
  }

/* ***************************************************************************

******************************* Horse Profile**********************************

***************************************************************************** */

  /// Retrieves the Horse Profile from the database if needed
  Future<void> getHorseProfile({required String id}) async {
    debugPrint('getHorseProfile for $id');
    if (state.horseProfile?.id == id) {
      debugPrint('Horse Profile already retrieved');
      emit(
        state.copyWith(
          //  index: 0,
          isForRider: false,
          horseId: state.horseProfile?.id,
          horseProfile: state.horseProfile,
          pageStatus: AppPageStatus.loaded,
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
            emit(
              state.copyWith(
                // index: 0,
                horseId: horseProfile.id,
                horseProfile: horseProfile,
                // isForRider: false,
              ),
            );
            if (!isOwner() &&
                state.ownersProfile?.email !=
                    state.horseProfile?.currentOwnerId) {
              debugPrint('Not Owner');
              _riderProfileRepository
                  .getRiderProfile(email: horseProfile.currentOwnerId)
                  .first
                  .then((value) {
                final ownerProfile = value.data() as RiderProfile?;
                debugPrint('Owner Profile Retrieved: ${ownerProfile?.name}');
                emit(
                  state.copyWith(
                    ownersProfile: ownerProfile,
                  ),
                );
              });
            } else {
              debugPrint('Owner');
              // emit(state.copyWith(ownersProfile: state.usersProfile));
            }
          }
        });
      } on FirebaseException catch (e) {
        debugPrint('Failed to get Horse Profile: $e');
        emit(
          state.copyWith(
            pageStatus: AppPageStatus.error,
            errorMessage: e.message.toString(),
          ),
        );
      }
    }
  }

  void _persistHorseProfileChanges(HorseProfile horseProfile) {
    debugPrint('Persisting Horse Profile Changes');
    try {
      _horseProfileRepository
          .createOrUpdateHorseProfile(horseProfile: horseProfile)
          .then(
            (value) => emit(
              state.copyWith(
                isMessage: true,
                errorMessage: "${state.horseProfile?.name}'s profile updated",
              ),
            ),
          );
    } catch (error) {
      debugPrint('Error: $error');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: "Error updating ${state.horseProfile?.name}'s profile",
        ),
      );
    }
  }

  void _updateHorseSkillLevel(
    HorseProfile horseProfile,
    LevelState levelState,
    BaseListItem note,
  ) {
    if (state.horseProfile != null && state.skill != null) {
      final timestamp = DateTime.now();
      final updatedSkillLevels = horseProfile.skillLevels ?? [];

      // Attempt to find existing skill level index
      final existingIndex = updatedSkillLevels
          .indexWhere((element) => element.skillId == state.skill?.id);

      // Replace or add the skill level
      if (existingIndex != -1) {
        updatedSkillLevels[existingIndex] = SkillLevel(
          levelState: levelState,
          lastEditDate: timestamp,
          skillId: state.skill!.id,
          skillName: state.skill!.skillName,
          lastEditBy: state.usersProfile?.name,
        );
      } else {
        updatedSkillLevels.add(
          SkillLevel(
            levelState: levelState,
            lastEditDate: timestamp,
            skillId: state.skill!.id,
            skillName: state.skill!.skillName,
            lastEditBy: state.usersProfile?.name,
          ),
        );
      }

      // Update the horse profile with the new list
      horseProfile.skillLevels = updatedSkillLevels;
      debugPrint('Skills: ${horseProfile.skillLevels?.length}');
      _addNoteToHorseProfile(horseProfile, note);
    } else {
      debugPrint('horse Profile or skill is null');
    }
  }

  /// Returns if the current user is the owner of the horse profile
  bool isOwner() {
    if (state.horseProfile == null || state.usersProfile == null) {
      return false;
    } else {
      return state.usersProfile?.email == state.horseProfile?.currentOwnerId;
    }
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
      final conversation =
          _createStudentHorseRequestConnversation(requestHorse);
      final message =
          _createStudentHorseRequestMessage(requestHorse, conversation.id);

      _messagesRepository
        ..createOrUpdateConversation(conversation: conversation)
        ..createOrUpdateMessage(
            message: message, conversationId: conversation.id);
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

  Conversation _createStudentHorseRequestConnversation(
    BaseListItem requestHorse,
  ) {
    final id = _createHorseConversationId();
    final memberNames = [state.usersProfile?.name, state.ownersProfile?.name]
        .map((e) => e!)
        .toList();
    final memberIds = [state.usersProfile?.email, state.ownersProfile?.email]
        .map((e) => e!.toLowerCase())
        .toList();

    return Conversation(
      id: id,
      parties: memberNames,
      partiesIds: memberIds,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      createdBy: state.usersProfile!.name,
      lastEditBy: state.usersProfile?.name,
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
      requestItem: requestHorse,
      subject: 'Student Horse Request',
      sender: state.usersProfile?.name,
      messageType: MessageType.STUDENT_HORSE_REQUEST,
      senderProfilePicUrl: state.usersProfile?.picUrl,
      message: '${state.usersProfile?.name} has requested to add '
          '${state.horseProfile?.name} as a student horse.',
      messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
      recipients: [state.usersProfile?.name, state.ownersProfile?.name]
          .map((e) => e!)
          .toList(),
    );
  }

  /// Creates a unique group id for the message
  String _createHorseConversationId() {
    // Create a list of the two emails, converted to paths and in lowercase
    final emails = <String>[
      state.usersProfile?.email.toLowerCase() as String,
      state.ownersProfile?.email.toLowerCase() as String,
    ]..sort();

    // Join the emails with an underscore
    final idbuff = emails.join('_');
    return convertEmailToPath(idbuff);
  }

  /// Adds a note to the horse's profile and persists the changes
  void _addNoteToHorseProfile(HorseProfile horseProfile, BaseListItem note) {
    horseProfile.notes ??= []; // Ensure the notes list is initialized
    horseProfile.notes!.add(note);
    _persistHorseProfileChanges(horseProfile);
  }

  void navigateToMessagesPage(BuildContext context, Conversation group) {
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

/* **************************************************************************

******************************* Skills Tree **********************************

***************************************************************************** */

  /// Retrieves the Skills from the database if needed

  void _getSkillTreeLists() {
    debugPrint('getSkillTreeLists');

    _getSkills();
    _getTrainingPaths();
    _getResources();
  }

  void _getSkills() {
    debugPrint('getting Skills called');
    if (state.allSkills.isEmpty) {
      debugPrint('Skills not retrieved yet');
      _skillsSubscription = _skillTreeRepository.getSkills().listen((event) {
        final skills = event.docs.map((doc) => (doc.data()) as Skill?).toList()
          ..sort((a, b) => a!.position.compareTo(b!.position));
        debugPrint('Skills Retrieved: ${skills.length}');

        emit(
          state.copyWith(
            allSkills: skills,
            sortedSkills: sortedSkills(),
          ),
        );
      });
    } else {
      debugPrint('Skills already retrieved');
    }
  }

  void _getTrainingPaths() {
    debugPrint('Get TrainingPaths Called');
    if (state.trainingPaths.isEmpty) {
      debugPrint('Training Paths not retrieved yet');
      _trainingPathsStream =
          _skillTreeRepository.getAllTrainingPaths().listen((event) {
        final trainingPaths =
            event.docs.map((doc) => (doc.data()) as TrainingPath?).toList();
        debugPrint('Training Paths Retrieved: ${trainingPaths.length}');
        emit(state.copyWith(trainingPaths: trainingPaths));
      });
    } else {
      debugPrint('Training Paths already retrieved');
    }
  }

  void _getResources() {
    debugPrint('Get Resources Called');
    if (state.resources.isEmpty) {
      debugPrint('Resources not retrieved yet');
      _resourcesStream = _resourcesRepository.getResources().listen((event) {
        final resources =
            event.docs.map((doc) => (doc.data()) as Resource?).toList();
        debugPrint('Resources Retrieved: ${resources.length}');
        emit(state.copyWith(resources: resources));
      });
    } else {
      debugPrint('Resources already retrieved');
    }
  }

  Skill getSkillFromSkillName(String skillName) {
    final skill = state.allSkills.firstWhere(
      (element) => element?.skillName == skillName,
      orElse: () => null,
    );
    return skill!;
  }
  // /// Returns a list of skills that are either for a
  // /// horse or rider
  // List<Skill?> getHorseOrRiderSkills() {
  //   final sortedSkills = state.allSkills
  //       .where(
  //         (element) => element?.rider == state.isForRider,
  //       )
  //       .toList();
  //   debugPrint('Skills Retrieved: ${sortedSkills.length}');
  //   return sortedSkills;
  // }

  /// Adds a Resource to the selected Skill

  void addResourceToSkill({
    required Resource? resource,
    required Skill? skill,
  }) {
    if (resource != null) {
      debugPrint('Resource Selected: ${resource.name}');

      if (skill != null) {
        debugPrint('Skill Selected: ${skill.skillName}');
        final skillTreeIds = resource.skillTreeIds ?? [];

        // Toggle the presence of skill.id in skillTreeIds
        if (skillTreeIds.contains(skill.id)) {
          skillTreeIds.remove(skill.id);
        } else {
          skillTreeIds.add(skill.id);
        }

        resource.skillTreeIds = skillTreeIds;

        try {
          _resourcesRepository.createOrUpdateResource(resource: resource);
        } catch (e) {
          debugPrint('Error: $e');
          emit(state.copyWith(errorMessage: e.toString(), isError: true));
        }
      } else {
        debugPrint('skill is null');
        emit(state.copyWith(errorMessage: 'skill is null', isError: true));
      }
    } else {
      debugPrint('resource is null');
      emit(state.copyWith(errorMessage: 'resource is null', isError: true));
    }
  }

  /// Search icon pressed and initiating a search
  Future<void> search() async {
    debugPrint('search');
    emit(state.copyWith(isSearch: true, searchList: _getSearchList()));
  }

  /// Toggle the Edit State
  void toggleIsEditState() {
    emit(state.copyWith(isEdit: !state.isEdit));
  }

  /// Difficulty Filter Changed
  void difficultyFilterChanged({required DifficultyState difficultyState}) {
    emit(state.copyWith(difficultyState: difficultyState));
  }

  /// Set the from Skills state
  void setFromSkills() {
    emit(
      state.copyWith(
        isFromTrainingPath: false,
        isFromTrainingPathList: false,
      ),
    );
  }

  ///    Called when a [level] is selected and we
  ///    want to change the [levelState] of the SkillLevel in the
  ///    Rider or Horse's profile
  void levelSelected({required LevelState levelState}) {
    if (state.isForRider) {
      if (state.viewingProfile != null) {
        // process the level change for the viewing profile
        // and add a note to the user's
        debugPrint('Changing ${state.viewingProfile?.name} ${state.skill} '
            'to $levelState');
        final note = BaseListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          name: '${state.usersProfile?.name} changed ${state.skill?.skillName} '
              'level to ${levelState.name} ',
        );
        final newViewingProfile = state.viewingProfile;
        _updateRiderSkillLevel(newViewingProfile, levelState, note);
        final newUsersProfile = state.usersProfile;
        _addNoteToProfile(
          newUsersProfile!,
          BaseListItem(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            date: DateTime.now(),
            message: state.usersProfile?.name,
            parentId: state.usersProfile?.email,
            name: "Changed ${state.viewingProfile?.name}'s "
                " skill '${state.skill?.skillName}' "
                'level to ${levelState.name} ',
          ),
        );
      } else {
        // process the level change for the user's profile
        // add a note to the user's profile
        debugPrint(
            'Changing ${state.usersProfile?.name} ${state.skill?.skillName} '
            'to $levelState');
        final newUsersProfile = state.usersProfile;
        final note = BaseListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          name: 'Changed their ${state.skill?.skillName} level '
              'to ${levelState.name}',
        );
        _updateRiderSkillLevel(newUsersProfile, levelState, note);
      }
    } else {
      // process the level change for the horse's profile
      // add a note to the horse's profile and the user's profile
      debugPrint('Changing ${state.horseProfile?.name} ${state.skill} '
          'to $levelState');
      final newHorseProfile = state.horseProfile;
      final note = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email,
        imageUrl: LogTag.Edit.toString(),
        name: '${state.usersProfile?.name} changed skill'
            " '${state.skill?.skillName}' to ${levelState.name}",
      );
      _updateHorseSkillLevel(newHorseProfile!, levelState, note);
      final newUsersProfile = state.usersProfile;
      _addNoteToProfile(
        newUsersProfile!,
        BaseListItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          date: DateTime.now(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          imageUrl: LogTag.Edit.toString(),
          name: "Changed ${state.horseProfile?.name}'s "
              "skill '${state.skill?.skillName}' to ${levelState.name}",
        ),
      );
    }
  }

  /// Returns the color for the level of the skill based on the [levelState]
  Color levelColor({
    required LevelState levelState,
    required Skill skill,
  }) {
    // Determine whether we are dealing with a rider or a horse profile.
    final currentProfile =
        state.isForRider ? determineCurrentProfile() : state.horseProfile;
    var isVerified = false;

    if (currentProfile != null) {
      final skillLevels = currentProfile is RiderProfile
          ? currentProfile.skillLevels
          : (currentProfile as HorseProfile).skillLevels;

      if (skillLevels != null && skillLevels.isNotEmpty) {
        final skillLevel = skillLevels.firstWhere(
          (element) => element.skillId == skill.id,
          orElse: () => SkillLevel(
            skillId: skill.id,
            skillName: skill.skillName,
            lastEditBy: state.usersProfile?.name,
            lastEditDate: DateTime.now(),
          ),
        );

        if (state.isForRider) {
          if (skillLevel.lastEditBy != null &&
              skillLevel.lastEditBy != state.usersProfile?.name) {
            isVerified = true;
          }
        } else {
          if (skillLevel.lastEditBy != null &&
              skillLevel.lastEditBy != state.horseProfile?.currentOwnerName) {
            isVerified = true;
          }
        }
        if (skillLevel.levelState.index >= levelState.index) {
          return isVerified ? Colors.yellow : Colors.blue;
        }
      }
    } else {
      debugPrint('Profile is not determined');
      return Colors.grey;
    }
    return Colors.grey;
  }

  /// Returns the learningDescription for the current skill or the
  /// proficientDescription for the current skill
  /// depending on the current levelState null if rider is guest
  String getLevelProgressDescription() {
    final skill = state.skill;
    final riderProfile = determineCurrentProfile();
    if (skill != null) {
      if (riderProfile != null) {
        if (riderProfile.skillLevels != null &&
            riderProfile.skillLevels!.isNotEmpty) {
          final skillLevel = riderProfile.skillLevels?.firstWhere(
            (element) => element.skillId == skill.id,
            orElse: () => SkillLevel(
              skillName: skill.skillName,
              skillId: skill.id,
              lastEditBy: state.usersProfile?.name,
              lastEditDate: DateTime.now(),
            ),
          );
          if (skillLevel?.levelState == LevelState.NO_PROGRESS) {
            return skill.learningDescription ??
                'To be considered "Learning"'
                    ' you should be actively working on this skill and '
                    'trying to improve';
          } else if (skillLevel?.levelState == LevelState.LEARNING) {
            return skill.proficientDescription ??
                'To be considered '
                    '"Proficient" you should be able to do ${skill.skillName} '
                    'with out assistance';
          } else if (skillLevel?.levelState == LevelState.PROFICIENT) {
            return 'You should be able to do ${skill.skillName} without'
                ' assistance anymore';
          } else {
            return '';
          }
        } else {
          debugPrint('skillLevels is null');
          return '';
        }
      } else {
        return '';
      }
    } else {
      debugPrint('skill is null');
      return '';
    }
  }

  ///Sort skills by state.isForRider and return the sorted list
  List<Skill?> _sortSkillsByType(List<Skill?> skills) {
    debugPrint('Sorting Skills by ${state.isForRider ? 'Rider' : 'Horse'}');
    final sortedSkills = skills
        .where(
          (element) => element?.rider == state.isForRider,
        )
        .toList();
    return sortedSkills;
  }

  /// Sorts the skills based on the difficulty
  List<Skill?> sortedSkills() {
    debugPrint('Sorting Skills by ${state.difficultyState}');
    final skills = _sortSkillsByType(state.allSkills);
    const difficultyOrder = {
      DifficultyState.introductory: 1,
      DifficultyState.intermediate: 2,
      DifficultyState.advanced: 3,
    };
    switch (state.difficultyState) {
      case DifficultyState.introductory:
        return skills
            .where(
              (element) => element?.difficulty == DifficultyState.introductory,
            )
            .toList()
          ..sort(
            (a, b) => difficultyOrder[a?.difficulty]!
                .compareTo(difficultyOrder[b?.difficulty]!),
          );
      case DifficultyState.intermediate:
        return skills
            .where(
              (element) => element?.difficulty == DifficultyState.intermediate,
            )
            .toList()
          ..sort(
            (a, b) => difficultyOrder[a?.difficulty]!
                .compareTo(difficultyOrder[b?.difficulty]!),
          );
      case DifficultyState.advanced:
        return skills
            .where((element) => element?.difficulty == DifficultyState.advanced)
            .toList()
          ..sort(
            (a, b) => difficultyOrder[a?.difficulty]!
                .compareTo(difficultyOrder[b?.difficulty]!),
          );
      case DifficultyState.all:
        return skills
          ..sort(
            (a, b) => difficultyOrder[a?.difficulty]!
                .compareTo(difficultyOrder[b?.difficulty]!),
          );
    }
  }

  /// Returns the Search List for the SkillTree state
  List<String?> _getSearchList() {
    switch (state.skillTreeNavigation) {
      case SkillTreeNavigation.SkillList:
        return sortedSkills().map((e) => e?.skillName).toList();
      case SkillTreeNavigation.TrainingPathList:
        return state.trainingPaths.map((e) => e?.name).toList();
      case SkillTreeNavigation.SkillLevel:
        return state.resources.map((e) => e?.name).toList();
      case SkillTreeNavigation.TrainingPath:
        return sortedSkills().map((e) => e?.skillName).toList();
    }
  }

  /// Search for Skills query
  void skillSearchQueryChanged({required String searchQuery}) {
    final searchList = sortedSkills()
        .map((e) => e?.skillName)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList));
  }

  /// Search for Resources query
  void resourceSearchQueryChanged({required String searchQuery}) {
    final searchList = state.resources
        .map((e) => e?.name)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList));
  }

  /// Search for Training Paths query
  void trainingPathSearchQueryChanged({required String searchQuery}) {
    final searchList = state.trainingPaths
        .map((e) => e?.name)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList));
  }

  /// Toggle the search state
  void toggleSearch() {
    emit(state.copyWith(isSearch: !state.isSearch));
  }

  /// Children of the [skillNode] sorted by position
  List<SkillNode> childrenNodes({required SkillNode skillNode}) {
    final children = <SkillNode>[];
    for (final child in state.trainingPath!.skillNodes) {
      if (child != null && child.parentId == skillNode.id) children.add(child);
    }
    children.sort((a, b) => a.position.compareTo(b.position));
    return children;
  }

  /* **************************************************************************

******************************* Resources **********************************

***************************************************************************** */
  /// Determines if the resource is new
  bool isNewResource(Resource resource) {
    final now = DateTime.now();
    final difference = now.difference(resource.lastEditDate!);
    return difference.inDays < 10;
  }

// TODO(mfrenchy): add th ability to open the resource locally https://pub.dev/packages/flutter_inappwebview
  ///   Single Resource is Selected and is being viewed
  Future<void> openResource({required String? url}) async {
    final uri = Uri.parse(url!);
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      throw Exception('Could Not Launch: $uri');
    }
  }

  /// Gets the user rating for the [resource] or creates a new one
  BaseListItem? getUserRatingForResource(Resource resource) {
    final newRatingUser = BaseListItem(
      id: state.usersProfile?.email ?? '',
      isCollapsed: false,
      isSelected: false,
    );

    final usersRating = resource.usersWhoRated?.firstWhere(
      (element) => element?.id == state.usersProfile?.email,
      orElse: BaseListItem.new,
    );
    if (resource.usersWhoRated == null) {
      return newRatingUser;
    } else {
      return usersRating;
    }
  }

  void updateResourceSortStatus(ResourcesSortStatus status) {
    switch (status) {
      case ResourcesSortStatus.mostRecommended:
        sortMostRecommended();
        break;
      case ResourcesSortStatus.recent:
        sortByNew();
        break;
      case ResourcesSortStatus.oldest:
        sortByOld();
        break;
      case ResourcesSortStatus.saved:
        sortBySaved();
        break;
    }
  }

  /// Sort the resources by the ones with the highest rating
  void sortMostRecommended() {
    final sortedList = state.resources
      ..sort(
        (a, b) => (b!.rating!).compareTo(a!.rating!),
      );
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.mostRecommended,
      ),
    );
  }

  ///  Sort the resources by the newest last edit date
  void sortByNew() {
    debugPrint('Sorting by New');
    final sortedList = state.resources
      ..sort(
        (a, b) => (b?.lastEditDate as DateTime)
            .compareTo(a!.lastEditDate as DateTime),
      );
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.recent,
      ),
    );
  }

  /// Sort the resources by the ones that have the oldest
  /// last edit date
  void sortByOld() {
    debugPrint('Sorting by Old');
    final sortedList = state.resources
      ..sort(
        (a, b) => (a!.lastEditDate as DateTime)
            .compareTo(b?.lastEditDate as DateTime),
      );
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.oldest,
      ),
    );
  }

  /// Sort the resources by the ones that have been saved
  /// by the user
  void sortBySaved() {
    debugPrint('Sorting by Saved');
    final savedResources = <Resource>[];
    if (state.usersProfile != null) {
      if (state.usersProfile?.savedResourcesList != null) {
        for (final resource in state.resources) {
          if (state.usersProfile!.savedResourcesList!.contains(resource!.id)) {
            savedResources.add(resource);
          }
        }
      }
    }
    emit(
      state.copyWith(
        savedResources: savedResources,
        resourcesSortStatus: ResourcesSortStatus.saved,
      ),
    );
  }

  ///   Save [resource] to the users profile saved resources list
  void saveResource({required Resource resource}) {
    final currentUsersProfile = state.usersProfile;
    if (currentUsersProfile != null) {
      List<String> savedResourcesList;
      if (currentUsersProfile.savedResourcesList != null) {
        savedResourcesList =
            currentUsersProfile.savedResourcesList as List<String>;
      } else {
        savedResourcesList = [];
      }

      if (!savedResourcesList.contains(resource.id)) {
        savedResourcesList.add(resource.id as String);
      } else {
        savedResourcesList.remove(resource.id);
      }
      currentUsersProfile.savedResourcesList = savedResourcesList;

      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: currentUsersProfile,
      );
    } else {
      // Handle the case where the user profile is not available
      debugPrint('User profile is not available');
      emit(
        state.copyWith(
          errorMessage:
              'Unautherized to Edit Resources, Login or Create an account',
          isError: true,
        ),
      );
    }
  }

  /// Determines if user has rated the [resource] positively or not
  bool isRatingPositive(Resource resource) {
    final rating = getUserRatingForResource(resource);
    return rating?.isSelected ?? false;
  }

  ///  User has clicked the recommend [resource] button
  void reccomendResource({required Resource resource}) {
    final editedresource = resource;
    _setNewPositiveRating(resource: editedresource);
    _resourcesRepository.createOrUpdateResource(resource: editedresource);
  }

  ///  User has clicked the dont recommend [resource] button
  void dontReccomendResource({required Resource resource}) {
    final editedresource = resource;
    _setNewNegativeRating(resource: editedresource);
    _resourcesRepository.createOrUpdateResource(resource: editedresource);
  }

  ///   Sets the new Rating on the [resource] based on whether or not they rated
  Resource _setNewPositiveRating({required Resource resource}) {
    final userEmail = state.usersProfile?.email as String;

    ///   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: true,
      isCollapsed: false,
    );

    ///   List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    /// New Ratings
    final newPositiveRating = resource.rating! + 1;
    final newDoublePositveRating = resource.rating! + 2;
    final newNegativeRating = resource.rating! - 1;

    ///   Reference to the user
    final user = resource.usersWhoRated
        ?.firstWhere((element) => element?.id == userEmail);

    /// All Conditions possible
    if (resource.usersWhoRated != null) {
      ///   'List is not NULL
      if (user != null) {
        ///   Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          ///   Never Rated before addding User and +1
          resource.usersWhoRated?.add(newuser);
          resource.rating = newPositiveRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          ///   Already Positive Rating, -1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = false;
          resource.rating = newNegativeRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          ///   User does not have a registered rateing +1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          ///   User already rated NEGATIVE, adding +2
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = false;
          resource.rating = newDoublePositveRating;
          return resource;
        } else {
          ///   Unexpeted Condition  NULL
          return resource;
        }
      } else {
        ///   No UserWhoRated Found, Adding one
        resource.usersWhoRated?.add(newuser);
        resource.rating = newPositiveRating;
        return resource;
      }
    } else {
      ///   UserWhoRated List is null adding and a +1
      resource
        ..usersWhoRated = newUsersWhoRated
        ..rating = newPositiveRating;
      return resource;
    }
  }

  ///   Sets the new Rating on the [resource] based on whether or not they rated
  Resource _setNewNegativeRating({required Resource resource}) {
    final userEmail = state.usersProfile!.email;

    ///   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: false,
      isCollapsed: true,
    );

    ///   List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    ///   New Rating Conditions
    final newPositiveRating = resource.rating! + 1;
    final newNegativeRating = resource.rating! - 1;
    final newDoubleNegativeRating = resource.rating! - 2;

    ///   Reference to the User
    final user = resource.usersWhoRated
        ?.firstWhere((element) => element?.id == userEmail);

    if (resource.usersWhoRated != null) {
      ///  List is not NULL
      if (user != null) {
        ///  Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          ///   Never Rated before addding User and -1
          resource.usersWhoRated?.add(newuser);
          resource.rating = newNegativeRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          ///   Already Negative Rating, +1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          ///   User does not have a registered rating -1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = true;
          resource.rating = newNegativeRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          ///   User already rated POSITIVE, adding -2
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == userEmail)
              ?.isCollapsed = true;
          resource.rating = newDoubleNegativeRating;
          return resource;
        } else {
          ///   Unexpeted Condition  NULL
          return resource;
        }
      } else {
        ///   No UserWhoRated Found, Adding one and -1
        resource.usersWhoRated?.add(newuser);
        resource.rating = newNegativeRating;
        return resource;
      }
    } else {
      ///   UserWhoRated List is null adding and a -1
      resource
        ..usersWhoRated = newUsersWhoRated
        ..rating = newNegativeRating;
      return resource;
    }
  }

  /// Delete a [resource] from the database
  void deleteResource(Resource resource) {
    _resourcesRepository.deleteResource(resource: resource);
  }

/* **************************************************************************

******************************* Messagees **********************************

***************************************************************************** */

  ///monitors the message entered into the message support dialog
  void messageToSupportChanged(String value) {
    emit(
      state.copyWith(
        errorMessage: value,
      ),
    );
  }

  void sendMessageToSupport() {
    emit(
      state.copyWith(messageToSupportStatus: MessageToSupportStatus.sending),
    );
    if (state.errorMessage.isEmpty) {
      emit(state.copyWith(isError: true, errorMessage: 'Message is empty'));
      return;
    } else {
      final emails = <String>[
        state.usersProfile?.email.toLowerCase() as String,
        StringConstants.HORSEANDRIDERCOMPANIONEMAIL.toLowerCase(),
      ]..sort();

      final idbuff = StringBuffer()..write(emails.join('_'));
      final id = convertEmailToPath(idbuff.toString());
      final recipients = <String>[
        state.usersProfile?.email.toLowerCase() as String,
        StringConstants.HORSEANDRIDERCOMPANIONEMAIL.toLowerCase(),
      ];

      final memberNames = <String>[
        state.usersProfile?.name as String,
        StringConstants.HORSEANDRIDERCOMPANIONNAME,
      ];

      final supportMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        sender: state.usersProfile?.name,
        subject: 'Message to Support',
        message: state.errorMessage,
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
        recipients: memberNames,
        senderProfilePicUrl: state.usersProfile?.picUrl,
      );

      final conversation = Conversation(
        id: id,
        parties: memberNames,
        partiesIds: recipients,
        createdBy: state.usersProfile?.name as String,
        createdOn: DateTime.now(),
        lastEditBy: state.usersProfile?.name as String,
        lastEditDate: DateTime.now(),
        recentMessage: supportMessage,
      );
      try {
        _messagesRepository
          ..createOrUpdateConversation(conversation: conversation)
          ..createOrUpdateMessage(
            message: supportMessage,
            conversationId: conversation.id,
          );
        emit(
          state.copyWith(
            messageToSupportStatus: MessageToSupportStatus.success,
            isMessage: true,
            errorMessage: 'Sent Message to the '
                "Horse & Rider's Companion Support Team",
          ),
        );
      } on FirebaseException catch (e) {
        emit(
          state.copyWith(
            messageToSupportStatus: MessageToSupportStatus.initial,
            isError: true,
            errorMessage: e.message,
          ),
        );

        debugPrint("Failed with error '${e.code}': ${e.message}");
      }
    }
  }

  /// Loads the Groups/Conversations for the user
  void getConversations() {
    if (state.conversations == null) {
      emit(state.copyWith(conversationsState: ConversationsState.loading));
      debugPrint('getConversations');
      if (state.usersProfile != null) {
        _conversationsStream = _messagesRepository
            .getConversations(userEmail: state.usersProfile!.email)
            .listen((event) {
          final conversations =
              event.docs.map((e) => (e.data()) as Conversation).toList()
                ..sort(
                  (a, b) => b.createdOn.compareTo(a.createdOn),
                );
          emit(
            state.copyWith(
              conversations: conversations,
              conversationsState: ConversationsState.loaded,
            ),
          );
        });
      } else {
        debugPrint('User Profile is null');
      }
    } else {
      debugPrint('Conversations already retrieved');
    }
  }

  /// User selected a conversation to view
  void setConversation(String conversationsId) {
    debugPrint('setConversation: $conversationsId');
    final conversation = getConversationById(conversationsId);
    if (conversation != null) {
      emit(
        state.copyWith(
          conversationState: ConversationState.loading,
          conversation: conversation,
          messageId: conversationsId,
        ),
      );
      if (conversation.messageState == MessageState.UNREAD) {
        conversation.messageState = MessageState.READ;
        _messagesRepository.createOrUpdateConversation(
          conversation: conversation,
        );
      }
      _messagesStream = _messagesRepository
          .getMessages(conversationId: conversation.id)
          .listen((event) {
        final messages = event.docs.map((e) => (e.data()) as Message).toList()
          ..sort(
            (a, b) => (a.date as DateTime).compareTo(
              b.date as DateTime,
            ),
          );
        debugPrint('Messages Retrieved: ${messages.length}');
        emit(
          state.copyWith(
            messages: messages.reversed.toList(),
            conversationState: ConversationState.loaded,
          ),
        );
      });
    } else {
      debugPrint('Conversation is null');
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error Retrieveing Conversation',
        ),
      );
    }
  }

  /// Returns a conversation by its [id]
  Conversation? getConversationById(String id) {
    if (state.conversations == null || state.conversations!.isEmpty) {
      return null;
    } else {
      final conversation = state.conversations!.firstOrNull;
      return conversation;
    }
  }

  /// AppBar title for a conversation showing the other parties name
  String conversationTitle() {
    final conversation = state.conversation;

    final parties = conversation?.parties?..remove(state.usersProfile?.name);
    return parties?.join(', ') ?? '';
  }

  /// Message text changed
  void messageTextChanged(String value) {
    final text = value;
    emit(state.copyWith(messageText: text));
  }

  /// User Submits a message
  void sendMessage() {
    if (state.messageText.isNotEmpty) {
      final message = Message(
        date: DateTime.now(),
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
        id: state.conversation?.id,
        sender: state.usersProfile?.name,
        senderProfilePicUrl: state.usersProfile?.picUrl,
        recipients: state.conversation?.parties,
        subject: '',
        message: state.messageText,
      );
      if (state.conversation != null) {
        final updatedconversation = state.conversation!
          ..lastEditDate = DateTime.now()
          ..recentMessage = message
          ..lastEditBy = state.usersProfile?.name
          ..messageState = MessageState.UNREAD;
        _messagesRepository
          ..createOrUpdateMessage(
            conversationId: updatedconversation.id,
            message: message,
          )
          ..createOrUpdateConversation(
            conversation: updatedconversation,
          );
      } else {
        debugPrint('Empty Text');
      }
    }
    emit(state.copyWith(messageText: ''));
  }

  /// Sort the Conversations by messageState, creadtedDate, and lastEditDate
  void sortConversations(ConversationsSort value) {
    final sortedConversations = state.conversations;

    switch (value) {
      case ConversationsSort.createdDate:
        sortedConversations?.sort(
          (a, b) => b.createdOn.compareTo(a.createdOn),
        );
        break;
      case ConversationsSort.lastupdatedDate:
        sortedConversations?.sort(
          (a, b) => b.lastEditDate.compareTo(a.lastEditDate),
        );
        break;
      case ConversationsSort.unread:
        sortedConversations?.sort(
          (a, b) => a.messageState.index.compareTo(b.messageState.index),
        );
        break;
      case ConversationsSort.oldest:
        sortedConversations?.sort(
          (a, b) => a.createdOn.compareTo(b.createdOn),
        );
    }
    emit(
      state.copyWith(
        conversationsSort: value,
        conversations: sortedConversations,
      ),
    );
  }

  /// Returns if the [message] is from the current user
  bool isCurrentUser(Message message) {
    return message.sender == state.usersProfile?.name;
  }

//  method that accepts MessageType request and adds
//  to the user's and receiver's appropriate lists
  void acceptRequest({
    required Message message,
    required BuildContext context,
  }) {
    emit(state.copyWith(acceptStatus: AcceptStatus.loading));
    _riderProfileRepository
        .getProfileByName(name: message.sender as String)
        .listen((event) {
      final receiverProfile = event.data() as RiderProfile;
      final receiverItem = BaseListItem(
        id: state.usersProfile?.email,
        name: state.usersProfile?.name,
        imageUrl: state.usersProfile?.picUrl,
        isCollapsed: true,
        isSelected: true,
      );
      final riderItem = BaseListItem(
        id: receiverProfile.email,
        name: receiverProfile.name,
        imageUrl: receiverProfile.picUrl,
        isCollapsed: true,
        isSelected: true,
      );
      switch (message.messageType) {
        case MessageType.INSTRUCTOR_REQUEST:
          final instructorAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${state.usersProfile?.name} as an Instructor',
            date: DateTime.now(),
            parentId: receiverProfile.email,
            message: receiverProfile.name,
          );
          final studentAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${receiverProfile.name} as a Student',
            date: DateTime.now(),
            parentId: state.usersProfile?.email,
            message: state.usersProfile?.name,
          );
          if (receiverProfile.instructors == null ||
              receiverProfile.instructors!.isEmpty) {
            receiverProfile.instructors = [riderItem];
          } else {
            receiverProfile.instructors?.removeWhere(
              (element) => element.id == state.usersProfile?.email,
            );
            receiverProfile.instructors?.add(riderItem);
          }
          receiverProfile.notes?.add(instructorAcceptNote);

          if (state.usersProfile?.students == null ||
              state.usersProfile!.students!.isEmpty) {
            state.usersProfile?.students = [receiverItem];
          } else {
            state.usersProfile?.students
                ?.removeWhere((element) => element.id == receiverProfile.email);
            state.usersProfile?.students?.add(receiverItem);
          }
          state.usersProfile?.notes?.add(studentAcceptNote);
          if (state.conversation != null) {
            try {
              _riderProfileRepository
                ..createOrUpdateRiderProfile(
                  riderProfile: receiverProfile,
                )
                ..createOrUpdateRiderProfile(
                  riderProfile: state.usersProfile!,
                );
              message.requestItem?.isSelected = true;
              _messagesRepository
                  .createOrUpdateMessage(
                message: message,
                conversationId: state.conversation!.id,
              )
                  .then((value) {
                emit(
                  state.copyWith(
                    isMessage: true,
                    errorMessage: 'Added ${receiverProfile.name} as an Student',
                    acceptStatus: AcceptStatus.accepted,
                  ),
                );
              });
            } catch (e) {
              emit(
                state.copyWith(
                  isError: true,
                  errorMessage: 'Error: $e',
                  acceptStatus: AcceptStatus.waiting,
                ),
              );
              debugPrint(e.toString());
            }
          } else {
            emit(
              state.copyWith(
                isError: true,
                errorMessage: 'Error: Conversation is null',
                acceptStatus: AcceptStatus.waiting,
              ),
            );
          }
          break;
        case MessageType.STUDENT_HORSE_REQUEST:
          debugPrint('STUDENT_HORSE_REQUEST');
          HorseProfile studentHorse;
          if (message.requestItem != null) {
            _horseProfileRepository
                .getHorseProfileById(id: message.requestItem!.id ?? '')
                .listen((event) {
              studentHorse = event.data() as HorseProfile;
              debugPrint('studentHorse: $studentHorse');
              final horseNote = BaseListItem(
                id: DateTime.now().toString(),
                name: 'Added ${receiverProfile.name} as a trainer',
                date: DateTime.now(),
                parentId: studentHorse.id,
                message: studentHorse.name,
              );

              final senderAcceptnote = BaseListItem(
                id: DateTime.now().toString(),
                name: 'Added ${studentHorse.name} as a student horse',
                date: DateTime.now(),
                parentId: receiverProfile.email,
                message: receiverProfile.name,
              );
              final receiverAcceptnote = BaseListItem(
                id: DateTime.now().toString(),
                name: 'Added ${receiverProfile.name} as '
                    'a trainer for ${studentHorse.name}',
                date: DateTime.now(),
                parentId: studentHorse.id,
                message: studentHorse.name,
              );

              if (studentHorse.instructors == null ||
                  studentHorse.instructors!.isEmpty) {
                studentHorse.instructors = [receiverItem];
              } else {
                studentHorse.instructors?.removeWhere(
                  (element) => element.id == receiverItem.id,
                );
                studentHorse.instructors?.add(
                  receiverItem,
                );
              }
              studentHorse.notes?.add(horseNote);

              if (receiverProfile.studentHorses == null ||
                  receiverProfile.studentHorses!.isEmpty) {
                receiverProfile.studentHorses = [
                  message.requestItem as BaseListItem,
                ];
              } else {
                receiverProfile.studentHorses?.removeWhere(
                  (element) => element.id == message.requestItem?.id,
                );
                receiverProfile.studentHorses
                    ?.add(message.requestItem as BaseListItem);
              }
              receiverProfile.notes?.add(senderAcceptnote);
              state.usersProfile?.notes?.add(receiverAcceptnote);
              if (state.conversation != null) {
                try {
                  _horseProfileRepository.createOrUpdateHorseProfile(
                    horseProfile: studentHorse,
                  );
                  _riderProfileRepository
                    ..createOrUpdateRiderProfile(
                      riderProfile: state.usersProfile!,
                    )
                    ..createOrUpdateRiderProfile(
                      riderProfile: receiverProfile,
                    );
                  message.messageState = MessageState.READ;
                  _messagesRepository
                      .createOrUpdateMessage(
                    message: message,
                    conversationId: state.conversation!.id,
                  )
                      .then((value) {
                    emit(
                      state.copyWith(
                        isMessage: true,
                        errorMessage: 'Added ${receiverProfile.name} as '
                            'a trainer for ${studentHorse.name}',
                        acceptStatus: AcceptStatus.accepted,
                      ),
                    );
                  });
                } on FirebaseException catch (e) {
                  emit(
                    state.copyWith(
                      isError: true,
                      errorMessage: 'Failed: ${e.message!}',
                      acceptStatus: AcceptStatus.waiting,
                    ),
                  );
                  debugPrint(e.toString());
                }
              } else {
                emit(
                  state.copyWith(
                    isError: true,
                    errorMessage: 'Error: Conversation is null',
                    acceptStatus: AcceptStatus.waiting,
                  ),
                );
              }
            });
          } else {
            debugPrint('message.requestItem is null');
            emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
          }

          break;
        case MessageType.STUDENT_REQUEST:
          final studentAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${state.usersProfile?.name} as a student',
            date: DateTime.now(),
            parentId: receiverProfile.email,
            message: receiverProfile.name,
          );
          final instructorAcceptNote = BaseListItem(
            id: DateTime.now().toString(),
            name: 'Added ${receiverProfile.name} as an instructor',
            date: DateTime.now(),
            parentId: state.usersProfile?.email,
            message: state.usersProfile?.name,
          );

          // TODO(mfrenchy77): check the logic here
          if (receiverProfile.students == null ||
              receiverProfile.students!.isEmpty) {
            receiverProfile.students = [receiverItem];
          } else {
            receiverProfile.students?.removeWhere(
              (element) => element.id == receiverItem.id,
            );
            receiverProfile.students?.add(
              receiverItem,
            );
          }
          receiverProfile.notes?.add(studentAcceptNote);
          if (state.usersProfile?.instructors == null ||
              state.usersProfile!.instructors!.isEmpty) {
            state.usersProfile?.instructors = [riderItem];
          } else {
            state.usersProfile?.instructors?.removeWhere(
              (element) => element.id == riderItem.id,
            );
            state.usersProfile?.instructors?.add(
              riderItem,
            );
          }
          state.usersProfile?.notes?.add(instructorAcceptNote);

          if (state.conversation != null) {
            try {
              _riderProfileRepository
                ..createOrUpdateRiderProfile(riderProfile: state.usersProfile!)
                ..createOrUpdateRiderProfile(riderProfile: receiverProfile);
              message.requestItem?.isSelected = true;
              _messagesRepository
                  .createOrUpdateMessage(
                message: message,
                conversationId: state.conversation!.id,
              )
                  .then((value) {
                emit(
                  state.copyWith(
                    isMessage: true,
                    errorMessage: 'Added ${receiverProfile.name} as an '
                        'instructor for ${state.usersProfile?.name}',
                    acceptStatus: AcceptStatus.accepted,
                  ),
                );
              });
            } on FirebaseException catch (e) {
              emit(
                state.copyWith(
                  isError: true,
                  errorMessage: 'Failed: ${e.message}',
                  acceptStatus: AcceptStatus.waiting,
                ),
              );
              debugPrint(e.toString());
            }
          } else {
            emit(
              state.copyWith(
                isError: true,
                errorMessage: 'Error: Conversation is null',
                acceptStatus: AcceptStatus.waiting,
              ),
            );
          }
          break;

        case MessageType.EDIT_REQUEST:
          // TODO(mfrenchy77): 2021-02-17 This is where whe are going to handle skill tree edit requests to the author of the skill
          debugPrint('EDIT_REQUEST');
          break;
        case MessageType.CHAT:
          debugPrint('CHAT');
          break;
      }
    });
  }

  /// returns the color for the group text based on the messageState
  Color groupTextColor({required Conversation conversation}) {
    final isDark = SharedPrefs().isDarkMode;
    return conversation.messageState == MessageState.UNREAD
        ? isDark
            ? Colors.white
            : Colors.black
        : isDark
            ? Colors.grey.shade400
            : Colors.grey.shade600;
  }

  /// Determines if the message request should be visible
  /// if the sender in not the current user
  /// and if the request is not already accepted
  /// returns true if the request should be visible
  bool isRequestVisible({required Message message}) {
    final isCurrentUser = message.sender == state.usersProfile?.name;
    final isMessageTypeValid =
        message.messageType == MessageType.INSTRUCTOR_REQUEST ||
            message.messageType == MessageType.STUDENT_HORSE_REQUEST ||
            message.messageType == MessageType.STUDENT_REQUEST;

    return !isCurrentUser &&
        isMessageTypeValid &&
        message.requestItem?.id != state.usersProfile?.email;
  }

  ///   method that checks if the request is accepted
  bool isRequestAccepted({required Message message}) {
    debugPrint('messageSender: ${message.sender}');
    if (message.messageType == MessageType.INSTRUCTOR_REQUEST) {
      debugPrint(
        'Instructor/Student List: ${state.usersProfile?.instructors?.map((e) => e.name)}',
      );
      return state.usersProfile?.instructors
              ?.any((element) => element.name == message.sender) ??
          false;
    } else if (message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
      _riderProfileRepository
          .getProfileByName(name: message.sender as String)
          .first
          .then((value) {
        final senderProfile = value.data() as RiderProfile;

        debugPrint(
          'StudentHorses: ${senderProfile.studentHorses?.map((e) => e.name)}',
        );
        debugPrint('message.requestItem?.name: ${message.requestItem?.name}');
        return senderProfile.studentHorses
                ?.any((element) => element.name == message.requestItem?.name) ??
            false;
      });
    }
    return false;
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
            pageStatus: AppPageStatus.resourceList,
          ),
        );
        break;
    }
  }

  /// Set the page status to Loading
  void setLoading() {
    emit(
      state.copyWith(
        pageStatus: AppPageStatus.loading,
      ),
    );
  }

  void navigateToProfile() {
    emit(
      state.copyWith(
        index: 0,
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  void navigateToAuth() {
    emit(
      state.copyWith(
        index: 0,
        pageStatus: AppPageStatus.auth,
      ),
    );
  }

  /// Navigate to the Horse Profile Page
  void navigateToHorseProfile(HorseProfile horseProfile) {
    emit(
      state.copyWith(
        index: 0,
        pageStatus: AppPageStatus.profile,
        horseProfile: horseProfile,
      ),
    );
  }

  void setHorseProfile() {
    emit(
      state.copyWith(
        isForRider: false,
      ),
    );
  }

  /// Resets from Horse Profile to the Rider Profile
  void resetFromHorseProfile() {
    debugPrint('resetFromHorseProfile');
    emit(
      state.copyWith(
        index: 0,
        isViewing: false,
        // ignore: avoid_redundant_argument_values
        horseId: null,
        isForRider: true,
        // ignore: avoid_redundant_argument_values
        horseProfile: null,
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  void setViewingProfile() {
    emit(
      state.copyWith(
        isViewing: true,
      ),
    );
  }

  /// Resets From Viewing Profile to the Users Profile
  void resetFromViewingProfile() {
    debugPrint('resetFromViewingProfile');
    emit(
      state.copyWith(
        index: 0,
        isViewing: false,
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        pageStatus: AppPageStatus.profile,
      ),
    );
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

  /// Navigates to the List of Skills
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

  /// Navigates to a the Skill Level Screen in the Skill Tree

  void navigateToSkillLevel({
    required Skill? skill,
  }) {
    debugPrint('navigateToSkillLevel for ${skill?.skillName}');
    emit(
      state.copyWith(
        index: 1,
        skill: skill,
        isSearch: false,
        isFromProfile: state.index == 0,
        pageStatus: AppPageStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.SkillLevel,
      ),
    );
  }

  /// Navigates to the List of Training Paths
  void navigateToTrainingPathList() {
    debugPrint('navigateToTrainingPathList');
    emit(
      state.copyWith(
        index: 1,
        pageStatus: AppPageStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.TrainingPathList,
        isFromProfile: state.index == 0,
      ),
    );
  }

  /// Navigates to a  Training Path
  void navigateToTrainingPath({
    required TrainingPath? trainingPath,
  }) {
    debugPrint('navigateToTrainingPath for ${trainingPath?.name}');
    emit(
      state.copyWith(
        index: 1,
        pageStatus: AppPageStatus.skillTree,
        trainingPath: trainingPath,
        isFromProfile: state.index == 0,
        skillTreeNavigation: SkillTreeNavigation.TrainingPath,
      ),
    );
  }

  /// Navigates to the Settings Page
  void navigateToSettings() {
    debugPrint('navigateToSettings');
    emit(
      state.copyWith(
        index: 0,
        pageStatus: AppPageStatus.settings,
      ),
    );
  }

  /// Navigates to the Messages Page
  void navigateToMessages() {
    debugPrint('navigateToMessages');
    emit(
      state.copyWith(
        index: 0,
        pageStatus: AppPageStatus.messages,
      ),
    );
  }

  /// Navigates to the Resources Page
  void navigateToResources(Resource resource) {
    debugPrint('navigateToResources');
    emit(
      state.copyWith(
        index: 2,
        resource: resource,
        pageStatus: AppPageStatus.resourceList,
      ),
    );
  }

  void navigateToResourceComments(Resource resource) {
    debugPrint('navigateToResourceComments');
    emit(
      state.copyWith(
        resource: resource,
        pageStatus: AppPageStatus.resource,
      ),
    );
  }

  /// Create Error
  void createError(String message) {
    emit(state.copyWith(isError: true, errorMessage: message));
  }

  /// Clears the Error Message and Snackbar
  void clearErrorMessage() {
    emit(state.copyWith(isMessage: false, errorMessage: ''));
  }

  /// Create a Snackbar Message
  void createMessage(String message) {
    emit(state.copyWith(isMessage: true, errorMessage: message));
  }

  /// Clear the isMessage
  void clearMessage() {
    emit(state.copyWith(isMessage: false, errorMessage: ''));
  }

  @override
  Future<void> close() {
    _messagesStream?.cancel();
    _userSubscription.cancel();
    _resourcesStream?.cancel();
    _skillsSubscription?.cancel();
    _conversationsStream?.cancel();
    _trainingPathsStream?.cancel();
    _horseProfileSubscription?.cancel();
    _usersProfileSubscription?.cancel();
    _viewingProfileSubscription.cancel();
    return super.close();
  }
}
