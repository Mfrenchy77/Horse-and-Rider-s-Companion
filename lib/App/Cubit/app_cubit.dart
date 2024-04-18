// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
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
      _checkFirstLaunch();
      if (user != null && user.id.isNotEmpty) {
        emit(state.copyWith(pageStatus: AppPageStatus.loading));
        debugPrint('User is authenticated');
        _getUsersProfile(user: user);
      } else {
        debugPrint('User is unauthenticated or email not verified');
        emit(state.copyWith(isGuest: true, pageStatus: AppPageStatus.loaded));
      }
    });
  }

  /// Checks if the user is a first time user and launces the About Page
  void _checkFirstLaunch() {
    debugPrint('Checking First Launch');
    final firstTime = SharedPrefs().isFirstLaunch();
    if (firstTime) {
      debugPrint('First Launch: $firstTime');
      emit(state.copyWith(showFirstLaunch: true));
    } else {
      debugPrint('Not First Launch');
    }
  }

  /// Sets the First Launch to false
  Future<void> setFirstLaunch() async {
    debugPrint('Setting First Launch to false');
    SharedPrefs().setFirstLaunch(isFirst: false);
    emit(state.copyWith(showFirstLaunch: false));
  }

  /// Checks if the users has viewed the Onboarding
  void _checkOnboarding() {
    debugPrint('Checking Onboarding');

    emit(state.copyWith(showOnboarding: SharedPrefs().showOnboarding()));
  }

  /// Sets the Onboarding to false
  void setOnboarding() {
    debugPrint('Setting Onboarding to false');
    SharedPrefs().setShowOnboarding(show: false);
    emit(state.copyWith(showOnboarding: false));
  }

  void _getUsersProfile({required User user}) {
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
          showEmailVerification: true,
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
          _checkOnboarding();
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

  /// Method to fetch rider profile from the database
  Future<RiderProfile?> _fetchRiderProfile(String email) async {
    debugPrint('Fetching Rider Profile for $email');
    try {
      final snapshot =
          await _riderProfileRepository.getRiderProfile(email: email).first;
      return snapshot.data() as RiderProfile?;
    } catch (e) {
      debugPrint('Error fetching rider profile: $e');
      return null;
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
      debugPrint('Email is verified: $isVerified');
      emit(
        state.copyWith(showEmailVerification: !isVerified),
      );

      if (isVerified) {
        _emailVerificationTimer?.cancel();
        debugPrint('Email is verified in Timer');
        emit(
          state.copyWith(
            isProfileSetup: true,
            isMessage: true,
            showEmailVerification: false,
            errorMessage: 'Email has been verified',
          ),
        );
      }
    });
  }

  /// Determines if the user is authorized to edit a viewing profile
  /// or a horse profile
  bool isAuthorized() {
    final usersProfile = state.usersProfile;
    final horseProfile = state.horseProfile;
    final viewingProfile = state.viewingProfile;

    // Early exit for guest users to avoid unnecessary checks
    if (state.isGuest) {
      debugPrint('Guest User');
      return false;
    }

    // Check ownership of the profile being viewed
    if (state.isViewing && viewingProfile != null) {
      if (usersProfile != null) {
        // Profile owner check
        if (viewingProfile.email == usersProfile.email) {
          debugPrint('Profile Owner');
          return true;
        }
        // Instructor check for the viewing profile
        if (viewingProfile.instructors
                ?.any((instructor) => instructor.id == usersProfile.email) ??
            false) {
          debugPrint('Viewing Profile Instructor');
          return true;
        }
        // Student check for the viewing profile
        if (viewingProfile.students
                ?.any((student) => student.id == usersProfile.email) ??
            false) {
          debugPrint('Viewing Profile Student');
          return true;
        }
      }
      // If no conditions met for viewingProfile, not authorized
      debugPrint('Not Authorized for Viewing Profile');
      return false;
    }

    // If the state is focused on a horse and the horseProfile exists
    if (!state.isForRider && horseProfile != null && usersProfile != null) {
      // Owner check for horse
      if (usersProfile.ownedHorses
              ?.any((ownedHorse) => ownedHorse.id == horseProfile.id) ??
          false) {
        debugPrint('Horse Owner');
        return true;
      }
      // Instructor check for horse
      if (horseProfile.instructors
              ?.any((instructor) => instructor.id == usersProfile.email) ??
          false) {
        debugPrint('Horse Instructor');
        return true;
      }
    }

    // Default authorization based on user profile availability
    if (usersProfile != null) {
      debugPrint('User Profile Loaded, Default Authorization');
      return true;
    }

    debugPrint('Default Not Authorized');
    return false;
  }

  /// Opens a Rider Profile Page for  [email]
  void getProfileToBeViewed({
    required String email,
  }) {
    emit(
      state.copyWith(
        horseId: '',
        isViewing: true,
        isForRider: true,
        // ignore: avoid_redundant_argument_values
        horseProfile: null,
      ),
    );
    if (state.usersProfile?.email != email) {
      _fetchRiderProfile(email).then((value) {
        if (value != null) {
          final viewingProfile = value;
          debugPrint('Viewing Profile Retrieved: ${viewingProfile.name}');

          emit(
            state.copyWith(
              horseId: '',
              isViewing: true,
              isForRider: true,
              // ignore: avoid_redundant_argument_values
              horseProfile: null,
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
  }

  /// Updates the skill level for the rider
  void _updateRiderSkillLevel(
    RiderProfile? riderProfile,
    LevelState levelState,
    BaseListItem note,
  ) {
    if (riderProfile != null) {
      // if riderProfile.email != state.usersProfile?.email
      // verify the skillLevel

      if (state.skill != null) {
        final timestamp = DateTime.now();
        final skillLevel = riderProfile.skillLevels?.firstWhereOrNull(
              (element) => element.skillId == state.skill?.id,
            ) ??
            SkillLevel(
              lastEditDate: timestamp,
              skillId: state.skill!.id,
              skillName: state.skill!.skillName,
              lastEditBy: state.usersProfile?.name,
              verified: riderProfile.email != state.usersProfile?.email,
            );

        riderProfile.skillLevels?.remove(skillLevel);
        riderProfile.skillLevels?.add(
          SkillLevel(
            levelState: levelState,
            lastEditDate: timestamp,
            skillId: state.skill!.id,
            skillName: state.skill!.skillName,
            lastEditBy: state.usersProfile?.name,
            verified: riderProfile.email != state.usersProfile?.email,
          ),
        );

        _addNoteToProfile(riderProfile, note);
      } else {
        debugPrint('Skill is null');
      }
    } else {
      debugPrint('riderProfile is null');
    }
  }

  /// Adds a note to the rider's profile
  void _addNoteToProfile(RiderProfile riderProfile, BaseListItem note) {
    riderProfile.notes ??= []; // Ensure the notes list is initialized
    riderProfile.notes!.add(note);
    _persistRiderProfileChanges(riderProfile);
  }

  /// Persists the changes to the rider profile to the repository
  Future<void> _persistRiderProfileChanges(
    RiderProfile riderProfile,
  ) async {
    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: riderProfile,
      );
    } catch (error) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: "Failed to update ${riderProfile.name}'s profile  ",
        ),
      );
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
      await _messagesRepository.createOrUpdateMessage(message: message);
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
      await _messagesRepository.createOrUpdateMessage(message: message);
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
      message: user.name,
      date: DateTime.now(),
      id: DateTime.now().toString(),
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

  /// Email changed in the delete account dialog
  void emailChanged(String email) {
    emit(state.copyWith(deleteEmail: Email.dirty(email)));
  }

  /// Deletes the user's account
  Future<void> deleteAccount() async {
    final user = state.usersProfile;
    final email = state.deleteEmail;
    if (user != null && email.isValid && email.value == user.email) {
      try {
        await _riderProfileRepository.deleteRiderProfile(email: user.email);
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
            isMessage: true,
            errorMessage: 'Account Deleted',
          ),
        );
      } catch (e) {
        emit(
          state.copyWith(
            isError: true,
            errorMessage: 'Failed to delete account: $e',
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to delete account',
        ),
      );
    }
  }

/* ***************************************************************************

******************************* Horse Profile**********************************

***************************************************************************** */

  /// Retrieves the Horse Profile from the database if needed
  Future<void> getHorseProfile({required String id}) async {
    debugPrint('getHorseProfile for $id');
    if (state.horseProfile?.id == id) {
      debugPrint('Horse Profile already retrieved');
      // State emission if necessary
    } else {
      debugPrint('Horse Profile not retrieved, getting now');
      _horseProfileSubscription =
          _horseProfileRepository.getHorseProfileById(id: id).listen((event) {
        final horseProfile = event.data() as HorseProfile?;
        if (horseProfile != null) {
          debugPrint('Horse Profile Retrieved: ${horseProfile.name}');

          _checkAndSetOwnerProfile(horseProfile);
          emit(
            state.copyWith(
              horseId: horseProfile.id,
              horseProfile: horseProfile,
            ),
          );
        } else {
          emit(
            state.copyWith(
              pageStatus: AppPageStatus.error,
              errorMessage: 'Failed to retrieve horse profile',
            ),
          );
        }
      });
    }
  }

  /// Fetches the Horse Profile from the database
  Future<HorseProfile?> _fetchHorseProfile(String id) async {
    try {
      final snapshot =
          await _horseProfileRepository.getHorseProfile(id: id).first;
      return snapshot.data() as HorseProfile?;
    } catch (e) {
      debugPrint('Error fetching horse profile: $e');
      return null;
    }
  }

  /// Checks and sets the owner profile
  Future<void> _checkAndSetOwnerProfile(HorseProfile horseProfile) async {
    if (!isOwner() &&
        state.ownersProfile?.email != horseProfile.currentOwnerId) {
      debugPrint('Not Owner, fetching owner profile');
      final ownerProfile =
          await _fetchRiderProfile(horseProfile.currentOwnerId);
      debugPrint('Owner Profile Retrieved: ${ownerProfile?.name}');
      emit(
        state.copyWith(
          ownersProfile: ownerProfile,
        ),
      );
    } else {
      debugPrint('Owner or same owner profile, no need to fetch');
    }
  }

  Future<void> _persistHorseProfileChanges(HorseProfile horseProfile) async {
    debugPrint('Persisting Horse Profile Changes');
    try {
      await _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
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
          verified: state.usersProfile?.email != horseProfile.currentOwnerId,
        );
      } else {
        updatedSkillLevels.add(
          SkillLevel(
            levelState: levelState,
            lastEditDate: timestamp,
            skillId: state.skill!.id,
            skillName: state.skill!.skillName,
            lastEditBy: state.usersProfile?.name,
            verified: state.usersProfile?.email != horseProfile.currentOwnerId,
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
        emit(
          state.copyWith(
            isMessage: true,
            errorMessage: 'Removed ${horseProfile.name} as a student horse',
          ),
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
        ..createOrUpdateMessage(message: message);
      debugPrint('Success');
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
      extra: state.usersProfile?.email,
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
      id: groupId,
      date: DateTime.now(),
      requestItem: requestHorse,
      subject: 'Student Horse Request',
      sender: state.usersProfile!.name,
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

******************************* Skill Tree **********************************

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
            sortedSkills: _sortSkillsByType(skills),
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

  /// Whether or not a user can edit a training path or not.
  ///  Based on whether they have created it or their email
  ///  is in the admin list
  bool canEditTrainingPath(TrainingPath trainingPath) {
    return state.usersProfile?.email == trainingPath.lastEditBy ||
        AuthorizedEmails.emails.contains(state.usersProfile?.email);
  }

  void _getResources() {
    debugPrint('Get Resources Called');
    if (state.resources.isEmpty) {
      debugPrint('Resources not retrieved yet');
      _resourcesStream = _resourcesRepository.getResources().listen((event) {
        final resources =
            event.docs.map((doc) => (doc.data()) as Resource).toList();
        debugPrint('Resources Retrieved: ${resources.length}');
        emit(state.copyWith(resources: resources));
      });
    } else {
      debugPrint('Resources already retrieved');
    }
  }

  /// Whether or not a user can edit a skill or not. Based on whether they
  /// have created it or their email is in the admin list
  bool canEditSkill(Skill skill) {
    return state.usersProfile?.email == skill.lastEditBy ||
        AuthorizedEmails.emails.contains(state.usersProfile?.email);
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

  // /// Difficulty Filter Changed
  // void difficultyFilterChanged({required DifficultyState difficultyState}) {
  //   emit(state.copyWith(difficultyState: difficultyState));
  // }

  /// Skill Tree Sort Changed
  void skillTreeSortChanged(SkillTreeSortState sort) {
    emit(state.copyWith(skillTreeSortState: sort));
    _sortSkills(sort);
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
        debugPrint('Changing and Verifing ${state.viewingProfile?.name}'
            ' ${state.skill} '
            'to $levelState');
        final note = BaseListItem(
          date: DateTime.now(),
          imageUrl: LogTag.Edit.toString(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: '${state.usersProfile?.name} changed ${state.skill?.skillName} '
              'level to ${levelState.name} ',
        );
        final newViewingProfile = state.viewingProfile;
        _updateRiderSkillLevel(newViewingProfile, levelState, note);
        final newUsersProfile = state.usersProfile;
        _addNoteToProfile(
          newUsersProfile!,
          BaseListItem(
            date: DateTime.now(),
            imageUrl: LogTag.Edit.toString(),
            message: state.usersProfile?.name,
            parentId: state.usersProfile?.email,
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: '${state.usersProfile?.name} verified '
                '${state.skill?.skillName} to'
                ' ${levelState.name} for ${state.viewingProfile?.name}',
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
          date: DateTime.now(),
          imageUrl: LogTag.Edit.toString(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
      final horseNote =
          state.usersProfile?.email != newHorseProfile?.currentOwnerId
              ? '${state.usersProfile?.name} verified '
                  '${state.skill?.skillName} to ${levelState.name}'
              : '${state.usersProfile?.name} changed '
                  '${state.skill?.skillName} to ${levelState.name}';
      final note = BaseListItem(
        name: horseNote,
        date: DateTime.now(),
        imageUrl: LogTag.Edit.toString(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      _updateHorseSkillLevel(newHorseProfile!, levelState, note);
      final newUsersProfile = state.usersProfile;
      final userNote =
          state.usersProfile?.email != newHorseProfile.currentOwnerId
              ? '${state.usersProfile?.name} verified '
                  '${state.skill?.skillName} to $levelState '
                  'for ${state.horseProfile?.name}'
              : '${state.usersProfile?.name} changed '
                  '${state.skill?.skillName} to $levelState'
                  ' for ${state.horseProfile?.name}';
      _addNoteToProfile(
        newUsersProfile!,
        BaseListItem(
          name: userNote,
          date: DateTime.now(),
          imageUrl: LogTag.Edit.toString(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
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
        final skillLevel = skillLevels.firstWhereOrNull(
          (element) => element.skillId == skill.id,
        );
        if (skillLevel != null) {
          isVerified = skillLevel.verified;
          if (skillLevel.levelState.index >= levelState.index) {
            return isVerified ? Colors.yellow : Colors.blue;
          }
        } else {
          debugPrint('Skill Level is null');
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

  void sortForHorse() {
    emit(state.copyWith(sortedSkills: _sortSkillsByType(state.allSkills)));
  }

  ///Sorts the Skills based on the SkillTreeSortState
  void _sortSkills(SkillTreeSortState sort) {
    final allSkills = state.allSkills;
    var sortedSkills = <Skill?>[];
    switch (sort) {
      case SkillTreeSortState.All:
        sortedSkills = _sortSkillsByType(allSkills);
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Husbandry:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.category.name == SkillTreeSortState.Husbandry.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Mounted:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.category.name == SkillTreeSortState.Mounted.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.In_Hand:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.category.name == SkillTreeSortState.In_Hand.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Other:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.category.name == SkillTreeSortState.Other.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Advanced:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.difficulty.name == SkillTreeSortState.Advanced.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Intermediate:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  SkillTreeSortState.Intermediate.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
      case SkillTreeSortState.Introductory:
        sortedSkills = allSkills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  SkillTreeSortState.Introductory.name,
            )
            .toList();
        emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
        break;
    }
  }

  /// Returns the Search List for the SkillTree state
  List<String?> _getSearchList() {
    switch (state.skillTreeNavigation) {
      case SkillTreeNavigation.SkillList:
        return state.sortedSkills.map((e) => e?.skillName).toList();
      case SkillTreeNavigation.TrainingPathList:
        return state.trainingPaths.map((e) => e?.name).toList();
      case SkillTreeNavigation.SkillLevel:
        return state.resources.map((e) => e.name).toList();
      case SkillTreeNavigation.TrainingPath:
        return state.sortedSkills.map((e) => e?.skillName).toList();
    }
  }

  /// Search for Skills query
  void skillSearchQueryChanged({required String searchQuery}) {
    final searchList = _sortSkillsByType(state.allSkills)
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
        .map((e) => e.name)
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

  /// Gets the resources Comments
  void getResourceComments(Resource resource) {
    final comments = resource.comments ?? [];
    emit(state.copyWith(resourceComments: comments));
  }

  /// Returns only the base comments
  List<Comment> getBaseComments(Resource resource) {
    return resource.comments
            ?.where((element) => element.parentId == null)
            .toList() ??
        <Comment>[];
  }

  /// returns a list of child comments for a parent comment
  List<Comment> getChildComments({
    required Comment parentComment,
  }) {
    final childComments = List<Comment>.empty(growable: true);
    final commentResource = state.resources.firstWhereOrNull(
      (element) => element.id == parentComment.resourceId,
    );
    for (final comment in commentResource?.comments ?? <Comment>[]) {
      if (comment.parentId == parentComment.id) {
        childComments.add(comment);
      }
    }
    return childComments;
  }

  void sortComments(CommentSortState sortState) {
    emit(state.copyWith(commentSortState: sortState));
    final sortedList = state.resourceComments;
    switch (sortState) {
      case CommentSortState.Recent:
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        emit(state.copyWith(resourceComments: sortedList));
        break;
      case CommentSortState.Oldest:
        sortedList.sort((a, b) => a.date.compareTo(b.date));
        emit(state.copyWith(resourceComments: sortedList));
        break;
      case CommentSortState.Best:
        sortedList.sort((a, b) => b.rating!.compareTo(a.rating!));
        emit(state.copyWith(resourceComments: sortedList));
        break;
      case CommentSortState.Worst:
        sortedList.sort((a, b) => a.rating!.compareTo(b.rating!));
        emit(state.copyWith(resourceComments: sortedList));
        break;
    }
  }

  /// Returns a resource based on the [id]
  Resource? getResourceById(String id) {
    debugPrint('getResourceById for $id');

    if (state.resource?.id == id) {
      debugPrint('Resource is already set: ${state.resource?.name}');
      return state.resource; // Return the already set resource
    }

    final resource =
        state.resources.firstWhereOrNull((element) => element.id == id);

    if (resource != null) {
      debugPrint('Resource found: ${resource.name}');
      getResourceComments(resource);
      emit(
        state.copyWith(
          resource: resource,
        ),
      );
    } else {
      debugPrint('Resource not found');
    }

    return resource;
  }

  /// Gets the user rating for the [resource] or creates a new one
  BaseListItem? getUserRatingForResource(Resource resource) {
    final newRatingUser = BaseListItem(
      id: state.usersProfile?.email ?? '',
      isCollapsed: false,
      isSelected: false,
    );

    final usersRating = resource.usersWhoRated?.firstWhere(
      (element) => element.id == state.usersProfile?.email,
      orElse: BaseListItem.new,
    );
    if (resource.usersWhoRated == null) {
      return newRatingUser;
    } else {
      return usersRating;
    }
  }

  /// Returns a sorted list of resources based on the
  /// [ResourcesSortStatus]
  List<Resource> sortResources(List<Resource?> resources) {
    final sortedList = resources;
    switch (state.resourcesSortStatus) {
      case ResourcesSortStatus.leastRecommended:
        sortedList.sort((a, b) => a!.rating!.compareTo(b!.rating!));
        break;
      case ResourcesSortStatus.mostRecommended:
        sortedList.sort((a, b) => b!.rating!.compareTo(a!.rating!));
        break;
      case ResourcesSortStatus.recent:
        sortedList.sort((a, b) => b!.lastEditDate!.compareTo(a!.lastEditDate!));
        break;
      case ResourcesSortStatus.oldest:
        sortedList.sort((a, b) => a!.lastEditDate!.compareTo(b!.lastEditDate!));
        break;
      case ResourcesSortStatus.saved:
        final savedResources = <Resource>[];
        if (state.usersProfile != null) {
          if (state.usersProfile?.savedResourcesList != null) {
            for (final resource in resources) {
              if (state.usersProfile!.savedResourcesList!
                  .contains(resource!.id)) {
                savedResources.add(resource);
              }
            }
          }
        }
        return savedResources;
    }

    return sortedList as List<Resource>;
  }

  void updateResourceSortStatus(ResourcesSortStatus status) {
    switch (status) {
      case ResourcesSortStatus.leastRecommended:
        _sortByLeastRecommended();
        break;
      case ResourcesSortStatus.mostRecommended:
        _sortMostRecommended();
        break;
      case ResourcesSortStatus.recent:
        _sortByNew();
        break;
      case ResourcesSortStatus.oldest:
        _sortByOld();
        break;
      case ResourcesSortStatus.saved:
        _sortBySaved();
        break;
    }
  }

  /// Sort the resources by the ones with the highest rating
  void _sortMostRecommended() {
    final sortedList = state.resources
      ..sort(
        (a, b) => (b.rating!).compareTo(a.rating!),
      );
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.mostRecommended,
      ),
    );
  }

  /// Sort the resources by the ones with the lowest rating
  void _sortByLeastRecommended() {
    final sortedList = state.resources
      ..sort(
        (a, b) => (a.rating!).compareTo(b.rating!),
      );
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.leastRecommended,
      ),
    );
  }

  ///  Sort the resources by the newest last edit date
  void _sortByNew() {
    debugPrint('Sorting by New');
    final sortedList = state.resources
      ..sort(
        (a, b) =>
            (b.lastEditDate as DateTime).compareTo(a.lastEditDate as DateTime),
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
  void _sortByOld() {
    debugPrint('Sorting by Old');
    final sortedList = state.resources
      ..sort(
        (a, b) =>
            (a.lastEditDate as DateTime).compareTo(b.lastEditDate as DateTime),
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
  void _sortBySaved() {
    debugPrint('Sorting by Saved');
    final savedResources = <Resource>[];
    if (state.usersProfile != null) {
      if (state.usersProfile?.savedResourcesList != null) {
        for (final resource in state.resources) {
          if (state.usersProfile!.savedResourcesList!.contains(resource.id)) {
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
  Future<void> saveResource({required Resource resource}) async {
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

      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: currentUsersProfile,
      );
      // create message notifiying if added or removed
      final message = savedResourcesList.contains(resource.id)
          ? 'Added "${resource.name}" to saved resources'
          : 'Removed "${resource.name}" from saved resources';
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: message,
        ),
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

  /// Determines if user has rated the [resource] negatively or not
  bool isRatingNegative(Resource resource) {
    final rating = getUserRatingForResource(resource);
    return rating?.isCollapsed ?? false;
  }

  ///  User has clicked the recommend [resource] button
  Future<void> reccomendResource({required Resource resource}) async {
    final editedresource = resource;
    _setNewPositiveRating(resource: editedresource);
    await _resourcesRepository.createOrUpdateResource(resource: editedresource);
    final message = isRatingPositive(resource)
        ? 'Added a positive Rating to "${resource.name}"'
        : 'Removed positive Rating from "${resource.name}"';
    emit(
      state.copyWith(
        isMessage: true,
        errorMessage: message,
      ),
    );
  }

  ///  User has clicked the dont recommend [resource] button
  Future<void> dontReccomendResource({required Resource resource}) async {
    final editedresource = resource;
    _setNewNegativeRating(resource: editedresource);
    await _resourcesRepository.createOrUpdateResource(resource: editedresource);
    final message = isRatingNegative(resource)
        ? 'Negatively Rated "${resource.name}"'
        : 'Removed negative Rating from "${resource.name}"';
    emit(
      state.copyWith(
        isMessage: true,
        errorMessage: message,
      ),
    );
  }

  ///   Sets the new Rating on the [resource] based on whether or not they rated
  Resource _setNewPositiveRating({required Resource resource}) {
    final userEmail = state.usersProfile?.email as String;

    //   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: true,
      isCollapsed: false,
    );

    //   List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    // New Ratings
    final newPositiveRating = resource.rating! + 1;
    final newDoublePositveRating = resource.rating! + 2;
    final newNegativeRating = resource.rating! - 1;

    // All Conditions possible
    if (resource.usersWhoRated != null && resource.usersWhoRated!.isNotEmpty) {
      //   Reference to the user
      final user = resource.usersWhoRated?.firstWhereOrNull(
        (element) => element.id == userEmail,
      );
      //   'List is not NULL
      if (user != null) {
        //   Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          //   Never Rated before addding User and +1
          resource.usersWhoRated?.add(newuser);
          resource.rating = newPositiveRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          //   Already Positive Rating, -1
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          resource.rating = newNegativeRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          //   User does not have a registered rateing +1
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          //   User already rated NEGATIVE, adding +2
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          resource.rating = newDoublePositveRating;
          return resource;
        } else {
          //   Unexpeted Condition  NULL
          return resource;
        }
      } else {
        //   No UserWhoRated Found, Adding one
        resource.usersWhoRated?.add(newuser);
        resource.rating = newPositiveRating;
        return resource;
      }
    } else {
      //   UserWhoRated List is null adding and a +1
      resource
        ..usersWhoRated = newUsersWhoRated
        ..rating = newPositiveRating;
      return resource;
    }
  }

  ///   Sets the new Rating on the [resource] based on whether or not they rated
  Resource _setNewNegativeRating({required Resource resource}) {
    final userEmail = state.usersProfile!.email;

    //   List item with user and rated is true
    final newuser = BaseListItem(
      id: userEmail,
      isSelected: false,
      isCollapsed: true,
    );

    //  List with the user and rated value loaded in
    final newUsersWhoRated = [newuser];

    //   New Rating Conditions
    final newPositiveRating = resource.rating! + 1;
    final newNegativeRating = resource.rating! - 1;
    final newDoubleNegativeRating = resource.rating! - 2;

    if (resource.usersWhoRated != null && resource.usersWhoRated!.isNotEmpty) {
      //   Reference to the User
      final user = resource.usersWhoRated?.firstWhereOrNull(
        (element) => element.id == userEmail,
      );

      //  List is not NULL
      if (user != null) {
        ///  Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          //   Never Rated before addding User and -1
          resource.usersWhoRated?.add(newuser);
          resource.rating = newNegativeRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          //   Already Negative Rating, +1
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          //   User does not have a registered rating -1
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = true;
          resource.rating = newNegativeRating;
          return resource;
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          //   User already rated POSITIVE, adding -2
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element.id == userEmail)
              .isCollapsed = true;
          resource.rating = newDoubleNegativeRating;
          return resource;
        } else {
          //   Unexpeted Condition  NULL
          return resource;
        }
      } else {
        //   No UserWhoRated Found, Adding one and -1
        resource.usersWhoRated?.add(newuser);
        resource.rating = newNegativeRating;
        return resource;
      }
    } else {
      //   UserWhoRated List is null adding and a -1
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
        id: id,
        date: DateTime.now(),
        recipients: memberNames,
        subject: 'Support Message',
        message: state.errorMessage,
        messageType: MessageType.SUPPORT,
        sender: state.usersProfile!.name,
        senderProfilePicUrl: state.usersProfile?.picUrl,
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
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
          ..createOrUpdateMessage(message: supportMessage);
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
      debugPrint('Conversation: ${conversation.parties}');
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
    debugPrint('Getting Conversation by Id: $id');
    if (state.conversations == null || state.conversations!.isEmpty) {
      debugPrint('Conversations is null');
      return null;
    } else {
      final conversation = state.conversations!.firstWhereOrNull(
        (element) => element.id == id,
      );
      debugPrint('Got Conversation: ${conversation?.parties}');
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
    if (state.messageText.isNotEmpty && state.conversation != null) {
      final message = Message(
        subject: 'Chat',
        date: DateTime.now(),
        id: state.conversation!.id,
        message: state.messageText,
        sender: state.usersProfile!.name,
        recipients: state.conversation!.parties,
        senderProfilePicUrl: state.usersProfile?.picUrl,
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      if (state.conversation != null) {
        final updatedconversation = state.conversation!
          ..lastEditDate = DateTime.now()
          ..recentMessage = message
          ..lastEditBy = state.usersProfile?.name
          ..messageState = MessageState.UNREAD;
        _messagesRepository
          ..createOrUpdateMessage(message: message)
          ..createOrUpdateConversation(
            conversation: updatedconversation,
          );
      } else {
        debugPrint('Conversation is null');
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

  ///  method that accepts MessageType request and adds
  ///  to the user's and receiver's appropriate lists
  Future<void> acceptRequest({
    required Message message,
    required BuildContext context,
  }) async {
    emit(state.copyWith(acceptStatus: AcceptStatus.loading));
    final String requestorId;
    if (message.requestItem?.id != null) {
      debugPrint('acceptRequest from: ${message.requestItem?.id}'
          ' for ${message.messageType}');
      if (message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
        requestorId = message.requestItem!.extra!;
      } else {
        requestorId = message.requestItem!.id!;
      }

      final requestorProfile = await _fetchRiderProfile(requestorId);
      if (requestorProfile == null) {
        emit(
          state.copyWith(
            isError: true,
            errorMessage: 'Error: Receiver Profile is null',
            acceptStatus: AcceptStatus.waiting,
          ),
        );
        return;
      } else {
        final user = BaseListItem(
          isSelected: true,
          isCollapsed: true,
          id: state.usersProfile?.email,
          name: state.usersProfile?.name,
          imageUrl: state.usersProfile?.picUrl,
        );
        debugPrint('User: ${user.name}');
        final requestor = BaseListItem(
          isSelected: true,
          isCollapsed: true,
          id: requestorProfile.email,
          name: requestorProfile.name,
          imageUrl: requestorProfile.picUrl,
        );
        debugPrint('Requestor: ${requestor.name}');
        switch (message.messageType) {
          case MessageType.INSTRUCTOR_REQUEST:
            await _handleInstructorRequest(
              user: user,
              message: message,
              requestor: requestor,
              requestorProfile: requestorProfile,
            );
            break;
          case MessageType.STUDENT_HORSE_REQUEST:
            debugPrint('STUDENT_HORSE_REQUEST');
            await _handleStudentHorseRequest(
              user: user,
              message: message,
              requestor: requestor,
              requestorProfile: requestorProfile,
            );

            break;
          case MessageType.STUDENT_REQUEST:
            await _handleStudentRequest(
              message: message,
              user: user,
              requestor: requestor,
              requestorProfile: requestorProfile,
            );

          case MessageType.EDIT_REQUEST:
            // TODO(mfrenchy77): 2021-02-17 This is where whe are going to
            // handle skill tree edit requests to the author of the skill
            debugPrint('EDIT_REQUEST');
            break;
          case MessageType.CHAT:
            debugPrint('CHAT');
            break;
          case MessageType.SUPPORT:
            debugPrint('SUPPORT');
            break;
        }
      }
    } else {
      emit(state.copyWith(acceptStatus: AcceptStatus.waiting));
      debugPrint('message.requestItem.id is null');
    }
  }

  /// handles the Instructor Request
  Future<void> _handleInstructorRequest({
    required Message message,
    required BaseListItem user,
    required BaseListItem requestor,
    required RiderProfile requestorProfile,
  }) async {
    final instructorAcceptNote = BaseListItem(
      date: DateTime.now(),
      id: DateTime.now().toString(),
      parentId: requestorProfile.email,
      message: requestorProfile.name,
      imageUrl: LogTag.Edit.toString(),
      name: 'Added ${state.usersProfile?.name} as an Instructor',
    );
    final studentAcceptNote = BaseListItem(
      date: DateTime.now(),
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      message: state.usersProfile?.name,
      parentId: state.usersProfile?.email,
      name: 'Added ${requestorProfile.name} as a Student',
    );
    if (requestorProfile.instructors == null ||
        requestorProfile.instructors!.isEmpty) {
      requestorProfile.instructors = [user];
    } else {
      requestorProfile.instructors?.removeWhere(
        (element) => element.id == state.usersProfile?.email,
      );
      requestorProfile.instructors?.add(user);
    }
    requestorProfile.notes?.add(instructorAcceptNote);

    if (state.usersProfile?.students == null ||
        state.usersProfile!.students!.isEmpty) {
      state.usersProfile?.students = [requestor];
    } else {
      state.usersProfile?.students?.removeWhere(
        (element) => element.id == requestorProfile.email,
      );
      state.usersProfile?.students?.add(requestor);
    }
    state.usersProfile?.notes?.add(studentAcceptNote);
    if (state.conversation != null) {
      try {
        await _persistRiderProfileChanges(requestorProfile);
        await _persistRiderProfileChanges(state.usersProfile!);
        message
          ..requestItem?.isSelected = true
          ..messageType = MessageType.CHAT
          ..message = 'Added ${state.usersProfile?.name} as an Instructor for '
              '${requestorProfile.name}';
        await _persistMessage(message).then((value) {
          emit(
            state.copyWith(
              isMessage: true,
              errorMessage: 'Added ${requestorProfile.name} as a Student',
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
  }

  /// Handle the Student Horse Request
  Future<void> _handleStudentHorseRequest({
    required Message message,
    required BaseListItem user,
    required BaseListItem requestor,
    required RiderProfile requestorProfile,
  }) async {
    final studentHorseId = message.requestItem?.id;
    if (studentHorseId == null) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: Student Horse ID is null',
        ),
      );
      return;
    }

    final studentHorse = await _fetchHorseProfile(studentHorseId);
    if (studentHorse == null) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Error: Student Horse is null',
        ),
      );
      return;
    }

    // Create notes for each related entity
    final horseNote = BaseListItem(
      date: DateTime.now(),
      parentId: studentHorse.id,
      message: studentHorse.name,
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      name: 'Added ${requestorProfile.name} as a trainer',
    );
    final senderAcceptNote = BaseListItem(
      date: DateTime.now(),
      id: DateTime.now().toString(),
      message: requestorProfile.name,
      imageUrl: LogTag.Edit.toString(),
      parentId: requestorProfile.email,
      name: 'Added ${studentHorse.name} as a student horse',
    );
    final receiverAcceptNote = BaseListItem(
      date: DateTime.now(),
      parentId: studentHorse.id,
      message: studentHorse.name,
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      name: 'Added ${requestorProfile.name} as '
          'a trainer for ${studentHorse.name}',
    );

    // Update Horse Profile with new instructor and note
    studentHorse.instructors = (studentHorse.instructors ?? [])
      ..removeWhere((element) => element.id == requestor.id)
      ..add(requestor);
    // ignore: cascade_invocations
    studentHorse.notes = (studentHorse.notes ?? [])..add(horseNote);

    // Update Requestor Profile with new student horse and note
    requestorProfile.studentHorses = (requestorProfile.studentHorses ?? [])
      ..removeWhere((element) => element.id == studentHorseId)
      ..add(message.requestItem as BaseListItem);

    // ignore: cascade_invocations
    requestorProfile.notes = (requestorProfile.notes ?? [])
      ..add(senderAcceptNote);

    // Update User Profile with new note
    state.usersProfile?.notes = (state.usersProfile?.notes ?? [])
      ..add(receiverAcceptNote);

    try {
      await _persistHorseProfileChanges(studentHorse);
      await _persistRiderProfileChanges(requestorProfile);

      if (state.usersProfile != null) {
        await _persistRiderProfileChanges(state.usersProfile!);
      }

      message
        ..requestItem?.isSelected = true
        ..message = 'Added ${requestorProfile.name} as a trainer '
            'for ${studentHorse.name}'
        ..messageType = MessageType.CHAT;
      await _persistMessage(message);

      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Added ${requestorProfile.name} as'
              ' a trainer for ${studentHorse.name}',
          acceptStatus: AcceptStatus.accepted,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed: $e',
          acceptStatus: AcceptStatus.waiting,
        ),
      );
      debugPrint(e.toString());
    }
  }

  /// Handle the Student Request
  Future<void> _handleStudentRequest({
    required Message message,
    required BaseListItem user,
    required BaseListItem requestor,
    required RiderProfile requestorProfile,
  }) async {
    final studentAcceptNote = BaseListItem(
      date: DateTime.now(),
      id: DateTime.now().toString(),
      message: requestorProfile.name,
      parentId: requestorProfile.email,
      imageUrl: LogTag.Edit.toString(),
      name: 'Added ${state.usersProfile?.name} as a student',
    );
    final instructorAcceptNote = BaseListItem(
      date: DateTime.now(),
      id: DateTime.now().toString(),
      imageUrl: LogTag.Edit.toString(),
      message: state.usersProfile?.name,
      parentId: state.usersProfile?.email,
      name: 'Added ${requestorProfile.name} as an instructor',
    );

    if (requestorProfile.students == null ||
        requestorProfile.students!.isEmpty) {
      requestorProfile.students = [user];
    } else {
      requestorProfile.students?.removeWhere(
        (element) => element.id == user.id,
      );
      requestorProfile.students?.add(
        user,
      );
    }
    requestorProfile.notes?.add(studentAcceptNote);

    if (state.usersProfile?.instructors == null ||
        state.usersProfile!.instructors!.isEmpty) {
      state.usersProfile?.instructors = [requestor];
    } else {
      state.usersProfile?.instructors?.removeWhere(
        (element) => element.id == requestor.id,
      );
      state.usersProfile?.instructors?.add(
        requestor,
      );
    }
    state.usersProfile?.notes?.add(instructorAcceptNote);

    if (state.conversation != null) {
      try {
        await _persistRiderProfileChanges(requestorProfile);
        await _persistRiderProfileChanges(state.usersProfile!);
        message
          ..requestItem?.isSelected = true
          ..messageType = MessageType.CHAT
          ..message = 'Added ${requestorProfile.name} as an instructor '
              'for ${state.usersProfile?.name}';
        await _persistMessage(message).then((value) {
          emit(
            state.copyWith(
              isMessage: true,
              errorMessage: 'Added ${requestorProfile.name} as an '
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

  /// Save a messaged to the database
  Future<void> _persistMessage(Message message) async {
    try {
      await _messagesRepository.createOrUpdateMessage(message: message);
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed: ${e.message}',
        ),
      );
      debugPrint(e.toString());
    }
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
  Future<bool> isRequestAccepted({required Message message}) async {
    debugPrint('messageSender: ${message.sender}');
    if (message.messageType == MessageType.INSTRUCTOR_REQUEST) {
      debugPrint(
        'Instructor/Student List: ${state.usersProfile?.instructors?.map((e) => e.name)}',
      );
      return state.usersProfile?.instructors
              ?.any((element) => element.name == message.sender) ??
          false;
    } else if (message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
      final senderProfile =
          await _fetchRiderProfile(message.requestItem!.extra!);

      debugPrint(
        'StudentHorses: ${senderProfile?.studentHorses?.map((e) => e.name)}',
      );
      debugPrint('message.requestItem?.name: ${message.requestItem?.name}');
      return senderProfile?.studentHorses
              ?.any((element) => element.name == message.requestItem?.name) ??
          false;
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
    debugPrint('Changing index from ${state.index} to $index');
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

  void setProfile() {
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
  void setHorseProfile() {
    emit(
      state.copyWith(
        index: 0,
        isViewing: false,
        isForRider: false,
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        pageStatus: AppPageStatus.profile,
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
        viewingProfile: null,
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
        index: 0,
        isForRider: true,
        isViewing: true,
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  /// Resets From Viewing Profile to the Users Profile
  void resetFromViewingProfile() {
    debugPrint('resetFromViewingProfile');
    emit(
      state.copyWith(
        index: 0,
        isForRider: true,
        isViewing: false,
        // ignore: avoid_redundant_argument_values
        viewingProfile: null,
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  /// Set the Resources List
  void setResourcesList() {
    emit(
      state.copyWith(
        index: 2,
        pageStatus: AppPageStatus.resourceList,
      ),
    );
  }

  void setResource() {
    emit(
      state.copyWith(
        index: 2,
        pageStatus: AppPageStatus.resource,
      ),
    );
  }

  /// Set the Skill Tree Page
  void setSkillTree() {
    emit(
      state.copyWith(
        index: 1,
        pageStatus: AppPageStatus.skillTree,
      ),
    );
  }

  ///Reset from the Resource Page to the Resource List
  void resetFromResource() {
    debugPrint('resetFromResource');
    emit(
      state.copyWith(
        index: 2,
        pageStatus: AppPageStatus.resourceList,
        // ignore: avoid_redundant_argument_values
        resourceComments: null,
        // ignore: avoid_redundant_argument_values
        resource: null,
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
        isFromTrainingPathList: true,
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
        pageStatus: AppPageStatus.settings,
      ),
    );
  }

  /// Navigates to the Messages Page
  void navigateToMessages() {
    debugPrint('navigateToMessages');
    emit(
      state.copyWith(
        pageStatus: AppPageStatus.messages,
      ),
    );
  }

  /// Navigates to the Resources Page
  void navigateToResources(Resource resource) {
    debugPrint('navigateToResources');
    emit(
      state.copyWith(
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
