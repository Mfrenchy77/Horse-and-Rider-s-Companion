// ignore_for_file: cast_nullable_to_non_nullable

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:collection/collection.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Connections/connection_failure.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/notifications/fcm_service.dart';
import 'package:horseandriderscompanion/Utilities/notifications/push_notification_service.dart';
import 'package:horseandriderscompanion/Utilities/resource_urls.dart';
import 'package:horseandriderscompanion/Utilities/view_utils.dart';
import 'package:url_launcher/url_launcher.dart';

part 'app_state.dart';

class AppCubit extends Cubit<AppState> {
  AppCubit({
    required this._messagesRepository,
    required this._skillTreeRepository,
    required this._resourcesRepository,
    required this._riderProfileRepository,
    required this._horseProfileRepository,
    required AuthGateway authenticationRepository,
    this._accountDeletionRepository,
    PushNotificationService? pushNotificationService,
    this._submitCoachingAction,
  }) : _authenticationRepository = authenticationRepository,
       _pushNotificationService = pushNotificationService ?? const FcmService(),
       super(
         authenticationRepository.currentUser.isNotEmpty
             ? AppState.authenticated(authenticationRepository.currentUser)
             : const AppState.unauthenticated(),
       ) {
    _beginListeningForUserChanges();
  }

  /// Repositories
  final MessagesStore _messagesRepository;
  final SkillTreeStore _skillTreeRepository;
  final ResourcesStore _resourcesRepository;
  final RiderProfileStore _riderProfileRepository;
  final HorseProfileStore _horseProfileRepository;
  final AuthGateway _authenticationRepository;
  final AccountDeletionRepository? _accountDeletionRepository;
  final PushNotificationService _pushNotificationService;
  final Future<Map<String, dynamic>> Function(Map<String, Object?>)?
  _submitCoachingAction;

  ///Streams
  late final StreamSubscription<User?> _userSubscription;
  StreamSubscription<List<Resource>>? _resourcesStream;
  StreamSubscription<List<Skill>>? _skillsSubscription;
  StreamSubscription<List<Conversation>>? _conversationsStream;
  // Training paths disabled; subscription retained for restoration.
  // StreamSubscription<List<TrainingPath>>? _trainingPathsStream;
  StreamSubscription<RiderProfile?>? _usersProfileSubscription;
  StreamSubscription<HorseProfile?>? _horseProfileSubscription;

  Timer? _emailVerificationTimer;

  User? _lastAuthUser;
  bool _verificationReloadInProgress = false;

  void _beginListeningForUserChanges() {
    _getSkillTreeLists();
    _userSubscription = _authenticationRepository.user.listen(
      (user) => _handleAuthUser(user ?? User.empty),
    );
  }

  void _handleAuthUser(User user) {
    final previous = _lastAuthUser;
    if (user == previous) return;
    _lastAuthUser = user;
    if (previous != null &&
        previous.id == user.id &&
        previous.email == user.email &&
        previous.isGuest == user.isGuest &&
        previous.emailVerified == user.emailVerified) {
      // Name and photo changes do not require a new profile listener.
      emit(state.copyWith(user: user));
      return;
    }

    _emailVerificationTimer?.cancel();
    unawaited(_usersProfileSubscription?.cancel());
    _usersProfileSubscription = null;
    final priorUser = previous ?? state.user;
    if (priorUser.isNotEmpty &&
        (priorUser.id != user.id ||
            priorUser.email != user.email ||
            priorUser.isGuest != user.isGuest ||
            (priorUser.emailVerified && !user.emailVerified))) {
      _clearAccountState();
    }
    _checkFirstLaunch();
    _checkOnboarding();
    if (user.isEmpty) {
      emit(state.copyWith(pageStatus: AppPageStatus.loaded));
      return;
    }
    _getUsersProfile(user: user);
  }

  void _clearAccountState() {
    _emailVerificationTimer?.cancel();
    unawaited(_usersProfileSubscription?.cancel());
    unawaited(_conversationsStream?.cancel());
    unawaited(_horseProfileSubscription?.cancel());
    _usersProfileSubscription = null;
    _conversationsStream = null;
    _horseProfileSubscription = null;
    emit(
      const AppState.unauthenticated().copyWith(
        allSkills: state.allSkills,
        sortedSkills: state.sortedSkills,
        resources: state.resources,
        hasResourceCatalogue: state.hasResourceCatalogue,
        index: state.index,
      ),
    );
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
  void completeOnboarding() {
    debugPrint('Setting Onboarding to false');
    SharedPrefs().setShowOnboarding(show: false);
    emit(state.copyWith(showOnboarding: false));
  }

  /// Forces onboarding presentation immediately depending on auth state.
  void showOnboardingNow() {
    if (state.status == AppStatus.authenticated) {
      emit(state.copyWith(showOnboarding: true));
    } else {
      emit(state.copyWith(showFirstLaunch: true, showOnboarding: true));
    }
  }

  /// Called from onboarding when the user completes the small profile form.
  /// Persists the rider profile and marks profile setup as complete.
  Future<void> completeProfileFromOnboarding(Map<String, String> data) async {
    final name = data['name'] ?? '';
    final email = data['email'] ?? state.user.email;
    final id = (state.user.id.isNotEmpty) ? state.user.id : email;

    final profile = RiderProfile(id: id, name: name, email: email);

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: profile,
      );
      emit(state.copyWith(usersProfile: profile, isProfileSetup: true));
      // Also dismiss onboarding
      completeOnboarding();
    } catch (e) {
      debugPrint('Error saving profile from onboarding: $e');
      emit(
        state.copyWith(isError: true, errorMessage: 'Failed to save profile'),
      );
    }
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
      emit(
        state.copyWith(
          user: user,
          isGuest: false,
          showEmailVerification: false,
          pageStatus: AppPageStatus.loading,
        ),
      );
      var registeredForNotifications = false;
      unawaited(_usersProfileSubscription?.cancel());
      _usersProfileSubscription = _riderProfileRepository
          .getRiderProfile(email: user.email)
          .listen((profile) {
            if (profile != null && !registeredForNotifications) {
              registeredForNotifications = true;
              unawaited(
                _pushNotificationService.ensureRegistered(profile.email),
              );
            }
            emit(
              state.copyWith(
                usersProfile: profile,
                clearUsersProfile: profile == null,
                isProfileSetup: profile != null,
                status: AppStatus.authenticated,
                pageStatus: AppPageStatus.loaded,
              ),
            );
          });
    }
  }

  /// Method to fetch rider profile from the database
  Future<RiderProfile?> _fetchRiderProfile(String email) async {
    debugPrint('Fetching Rider Profile for $email');
    try {
      final profile = await _riderProfileRepository
          .getRiderProfile(email: email)
          .first;
      return profile;
    } catch (e) {
      debugPrint('Error fetching rider profile: $e');
      return null;
    }
  }

  /// Resend the email verification
  Future<void> resendEmailVerification() async {
    await _authenticationRepository.resendEmailVerification();
    emit(
      state.copyWith(isMessage: true, errorMessage: 'Email Verification Sent'),
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
    _emailVerificationTimer = Timer.periodic(const Duration(seconds: 10), (
      _,
    ) async {
      if (_verificationReloadInProgress) return;
      _verificationReloadInProgress = true;
      try {
        // Firebase userChanges delivers the refreshed user to the same
        // handler as sign-in. The timer only asks Firebase to refresh it.
        await _authenticationRepository.reloadCurrentUser();
      } catch (error) {
        debugPrint('Unable to refresh email verification: $error');
      } finally {
        _verificationReloadInProgress = false;
      }
    });
  }

  bool canWriteProfileRecords() {
    final rider = state.usersProfile;
    if (state.isGuest || rider == null) return false;
    if (state.isViewing && state.viewingProfile != null) {
      return state.viewingProfile?.email == rider.email;
    }
    return state.isForRider ||
        state.horseProfile?.currentOwnerId == rider.email;
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
        if (viewingProfile.instructors?.any(
              (instructor) => instructor.id == usersProfile.email,
            ) ??
            false) {
          debugPrint('Viewing Profile Instructor');
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
      if (horseProfile.currentOwnerId.toLowerCase() ==
          usersProfile.email.toLowerCase()) {
        debugPrint('Horse Owner');
        return true;
      }
      // Instructor check for horse
      if (horseProfile.instructors?.any(
            (instructor) => instructor.id == usersProfile.email,
          ) ??
          false) {
        debugPrint('Horse Instructor');
        return true;
      }
    }

    // A loaded rider profile does not authorize edits to an unrelated horse.
    if (!state.isForRider) return false;

    // Default authorization based on user profile availability
    if (usersProfile != null) {
      debugPrint('User Profile Loaded, Default Authorization');
      return true;
    }

    debugPrint('Default Not Authorized');
    return false;
  }

  /// Reloads the viewed rider without changing the current screen or skill.
  Future<void> refreshViewedRider(String email) async {
    final session = state.user;
    RiderProfile? profile;
    try {
      profile = await _riderProfileRepository.getRiderProfileByEmail(
        email: email,
        serverOnly: true,
      );
    } catch (error) {
      debugPrint('Could not refresh viewed rider: $error');
    }
    if (isClosed ||
        state.user != session ||
        !state.isViewing ||
        state.viewingProfile?.email != email) {
      return;
    }
    if (profile == null) {
      createError('Saved, but the student’s progress could not be refreshed.');
      return;
    }
    emit(state.copyWith(viewingProfile: profile));
  }

  /// Opens a Rider Profile Page for  [email]
  void getProfileToBeViewed({required String email}) {
    final isSameViewingProfile = state.viewingProfile?.email == email;
    emit(
      state.copyWith(
        isViewing: true,
        isForRider: true,
        viewingProfielEmail: email,
        clearViewingProfile: !isSameViewingProfile,
      ),
    );
    if (state.usersProfile?.email != email) {
      _fetchRiderProfile(email).then((value) {
        if (isClosed) return;
        if (value != null) {
          final viewingProfile = value;
          debugPrint('Viewing Profile Retrieved: ${viewingProfile.name}');

          emit(
            state.copyWith(
              isViewing: true,
              isForRider: true,
              viewingProfielEmail: email,
              viewingProfile: viewingProfile,
              pageStatus: AppPageStatus.loaded,
            ),
          );
        } else {
          emit(
            state.copyWith(isError: true, errorMessage: 'Profile Not Found'),
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
      resetFromHorseProfile();
    } else if (state.isViewing) {
      resetFromViewingProfile();
    }
  }

  void _updateRiderSkillLevel(
    RiderProfile? riderProfile,
    LevelState levelState,
    BaseListItem note,
  ) {
    if (riderProfile == null) {
      debugPrint('Rider profile is null');
      return;
    }
    if (state.skill == null) {
      debugPrint('Skill is null');
      return;
    }

    final updatedSkillLevels = List<SkillLevel>.of(
      riderProfile.skillLevels ?? const [],
    );
    final existingIndex = updatedSkillLevels.indexWhere(
      (element) => element.skillId == state.skill!.id,
    );
    final updatedSkillLevel = SkillLevel(
      levelState: levelState,
      lastEditDate: DateTime.now(),
      skillId: state.skill!.id,
      skillName: state.skill!.skillName,
      lastEditBy: state.usersProfile?.name,
      verified: riderProfile.email != state.usersProfile?.email,
    );

    if (existingIndex != -1) {
      updatedSkillLevels[existingIndex] = updatedSkillLevel;
      debugPrint('Updated existing skill level');
    } else {
      updatedSkillLevels.add(updatedSkillLevel);
      debugPrint('Added new skill level');
    }

    final updatedProfile = riderProfile.copyWith(
      skillLevels: updatedSkillLevels,
      notes: <BaseListItem>[...?riderProfile.notes, note],
    );
    _persistRiderProfileChanges(updatedProfile);
  }

  /// Adds a note to the rider's profile
  void _addNoteToProfile(RiderProfile riderProfile, BaseListItem note) {
    final updatedProfile = riderProfile.copyWith(
      notes: <BaseListItem>[...?riderProfile.notes, note],
    );
    _persistRiderProfileChanges(updatedProfile);
  }

  /// Persists the changes to the rider profile to the repository
  Future<void> _persistRiderProfileChanges(RiderProfile riderProfile) async {
    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: riderProfile,
      );
      debugPrint('Rider profile changes persisted');
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
    if (state.isViewing && state.viewingProfile != null) {
      return state.viewingProfile!;
    } else if (state.usersProfile != null) {
      return state.usersProfile!;
    } else {
      return null;
    }
  }

  Future<void> logOutRequested() async {
    try {
      await _authenticationRepository.logOut();
      if (isClosed) return;
      _handleAuthUser(User.empty);
      navigateToAuth();
    } on LogOutFailure {
      if (isClosed) return;
      emit(state.copyWith(isError: true, errorMessage: 'Unable to sign out'));
    }
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
      senderId: user.email.toLowerCase(),
      sender: user.name,
      messageId: messageId,
      requestItem: requestItem,
      subject: 'Instructor Request',
      senderProfilePicUrl: user.picUrl,
      messageType: MessageType.INSTRUCTOR_REQUEST,
      recipients: [user.name, instructorProfile.name],
      message:
          '${user.name} has requested '
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
        state.copyWith(isError: true, errorMessage: 'Failed to send request'),
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
      senderId: user.email.toLowerCase(),
      date: DateTime.now(),
      requestItem: requestItem,
      subject: 'Student Request',
      senderProfilePicUrl: user.picUrl,
      messageType: MessageType.STUDENT_REQUEST,
      recipients: [user.name, studentProfile.name],
      message:
          '${user.name} has requested '
          '${studentProfile.name} to be their Student',
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
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
        state.copyWith(isError: true, errorMessage: 'Failed to send request'),
      );
    }
  }

  ///  removes a student from the your student list
  ///  and removes the your from the their instructor list
  ///  and adds a note to both users
  Future<void> removeStudent({required RiderProfile studentProfile}) async {
    final user = state.usersProfile!;

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

    final updatedUser = user.copyWith(
      students: user.students
          ?.where((student) => student.id != studentProfile.email.toLowerCase())
          .toList(),
      notes: <BaseListItem>[...?user.notes, userNote],
    );
    final updatedStudent = studentProfile.copyWith(
      instructors: studentProfile.instructors
          ?.where((instructor) => instructor.id != user.email.toLowerCase())
          .toList(),
      notes: <BaseListItem>[...?studentProfile.notes, studentNote],
    );

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedUser,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedStudent,
      );
      emit(
        state.copyWith(
          usersProfile: updatedUser,
          isMessage: true,
          errorMessage: 'Removed ${studentProfile.name} as a Student',
        ),
      );
    } catch (e) {
      debugPrint('Failed to remove student: $e');
      emit(
        state.copyWith(isError: true, errorMessage: 'Failed to remove student'),
      );
    }
  }

  ///  removes a Viewing Profile from your Instructor list
  ///  and removes you from their student list and adds a note to both users
  Future<void> removeInstructor({
    required RiderProfile instructorProfile,
  }) async {
    final user = state.usersProfile!;

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

    final updatedUser = user.copyWith(
      instructors: user.instructors
          ?.where(
            (instructor) =>
                instructor.id != instructorProfile.email.toLowerCase(),
          )
          .toList(),
      notes: <BaseListItem>[...?user.notes, userNote],
    );
    final updatedInstructor = instructorProfile.copyWith(
      students: instructorProfile.students
          ?.where((student) => student.id != user.email.toLowerCase())
          .toList(),
      notes: <BaseListItem>[...?instructorProfile.notes, instructorNote],
    );

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedUser,
      );
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedInstructor,
      );
      emit(
        state.copyWith(
          usersProfile: updatedUser,
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

  Future<void> addToContact({required RiderProfile riderProfile}) =>
      _saveContact(riderProfile, add: true);

  Future<void> removeFromContacts({required RiderProfile riderProfile}) =>
      _saveContact(riderProfile, add: false);

  Future<void> _saveContact(RiderProfile profile, {required bool add}) async {
    final rider = state.usersProfile;
    if (state.isGuest || rider == null) return;
    try {
      await _riderProfileRepository.saveContact(
        email: rider.email,
        contact: BaseListItem(
          id: profile.email.toLowerCase(),
          name: profile.name,
          imageUrl: profile.picUrl,
          isCollapsed: true,
          isSelected: false,
        ),
        add: add,
      );
      if (isClosed || state.usersProfile?.email != rider.email) return;
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: add
              ? 'Added ${profile.name} to contacts'
              : 'Removed ${profile.name} from contacts',
        ),
      );
    } catch (e) {
      if (isClosed || state.usersProfile?.email != rider.email) return;
      createError('Could not update your contacts. Try again.');
    }
  }

  /// Returns true if the viewingProfile is in the userProfile contacts
  bool isContact() {
    return state.usersProfile?.savedProfilesList?.any(
          (element) => element.id == state.viewingProfile?.email,
        ) ??
        false;
  }

  ///  Returns true if the userProfile is an instructor of the viewingProfile
  bool isInstuctor() {
    return state.viewingProfile?.instructors?.any(
          (element) => element.id == state.usersProfile?.email,
        ) ??
        false;
  }

  /// Email changed in the delete account dialog
  void emailChanged(String email) {
    emit(state.copyWith(deleteEmail: Email.dirty(email)));
  }

  /// Resets transient account deletion status when opening/closing the dialog.
  void resetAccountDeletionStatus() {
    emit(
      state.copyWith(
        deleteEmail: const Email.pure(),
        accountDeletionStatus: AccountDeletionUiStatus.initial,
        accountDeletionError: '',
      ),
    );
  }

  /// Reauthenticates with [password] and retries account deletion.
  Future<void> reauthenticateForDeletionWithPassword(String password) async {
    emit(
      state.copyWith(
        accountDeletionStatus: AccountDeletionUiStatus.inProgress,
        accountDeletionError: '',
      ),
    );
    try {
      await _authenticationRepository.reauthenticateWithPassword(
        password: password,
      );
      await deleteAccount();
    } on ReauthenticationFailure catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.requiresRecentLogin,
          accountDeletionError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.requiresRecentLogin,
          accountDeletionError: 'Reauthentication failed: $e',
        ),
      );
    }
  }

  /// Reauthenticates with Google and retries account deletion.
  Future<void> reauthenticateForDeletionWithGoogle() async {
    emit(
      state.copyWith(
        accountDeletionStatus: AccountDeletionUiStatus.inProgress,
        accountDeletionError: '',
      ),
    );
    try {
      await _authenticationRepository.reauthenticateWithGoogle();
      await deleteAccount();
    } on ReauthenticationFailure catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.requiresRecentLogin,
          accountDeletionError: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.requiresRecentLogin,
          accountDeletionError: 'Reauthentication failed: $e',
        ),
      );
    }
  }

  /// Deletes the user's account via the backend-authorized deletion pipeline.
  Future<void> deleteAccount() async {
    final user = state.usersProfile;
    final authEmail = state.user.email;
    final expectedEmail = user != null ? user.email : authEmail;
    final email = state.deleteEmail;
    final normalizedInput = email.value.trim().toLowerCase();
    final normalizedExpected = expectedEmail.trim().toLowerCase();
    if (expectedEmail.isEmpty ||
        !email.isValid ||
        normalizedInput != normalizedExpected) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.failure,
          accountDeletionError:
              'Confirmation email does not match your signed-in account.',
          isError: true,
          errorMessage: 'Failed to delete account',
        ),
      );
      return;
    }

    final deletionRepo = _accountDeletionRepository;
    if (deletionRepo == null) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.failure,
          accountDeletionError: 'Account deletion service is not configured.',
          isError: true,
          errorMessage: 'Account deletion service is not configured.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        accountDeletionStatus: AccountDeletionUiStatus.inProgress,
        accountDeletionError: '',
      ),
    );

    try {
      final result = await deletionRepo.deleteCurrentAccount();
      if (result.status == AccountDeletionStatus.requiresRecentLogin) {
        emit(
          state.copyWith(
            accountDeletionStatus: AccountDeletionUiStatus.requiresRecentLogin,
            accountDeletionError:
                result.message ??
                'Please reauthenticate before deleting your account.',
          ),
        );
        return;
      }

      unawaited(_usersProfileSubscription?.cancel());
      unawaited(_horseProfileSubscription?.cancel());
      _usersProfileSubscription = null;
      _horseProfileSubscription = null;
      try {
        await _authenticationRepository.logOut();
      } catch (_) {
        // Backend already deleted/revoked the identity; clear local session.
      }
      final uiStatus = result.status == AccountDeletionStatus.scheduled
          ? AccountDeletionUiStatus.scheduled
          : AccountDeletionUiStatus.completed;
      emit(
        state.copyWith(
          status: AppStatus.unauthenticated,
          user: User.empty,
          clearUsersProfile: true,
          clearHorseProfile: true,
          clearViewingProfile: true,
          clearOwnersProfile: true,
          horseId: '',
          viewingProfielEmail: '',
          isViewing: false,
          isForRider: true,
          isProfileSetup: false,
          deleteEmail: const Email.pure(),
          isGuest: true,
          accountDeletionStatus: uiStatus,
          accountDeletionError: '',
          isMessage: true,
          errorMessage: result.message ?? 'Account Deleted',
        ),
      );
    } on AccountDeletionFailure catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.failure,
          accountDeletionError: e.message,
          isError: true,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          accountDeletionStatus: AccountDeletionUiStatus.failure,
          accountDeletionError: 'Failed to delete account: $e',
          isError: true,
          errorMessage: 'Failed to delete account: $e',
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
      // Cancel any existing listener before subscribing to a new horse
      await _horseProfileSubscription?.cancel();
      _horseProfileSubscription = _horseProfileRepository
          .getHorseProfileById(id: id)
          .listen((horseProfile) {
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

  /// Checks and sets the owner profile
  Future<void> _checkAndSetOwnerProfile(HorseProfile horseProfile) async {
    if (!isOwner() &&
        state.ownersProfile?.email != horseProfile.currentOwnerId) {
      debugPrint('Not Owner, fetching owner profile');
      final ownerProfile = await _fetchRiderProfile(
        horseProfile.currentOwnerId,
      );
      debugPrint('Owner Profile Retrieved: ${ownerProfile?.name}');
      emit(state.copyWith(ownersProfile: ownerProfile));
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
      final updatedSkillLevels = List<SkillLevel>.of(
        horseProfile.skillLevels ?? const [],
      );

      // Attempt to find existing skill level index
      final existingIndex = updatedSkillLevels.indexWhere(
        (element) => element.skillId == state.skill?.id,
      );

      final updatedSkillLevel = SkillLevel(
        levelState: levelState,
        lastEditDate: timestamp,
        skillId: state.skill!.id,
        skillName: state.skill!.skillName,
        lastEditBy: state.usersProfile?.name,
        verified: state.usersProfile?.email != horseProfile.currentOwnerId,
      );

      // Replace or add the skill level
      if (existingIndex != -1) {
        updatedSkillLevels[existingIndex] = updatedSkillLevel;
      } else {
        updatedSkillLevels.add(updatedSkillLevel);
      }

      // Update the horse profile with a new list
      final updatedHorseProfile = horseProfile.copyWith(
        skillLevels: updatedSkillLevels,
      );
      debugPrint('Skills: ${updatedHorseProfile.skillLevels?.length}');
      _addNoteToHorseProfile(updatedHorseProfile, note);
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
    return state.horseProfile?.instructors?.any(
          (instructor) => instructor.id == state.usersProfile?.email,
        ) ??
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
    final currentUser = state.usersProfile;
    final updatedHorse = horseProfile.copyWith(
      instructors: horseProfile.instructors
          ?.where((element) => element.id != currentUser?.email)
          .toList(),
    );

    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(
        studentHorses: currentUser.studentHorses
            ?.where((element) => element.id != horseProfile.id)
            .toList(),
      );
      try {
        _horseProfileRepository.createOrUpdateHorseProfile(
          horseProfile: updatedHorse,
        );
        _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: updatedUser,
        );
        emit(
          state.copyWith(
            horseProfile: updatedHorse,
            usersProfile: updatedUser,
            isMessage: true,
            errorMessage: 'Removed ${horseProfile.name} as a student horse',
          ),
        );
      } on RepositoryException catch (e) {
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
      final conversation = _createStudentHorseRequestConnversation(
        requestHorse,
      );
      final message = _createStudentHorseRequestMessage(
        requestHorse,
        conversation.id,
      );

      _messagesRepository
        ..createOrUpdateConversation(conversation: conversation)
        ..createOrUpdateMessage(message: message);
      debugPrint('Success');
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage:
              'Request to add '
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
    final memberNames = [
      state.usersProfile?.name,
      state.ownersProfile?.name,
    ].map((e) => e!).toList();
    final memberIds = [
      state.usersProfile?.email,
      state.ownersProfile?.email,
    ].map((e) => e!.toLowerCase()).toList();

    return Conversation(
      id: id,
      parties: memberNames,
      partiesIds: memberIds,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      createdBy: state.usersProfile!.name,
      lastEditBy: state.usersProfile?.name,
      recentMessage: _createStudentHorseRequestMessage(requestHorse, id),
    );
  }

  Message _createStudentHorseRequestMessage(
    BaseListItem requestHorse,
    String groupId,
  ) {
    return Message(
      id: groupId,
      date: DateTime.now(),
      senderId: state.usersProfile?.email.toLowerCase(),
      requestItem: requestHorse,
      subject: 'Student Horse Request',
      sender: state.usersProfile!.name,
      messageType: MessageType.STUDENT_HORSE_REQUEST,
      senderProfilePicUrl: state.usersProfile?.picUrl,
      message:
          '${state.usersProfile?.name} has requested to add '
          '${state.horseProfile?.name} as a student horse.',
      messageId: DateTime.now().millisecondsSinceEpoch.toString(),
      recipients: [
        state.usersProfile?.name,
        state.ownersProfile?.name,
      ].map((e) => e!).toList(),
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
    final updatedHorseProfile = horseProfile.copyWith(
      notes: <BaseListItem>[...?horseProfile.notes, note],
    );
    _persistHorseProfileChanges(updatedHorseProfile);
  }

  Future<void> setHorseArchive(String archiveStatus) async {
    final horse = state.horseProfile;
    final email = state.usersProfile?.email;
    final submit = _submitCoachingAction;
    if (state.isGuest ||
        horse == null ||
        email == null ||
        horse.currentOwnerId.toLowerCase() != email.toLowerCase()) {
      return;
    }
    if (submit == null) {
      createError('Horse archive is unavailable. Try again.');
      return;
    }
    try {
      await submit({
        'action': 'setHorseArchive',
        'horseId': horse.id,
        'archiveStatus': archiveStatus,
      });
      if (isClosed || state.usersProfile?.email != email) return;
      final message = switch (archiveStatus) {
        'active' => '${horse.name} is back in your active horses.',
        'deceased' => '${horse.name} was archived as deceased.',
        _ => '${horse.name} was archived.',
      };
      emit(state.copyWith(isMessage: true, errorMessage: message));
    } catch (error) {
      if (isClosed || state.usersProfile?.email != email) return;
      createError(
        error is ConnectionFailure
            ? error.message
            : 'Could not update the horse archive. Try again.',
      );
    }
  }

  /// Performs horse-management side effects (sale listing / transfer / trainer
  /// invite) via the coaching connection backend.
  ///
  /// UI should only collect user input (dialogs) then call this single method.
  Future<void> submitHorseManageAction({
    required HorseProfile horse,
    required String action,
    Map<String, Object?>? listing,
    String? recipientEmail,
  }) async {
    final email = state.usersProfile?.email;
    final submit = _submitCoachingAction;
    if (state.isGuest || email == null) return;

    // Must be current owner.
    if (horse.currentOwnerId.toLowerCase() != email.toLowerCase()) return;
    if (submit == null) {
      createError('This action is unavailable. Try again.');
      return;
    }
    if (state.horseManageInProgress) return;

    emit(
      state.copyWith(horseManageInProgress: true, horseManageHorseId: horse.id),
    );

    try {
      final request = switch (action) {
        'listing' => {'action': 'setSaleListing', 'listing': listing},
        'unlist' => {'action': 'setSaleListing', 'listing': null},
        'transfer' => {
          'action': 'sendTransfer',
          'recipientEmail': recipientEmail,
        },
        'invite' => {
          'action': 'send',
          'kind': 'horse',
          'coachEmail': recipientEmail,
        },
        _ => null,
      };

      if (request == null) return;
      if ((action == 'listing') && (listing == null)) return;
      if ((action == 'transfer' || action == 'invite') &&
          (recipientEmail == null || recipientEmail.trim().isEmpty)) {
        return;
      }

      final result = await submit({'horseId': horse.id, ...request});

      if (isClosed || state.usersProfile?.email != email) return;

      final message = switch (action) {
        'listing' => 'Sale listing saved.',
        'unlist' => 'Sale listing removed.',
        'transfer' => 'Transfer request sent.',
        _ when result['incoming'] == true =>
          'Review the existing incoming request.',
        _ when result['status'] == 'accepted' =>
          'This connection is already active.',
        _ => 'Request sent.',
      };

      createMessage(message);
    } on ConnectionFailure catch (error) {
      if (isClosed || state.usersProfile?.email != email) return;
      final message = switch ((action, error.message)) {
        ('listing' || 'unlist', 'Invalid connection ID.') =>
          'Sale listings require an updated Firebase service.',
        ('transfer', 'Invalid connection ID.') =>
          'Ownership transfers are unavailable in '
              'this version of the Firebase service.',
        _ => error.message,
      };
      createError(message);
    } catch (_) {
      if (isClosed || state.usersProfile?.email != email) return;
      createError('The change could not be saved. Try again.');
    } finally {
      if (!isClosed && state.usersProfile?.email == email) {
        emit(
          state.copyWith(
            horseManageInProgress: false,
            clearHorseManageHorseId: true,
          ),
        );
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
    // Skills are shared by the rider profile and Skill Tree.
    // Training paths disabled: do not subscribe to Firestore at startup.
    // _getTrainingPaths();
  }

  void _getSkills() {
    if (_skillsSubscription != null) return;
    debugPrint('Listening for skill catalogue updates');
    _skillsSubscription = _skillTreeRepository.getSkills().listen(
      (skillsList) {
        final next = skillsList.toList()
          ..sort((a, b) => a.position.compareTo(b.position));
        if (_sameSkills(next, state.allSkills)) return;
        emit(state.copyWith(allSkills: next));
        _sortSkills(state.categorySortState, state.difficultySortState);
      },
      onError: (Object error) {
        debugPrint('Failed to listen for skill catalogue: $error');
      },
    );
  }

  // Training-path subscription retained for possible restoration.
  //   void _getTrainingPaths() {
  //     debugPrint('Get TrainingPaths Called');
  //     if (_trainingPathsStream != null) return;
  //     _trainingPathsStream =
  //         _skillTreeRepository.getAllTrainingPaths().listen((trainingPaths) {
  //       debugPrint('Training Paths Retrieved: ${trainingPaths.length}');
  //       final curr = state.trainingPaths;
  //       if (const DeepCollectionEquality().equals(
  //         curr.map((path) => path?.toFirestore()).toList(),
  //         trainingPaths.map((path) => path.toFirestore()).toList(),
  //       )) {
  //         return;
  //       }
  //       emit(state.copyWith(trainingPaths: trainingPaths));
  //     });
  //   }

  /// Whether or not a user can edit a training path or not.
  ///  Based on whether they have created it or their email
  ///  is in the admin list
  bool canEditTrainingPath(TrainingPath trainingPath) {
    return state.usersProfile != null &&
        (state.usersProfile?.email == trainingPath.createdById ||
            AuthorizedEmails.emails.contains(state.usersProfile?.email));
  }

  void loadResourcesIfNeeded() {
    if (_resourcesStream != null) return;
    debugPrint('Listening for resource updates after entering Resources');
    _resourcesStream = _resourcesRepository.getResources().listen(
      (resources) {
        if (state.hasResourceCatalogue &&
            _sameResources(resources, state.resources)) {
          return;
        }
        final selected = resources.firstWhereOrNull(
          (resource) => resource.id == state.resource?.id,
        );
        emit(
          state.copyWith(
            resources: resources,
            hasResourceCatalogue: true,
            resource: selected,
            resourceComments: selected == null
                ? state.resourceComments
                : List<Comment>.of(selected.comments ?? const []),
          ),
        );
      },
      onError: (Object error) {
        _resourcesStream = null;
        emit(state.copyWith(hasResourceCatalogue: false));
        debugPrint('Failed to listen for resource updates: $error');
      },
      cancelOnError: true,
    );
  }

  /// get the selected Skill id
  String? getSelectedSkillId() {
    return state.skill?.id;
  }

  /// get the selected Training Path id
  String? getSelectedTrainingPathId() {
    return state.trainingPath?.id;
  }

  /// Whether or not a user can edit a skill or not. Based on whether they
  /// have created it or their email is in the admin list
  bool canEditSkill(Skill? skill) {
    return state.usersProfile != null &&
        (state.usersProfile?.email == skill?.lastEditBy ||
            AuthorizedEmails.emails.contains(state.usersProfile?.email));
  }

  /// Wheter or not a user can edit a resource or not. Based on whether they
  /// have created it or their email is in the admin list
  bool canEditResource(Resource resource) {
    return state.usersProfile != null &&
        (state.usersProfile?.email == resource.authorId ||
            state.usersProfile?.email == resource.lastEditBy ||
            AuthorizedEmails.emails.contains(state.usersProfile?.email));
  }

  /// Returns the full Skill object from the id
  Skill? _getSkillFromId(String id) {
    final skill = state.allSkills.firstWhereOrNull(
      (element) => element?.id == id,
    );
    return skill;
  }

  /// Return a Skill item from the id
  Skill? getSkillFromId(String id) {
    final skill = _getSkillFromId(id);
    if (skill == null) {
      debugPrint('Skill not found for id: $id');
    } else {}
    return skill;
  }

  bool skillExists(String id) {
    return state.allSkills.any((skill) => skill?.id == id);
  }

  /// set the selected Skill from the id
  void setSkill(String? id) {
    if (id == null || id.isEmpty) {
      debugPrint('Skill id is null or empty');
      emit(state.copyWith(clearSkill: true));
      return;
    }
    final skill = _getSkillFromId(id);
    if (skill != null) {
      debugPrint('Setting Skill: ${skill.skillName}');
      emit(state.copyWith(skill: skill));
    } else {
      debugPrint('Skill not found for id: $id');
      emit(state.copyWith(clearSkill: true));
    }
  }

  /// Returns the full Training Path object from the id
  TrainingPath? getTrainingPathFromId(String id) {
    final trainingPath = state.trainingPaths.firstWhereOrNull(
      (element) => element?.id == id,
    );
    return trainingPath;
  }

  /// Set the selected Training Path from the id
  void setTrainingPath(String? id) {
    if (id == null || id.isEmpty) {
      debugPrint('Training Path id is null or empty');
      return;
    }
    final trainingPath = getTrainingPathFromId(id);
    if (trainingPath != null) {
      debugPrint('Setting Training Path: ${trainingPath.name}');
      emit(state.copyWith(trainingPath: trainingPath));
    } else {
      debugPrint('Training Path not found for id: $id');
    }
  }

  Skill? getSkillFromSkillName(String skillName) {
    debugPrint('Getting Skill: $skillName');
    final skill = state.allSkills.firstWhereOrNull(
      (element) => element?.skillName == skillName,
    );
    if (skill == null) {
      debugPrint(
        'Skill not found, Skill list length: ${state.allSkills.length}',
      );
    } else {
      debugPrint('Skill Found: ${skill.skillName}');
    }
    return skill;
  }

  /// Adds a Resource to the selected Skill
  void addResourceToSkill({
    required Resource? resource,
    required Skill? skill,
  }) {
    if (resource != null) {
      debugPrint('Resource Selected: ${resource.name}');

      if (skill != null) {
        debugPrint('Skill Selected: ${skill.skillName}');
        final skillTreeIds = List<String>.of(resource.skillTreeIds);

        // Toggle the presence of skill.id in skillTreeIds
        if (skillTreeIds.contains(skill.id)) {
          skillTreeIds.remove(skill.id);
        } else {
          skillTreeIds.add(skill.id);
        }

        final updatedResource = resource.copyWith(skillTreeIds: skillTreeIds);

        try {
          _resourcesRepository.createOrUpdateResource(
            resource: updatedResource,
          );
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

  /// Category Filter Changed
  void categorySortChanged(CategorySortState categorySortState) {
    debugPrint('Category Filter Changedto : $categorySortState.name');
    emit(state.copyWith(categorySortState: categorySortState));
    _sortSkills(categorySortState, state.difficultySortState);
  }

  /// Difficulty Filter Changed
  void difficultySortChanged(DifficultySortState difficultySortState) {
    debugPrint('Difficulty Filter Changed to: $difficultySortState.name');
    emit(state.copyWith(difficultySortState: difficultySortState));
    _sortSkills(state.categorySortState, difficultySortState);
  }

  /// Set the from Skills state
  void setFromSkills() {
    emit(
      state.copyWith(isFromTrainingPath: false, isFromTrainingPathList: false),
    );
  }

  ///    Called when a [level] is selected and we
  ///    want to change the [levelState] of the SkillLevel in the
  ///    Rider or Horse's profile
  void levelSelected({required LevelState levelState}) {
    if (state.isForRider) {
      if (state.viewingProfile != null && state.isViewing) {
        // process the level change for the viewing profile
        // and add a note to the user's
        debugPrint(
          'Changing and Verifing ${state.viewingProfile?.name}'
          ' ${state.skill} '
          'to $levelState',
        );
        final note = BaseListItem(
          date: DateTime.now(),
          imageUrl: LogTag.Edit.toString(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name:
              '${state.usersProfile?.name} changed ${state.skill?.skillName} '
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
            name:
                '${state.usersProfile?.name} verified '
                '${state.skill?.skillName} to'
                ' ${levelState.name} for ${state.viewingProfile?.name}',
          ),
        );
      } else {
        // process the level change for the user's profile
        // add a note to the user's profile
        debugPrint(
          'Changing ${state.usersProfile?.name} ${state.skill?.skillName} '
          'to $levelState',
        );
        final newUsersProfile = state.usersProfile;
        final note = BaseListItem(
          date: DateTime.now(),
          imageUrl: LogTag.Edit.toString(),
          message: state.usersProfile?.name,
          parentId: state.usersProfile?.email,
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name:
              'Changed their ${state.skill?.skillName} level '
              'to ${levelState.name}',
        );
        _updateRiderSkillLevel(newUsersProfile, levelState, note);
      }
    } else {
      // process the level change for the horse's profile
      // add a note to the horse's profile and the user's profile
      debugPrint(
        'Changing ${state.horseProfile?.name} ${state.skill} '
        'to $levelState',
      );
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

  ///Returns the difficuty of a skill from it's name
  DifficultyState getDifficulty(String id) {
    final skill = getSkillFromId(id);
    return skill?.difficulty ?? DifficultyState.All;
  }

  /// returns the category of a skill from it's name
  SkillCategory getSkillCategory(String id) {
    final skill = getSkillFromId(id);
    return skill?.category ?? SkillCategory.Other;
  }

  /// Check if a skill from [skillId] has unmet prerequisites
  bool hasUnmetPrerequisites(String skillId) {
    // Prerequisites disabled: skill progress is independent of other skills.
    return false;

    // Original prerequisite check retained for possible restoration.
    //     final skill = getSkillFromId(skillId);
    //     if (skill == null) return false;
    //
    //     // Check if the skill has prerequisites
    //     if (skill.prerequisites.isEmpty) return false;
    //
    //     // Get the current profile's skill levels
    //     final currentProfile = state.isForRider
    //         ? determineCurrentProfile()
    //         : state.horseProfile;
    //     final skillLevels = currentProfile is RiderProfile
    //         ? currentProfile.skillLevels
    //         : (currentProfile as HorseProfile?)?.skillLevels;
    //
    //     // Check if all prerequisites are met
    //     return skill.prerequisites.any((prerequisiteId) {
    //       final prerequisiteLevel = skillLevels?.firstWhereOrNull(
    //         (level) => level.skillId == prerequisiteId,
    //       );
    //       return prerequisiteLevel == null ||
    //           prerequisiteLevel.levelState != LevelState.PROFICIENT;
    //     });
  }

  /// Returns the color for the level of the skill based on the [levelState]
  Color levelColor({required Skill skill, required LevelState levelState}) {
    final currentProfile = state.isForRider
        ? determineCurrentProfile()
        : state.horseProfile;

    final skillLevels = currentProfile is RiderProfile
        ? currentProfile.skillLevels
        : (currentProfile as HorseProfile?)?.skillLevels;

    final level = skillLevels?.firstWhereOrNull((e) => e.skillId == skill.id);

    if (level == null) return Colors.transparent;

    final isVerified = level.verified;

    return level.levelState.index >= levelState.index
        ? (isVerified ? Colors.yellow : Colors.blue)
        : Colors.transparent;
  }

  Gradient? levelGradient({required Skill skill}) {
    final currentProfile = state.isForRider
        ? determineCurrentProfile()
        : state.horseProfile;

    final skillLevels = currentProfile is RiderProfile
        ? currentProfile.skillLevels
        : (currentProfile as HorseProfile?)?.skillLevels;

    final level = skillLevels?.firstWhereOrNull((e) => e.skillId == skill.id);

    if (level == null || level.levelState != LevelState.LEARNING) {
      return null;
    }

    final fillColor = level.verified ? Colors.yellow : Colors.blue;

    return LinearGradient(
      stops: const [0.48, 0.52],
      colors: [fillColor, Colors.transparent],
    );
  }

  Gradient? horizontalGradient({required Skill skill}) {
    final currentProfile = state.isForRider
        ? determineCurrentProfile()
        : state.horseProfile;

    final skillLevels = currentProfile is RiderProfile
        ? currentProfile.skillLevels
        : (currentProfile as HorseProfile?)?.skillLevels;

    final level = skillLevels?.firstWhereOrNull((e) => e.skillId == skill.id);

    if (level == null || level.levelState != LevelState.LEARNING) {
      return null;
    }

    final fillColor = level.verified ? Colors.yellow : Colors.blue;

    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const [0.48, 0.52],
      colors: [fillColor, Colors.transparent],
    );
  }

  Future<void> removeDeprecatedSkillLevels({
    required RiderProfile profile,
    required List<SkillLevel> deprecatedLevels,
  }) async {
    if (deprecatedLevels.isEmpty) return;

    final idsToRemove = deprecatedLevels.map((level) => level.skillId).toSet();
    final updatedSkillLevels = (profile.skillLevels ?? [])
        .where((level) => !idsToRemove.contains(level.skillId))
        .toList();

    final updatedProfile = profile.copyWith(skillLevels: updatedSkillLevels);

    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedProfile,
      );

      var nextState = state;
      if (profile.email == state.usersProfile?.email) {
        nextState = nextState.copyWith(usersProfile: updatedProfile);
      }
      if (profile.email == state.viewingProfile?.email) {
        nextState = nextState.copyWith(viewingProfile: updatedProfile);
      }

      final removalCount = idsToRemove.length;
      nextState = nextState.copyWith(
        isMessage: true,
        errorMessage:
            '$removalCount deprecated skill${removalCount == 1 ? '' : 's'} '
            'deleted',
      );

      emit(nextState);
    } catch (error) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to delete deprecated skills',
        ),
      );
    }
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
    debugPrint(
      'Sorting ${skills.length} Skills by'
      ' ${state.isForRider ? 'Rider' : 'Horse'}',
    );
    final sortedSkills = skills
        .where((element) => element?.rider == state.isForRider)
        .toList();
    debugPrint('Returning ${sortedSkills.length} skills');
    return sortedSkills;
  }

  void sortForHorse() {
    emit(state.copyWith(sortedSkills: _sortSkillsByType(state.allSkills)));
  }

  /// Changed the Difficulty sort

  ///Sorts the Skills based on the SkillTreeSortState
  void _sortSkills(
    CategorySortState categorySort,
    DifficultySortState difficultySort,
  ) {
    // Do NOT mutate state's list in-place. Work on a copy.
    var sortedSkills = List<Skill?>.from(state.allSkills)
      ..sort((a, b) => a!.skillName.compareTo(b!.skillName));

    // First, sort by category
    sortedSkills = _sortSkillsByCategory(categorySort, sortedSkills);

    // Then, sort by difficulty within the filtered category
    sortedSkills = _sortSkillsByDifficulty(difficultySort, sortedSkills);

    // Emit the sorted skills
    debugPrint('Emitting ${sortedSkills.length} Sorted Skills');
    emit(state.copyWith(sortedSkills: _sortSkillsByType(sortedSkills)));
  }

  // --------- List equality guards (by id + version-ish fields) ---------
  bool _sameSkills(List<Skill> a, List<Skill?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final ai = a[i];
      final bi = b[i];
      if (bi == null) return false;
      if (ai.id != bi.id) return false;
      if (ai.position != bi.position) return false;
      // If both have lastEditDate, compare; otherwise ignore.
      final ad = ai.lastEditDate?.millisecondsSinceEpoch;
      final bd = bi.lastEditDate?.millisecondsSinceEpoch;
      if (ad != null || bd != null) {
        if (ad != bd) return false;
      }
    }
    return true;
  }

  bool _sameResources(List<Resource> a, List<Resource> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_sameResourceValue(a[i].toFirestore(), b[i].toFirestore())) {
        return false;
      }
    }
    return true;
  }

  bool _sameResourceValue(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (!_sameResourceValue(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.entries.every(
            (entry) =>
                b.containsKey(entry.key) &&
                _sameResourceValue(entry.value, b[entry.key]),
          );
    }
    return a == b;
  }

  List<Skill?> _sortSkillsByCategory(
    CategorySortState categorySort,
    List<Skill?> skills,
  ) {
    switch (categorySort) {
      case CategorySortState.All:
        return skills;
      case CategorySortState.Husbandry:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategorySortState.Husbandry.name,
            )
            .toList();
      case CategorySortState.Mounted:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategorySortState.Mounted.name,
            )
            .toList();
      case CategorySortState.In_Hand:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategorySortState.In_Hand.name,
            )
            .toList();
      case CategorySortState.Other:
        return skills
            .where(
              (element) =>
                  element?.category.name == CategorySortState.Other.name,
            )
            .toList();
    }
  }

  List<Skill?> _sortSkillsByDifficulty(
    DifficultySortState difficultySort,
    List<Skill?> skills,
  ) {
    switch (difficultySort) {
      case DifficultySortState.All:
        return skills;
      case DifficultySortState.Introductory:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  DifficultySortState.Introductory.name,
            )
            .toList();
      case DifficultySortState.Intermediate:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name ==
                  DifficultySortState.Intermediate.name,
            )
            .toList();
      case DifficultySortState.Advanced:
        return skills
            .where(
              (element) =>
                  element?.difficulty.name == DifficultySortState.Advanced.name,
            )
            .toList();
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

  // ---------- helpers ----------
  String _norm(String s) => s.trim().toLowerCase();

  List<Skill> _sortSkillsByName(List<Skill> list) {
    final out =
        list
            .whereType<Skill>()
            .toList() // drop nulls defensively
          ..sort((a, b) => _norm(a.skillName).compareTo(_norm(b.skillName)));
    return out;
  }

  // Optional: quick reset you can call after loading skills, etc.
  void resetSkillSearchToAll() {
    final all = state.allSkills.whereType<Skill>().toList();
    final sortedAll = _sortSkillsByName(all);
    emit(
      state.copyWith(
        sortedSkills: sortedAll,
        searchList: sortedAll.map((s) => s.skillName).toList(),
      ),
    );
  }

  // ---------- SKILLS ----------
  void skillSearchQueryChanged({required String searchQuery}) {
    final q = _norm(searchQuery);
    final all = state.allSkills.whereType<Skill>().toList();

    if (q.isEmpty) {
      final sortedAll = _sortSkillsByName(all);
      emit(
        state.copyWith(
          sortedSkills: sortedAll,
          searchList: sortedAll.map((s) => s.skillName).toList(),
        ),
      );
      return;
    }

    final filtered = all.where((s) => _norm(s.skillName).contains(q)).toList();
    final sortedFiltered = _sortSkillsByName(filtered);

    emit(
      state.copyWith(
        sortedSkills: sortedFiltered,
        searchList: sortedFiltered.map((s) => s.skillName).toList(),
      ),
    );
  }

  // ---------- RESOURCES ----------
  void resourceSearchQueryChanged({required String searchQuery}) {
    final q = _norm(searchQuery);
    final names = state.resources.map((r) => r.name).whereType<String>();

    final searchList = q.isEmpty
        ? names
              .toList() // FULL list when empty
        : names.where((n) => _norm(n).contains(q)).toList();

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
    if (!state.isSearch &&
        state.skillTreeNavigation == SkillTreeNavigation.SkillLevel) {
      loadResourcesIfNeeded();
    }
    emit(state.copyWith(isSearch: !state.isSearch));
  }

  /// Children of the [skillNode] sorted by position
  List<SkillNode> childrenNodes({required SkillNode skillNode}) {
    final children = <SkillNode>[];
    for (final child in state.trainingPath!.skillNodes) {
      if (child != null && child.parentId == skillNode.id) {
        // Check if the child node has a corresponding skill
        final skill = getSkillFromId(child.skillId);
        if (skill != null) {
          children.add(child);
        }
      }
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

  ///   Open Resource in External Browser
  Future<void> openResource({required String? url}) async {
    final uri = youtubeWatchUri(url) ?? resourceWebUri(url);
    if (uri == null) {
      createError('No valid resource link');
      return;
    }
    try {
      if (await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      )) {
        return;
      }
    } catch (error) {
      debugPrint('Unable to open resource: $error');
    }
    if (!isClosed) createError('Unable to open resource link');
  }

  /// Gets the resources Comments
  void getResourceComments(Resource resource) {
    final comments = List<Comment>.of(resource.comments ?? const []);
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
  List<Comment> getChildComments({required Comment parentComment}) {
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
    final sortedList = List<Comment>.of(state.resourceComments);
    switch (sortState) {
      case CommentSortState.Recent:
        sortedList.sort((a, b) => b.date.compareTo(a.date));
        break;
      case CommentSortState.Oldest:
        sortedList.sort((a, b) => a.date.compareTo(b.date));
        break;
      case CommentSortState.Best:
        sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case CommentSortState.Worst:
        sortedList.sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
        break;
    }
    emit(
      state.copyWith(
        commentSortState: sortState,
        resourceComments: sortedList,
      ),
    );
  }

  /// Returns a resource based on the [id]
  Resource? getResourceById(String id) {
    debugPrint('getResourceById for $id');

    if (state.resource?.id == id) {
      debugPrint('Resource is already set: ${state.resource?.name}');
      return state.resource; // Return the already set resource
    }

    final resource = state.resources.firstWhereOrNull(
      (element) => element.id == id,
    );

    if (resource != null) {
      debugPrint('Resource found: ${resource.name}');
      selectResource(resource);
    } else {
      debugPrint('Resource not found');
    }

    return resource;
  }

  void selectResource(Resource resource) {
    emit(
      state.copyWith(
        resource: resource,
        resourceComments: List<Comment>.of(resource.comments ?? const []),
      ),
    );
  }

  Future<Resource?> fetchResource(String id) =>
      _resourcesRepository.getResourceById(id);

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
    final sortedList = resources.whereType<Resource>().toList();
    switch (state.resourcesSortStatus) {
      case ResourcesSortStatus.leastRecommended:
        sortedList.sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
        break;
      case ResourcesSortStatus.mostRecommended:
        sortedList.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case ResourcesSortStatus.recent:
        sortedList.sort((a, b) => _resourceDate(b).compareTo(_resourceDate(a)));
        break;
      case ResourcesSortStatus.oldest:
        sortedList.sort((a, b) => _resourceDate(a).compareTo(_resourceDate(b)));
        break;
      case ResourcesSortStatus.saved:
        final savedResources = <Resource>[];
        if (state.usersProfile != null) {
          if (state.usersProfile?.savedResourcesList != null) {
            for (final resource in sortedList) {
              if (state.usersProfile!.savedResourcesList!.contains(
                resource.id,
              )) {
                savedResources.add(resource);
              }
            }
          }
        }
        return savedResources;
    }

    return sortedList;
  }

  DateTime _resourceDate(Resource resource) =>
      resource.lastEditDate ?? resource.createdAt ?? DateTime(1970);

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
    final sortedList = List<Resource>.of(state.resources)
      ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
    emit(
      state.copyWith(
        resources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.mostRecommended,
      ),
    );
  }

  /// Sort the resources by the ones with the lowest rating
  void _sortByLeastRecommended() {
    final sortedList = List<Resource>.of(state.resources)
      ..sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
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
    final sortedList = List<Resource>.of(state.resources)
      ..sort((a, b) => _resourceDate(b).compareTo(_resourceDate(a)));
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
    final sortedList = List<Resource>.of(state.resources)
      ..sort((a, b) => _resourceDate(a).compareTo(_resourceDate(b)));
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
        savedResourcesList = List<String>.from(
          currentUsersProfile.savedResourcesList!,
        );
      } else {
        savedResourcesList = [];
      }

      if (!savedResourcesList.contains(resource.id)) {
        savedResourcesList.add(resource.id as String);
      } else {
        savedResourcesList.remove(resource.id);
      }
      final updatedProfile = currentUsersProfile.copyWith(
        savedResourcesList: savedResourcesList,
      );

      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: updatedProfile,
      );
      // create message notifiying if added or removed
      final message = savedResourcesList.contains(resource.id)
          ? 'Added "${resource.name}" to saved resources'
          : 'Removed "${resource.name}" from saved resources';
      emit(
        state.copyWith(
          usersProfile: updatedProfile,
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
    final editedresource = _setNewPositiveRating(resource: resource);
    await _resourcesRepository.createOrUpdateResource(resource: editedresource);
    final message = isRatingPositive(editedresource)
        ? 'Added a positive Rating to "${resource.name}"'
        : 'Removed positive Rating from "${resource.name}"';
    emit(state.copyWith(isMessage: true, errorMessage: message));
  }

  ///  User has clicked the dont recommend [resource] button
  Future<void> dontReccomendResource({required Resource resource}) async {
    final editedresource = _setNewNegativeRating(resource: resource);
    await _resourcesRepository.createOrUpdateResource(resource: editedresource);
    final message = isRatingNegative(editedresource)
        ? 'Negatively Rated "${resource.name}"'
        : 'Removed negative Rating from "${resource.name}"';
    emit(state.copyWith(isMessage: true, errorMessage: message));
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

    final baseRating = resource.rating ?? 0;
    final newPositiveRating = baseRating + 1;
    final newDoublePositveRating = baseRating + 2;
    final newNegativeRating = baseRating - 1;

    final existingUsers = List<BaseListItem>.of(
      resource.usersWhoRated ?? const [],
    );
    if (existingUsers.isNotEmpty) {
      final index = existingUsers.indexWhere(
        (element) => element.id == userEmail,
      );
      if (index != -1) {
        final user = existingUsers[index];
        if (user.isSelected == null && user.isCollapsed == null) {
          existingUsers.add(newuser);
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newPositiveRating,
          );
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: false,
            isCollapsed: false,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newNegativeRating,
          );
        } else if (user.isSelected == false && user.isCollapsed == false) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: true,
            isCollapsed: false,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newPositiveRating,
          );
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: true,
            isCollapsed: false,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newDoublePositveRating,
          );
        } else {
          return resource;
        }
      } else {
        existingUsers.add(newuser);
        return resource.copyWith(
          usersWhoRated: existingUsers,
          rating: newPositiveRating,
        );
      }
    } else {
      return resource.copyWith(
        usersWhoRated: <BaseListItem>[newuser],
        rating: newPositiveRating,
      );
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

    final baseRating = resource.rating ?? 0;
    final newPositiveRating = baseRating + 1;
    final newNegativeRating = baseRating - 1;
    final newDoubleNegativeRating = baseRating - 2;

    final existingUsers = List<BaseListItem>.of(
      resource.usersWhoRated ?? const [],
    );
    if (existingUsers.isNotEmpty) {
      final index = existingUsers.indexWhere(
        (element) => element.id == userEmail,
      );
      if (index != -1) {
        final user = existingUsers[index];
        if (user.isSelected == null && user.isCollapsed == null) {
          existingUsers.add(newuser);
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newNegativeRating,
          );
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == false && user.isCollapsed == true) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: false,
            isCollapsed: false,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newPositiveRating,
          );
        } else if (user.isSelected == false && user.isCollapsed == false) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: false,
            isCollapsed: true,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newNegativeRating,
          );
          // ignore: use_if_null_to_convert_nulls_to_bools
        } else if (user.isSelected == true && user.isCollapsed == false) {
          existingUsers[index] = BaseListItem(
            id: userEmail,
            isSelected: false,
            isCollapsed: true,
          );
          return resource.copyWith(
            usersWhoRated: existingUsers,
            rating: newDoubleNegativeRating,
          );
        } else {
          return resource;
        }
      } else {
        existingUsers.add(newuser);
        return resource.copyWith(
          usersWhoRated: existingUsers,
          rating: newNegativeRating,
        );
      }
    } else {
      return resource.copyWith(
        usersWhoRated: <BaseListItem>[newuser],
        rating: newNegativeRating,
      );
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
    emit(state.copyWith(errorMessage: value));
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
        senderId: state.usersProfile?.email.toLowerCase(),
        sender: state.usersProfile!.name,
        senderProfilePicUrl: state.usersProfile?.picUrl,
        messageId: DateTime.now().millisecondsSinceEpoch.toString(),
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
            errorMessage:
                'Sent Message to the '
                "Horse & Rider's Companion Support Team",
          ),
        );
      } on RepositoryException catch (e) {
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
    if (state.conversations == null && _conversationsStream == null) {
      emit(state.copyWith(conversationsState: ConversationsState.loading));
      debugPrint('getConversations');
      if (state.usersProfile != null) {
        _conversationsStream = _messagesRepository
            .getConversations(userEmail: state.usersProfile!.email)
            .listen((conversationsList) {
              final conversations = conversationsList.toList()
                ..sort((a, b) => b.createdOn.compareTo(a.createdOn));
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

  /// Reissues a legacy message as a connection requiring fresh consent.
  Future<void> acceptRequest({required Message message}) async {
    if (message.messageType == MessageType.TRANSFER_HORSE_REQUEST) {
      _handleTransferHorseRequest();
      return;
    }
    final email = state.usersProfile?.email;
    final sender =
        message.senderId ??
        (message.messageType == MessageType.STUDENT_HORSE_REQUEST
            ? message.requestItem?.extra
            : message.requestItem?.id);
    final submit = _submitCoachingAction;
    if (state.isGuest ||
        email == null ||
        sender == null ||
        submit == null ||
        sender.toLowerCase() == email.toLowerCase() ||
        state.acceptStatus == AcceptStatus.loading) {
      return;
    }

    final request = switch (message.messageType) {
      MessageType.INSTRUCTOR_REQUEST => {
        'kind': 'rider',
        'learnerEmail': sender,
        'coachEmail': email,
      },
      MessageType.STUDENT_REQUEST => {
        'kind': 'rider',
        'learnerEmail': email,
        'coachEmail': sender,
      },
      MessageType.STUDENT_HORSE_REQUEST => {
        'kind': 'horse',
        'learnerEmail': email,
        'coachEmail': sender,
        'horseId': message.requestItem?.id,
      },
      _ => null,
    };
    if (request == null) return;
    emit(state.copyWith(acceptStatus: AcceptStatus.loading));
    try {
      final result = await submit({'action': 'send', ...request});
      if (isClosed || state.usersProfile?.email != email) return;
      emit(
        state.copyWith(
          acceptStatus: AcceptStatus.submitted,
          isMessage: true,
          errorMessage: switch (result['status']) {
            'accepted' => 'This connection is already active.',
            _ when result['incoming'] == true =>
              'Open Connections and requests to respond.',
            _ => 'Connection request sent. The other rider needs to accept it.',
          },
        ),
      );
    } catch (_) {
      if (isClosed || state.usersProfile?.email != email) return;
      emit(
        state.copyWith(
          acceptStatus: AcceptStatus.waiting,
          isError: true,
          errorMessage: 'Could not send the connection request. Try again.',
        ),
      );
    }
  }

  /// Deny/Decline a pending request message and convert it to a chat entry
  Future<void> denyRequest({required Message message}) async {
    // No repository side-effects beyond updating the message to a normal chat
    try {
      String denialText;
      switch (message.messageType) {
        case MessageType.INSTRUCTOR_REQUEST:
          denialText = 'Denied instructor request from ${message.sender}';
          break;
        case MessageType.STUDENT_REQUEST:
          denialText = 'Denied student request from ${message.sender}';
          break;
        case MessageType.STUDENT_HORSE_REQUEST:
          final horseName = message.requestItem?.name ?? 'horse';
          denialText =
              'Denied student horse request for '
              '$horseName from ${message.sender}';
          break;
        case MessageType.TRANSFER_HORSE_REQUEST:
          denialText = 'Denied horse transfer request';
          break;
        case MessageType.EDIT_REQUEST:
        case MessageType.CHAT:
        case MessageType.SUPPORT:
          denialText = 'Request dismissed';
          break;
      }

      message
        ..message = denialText
        ..messageType = MessageType.CHAT;

      await _persistMessage(message);
      emit(
        state.copyWith(
          isMessage: true,
          errorMessage: 'Request denied',
          acceptStatus: AcceptStatus.waiting,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isError: true,
          errorMessage: 'Failed to deny request: $e',
        ),
      );
    }
  }

  /// Handle transfer horse request
  void _handleTransferHorseRequest() {
    emit(
      state.copyWith(
        acceptStatus: AcceptStatus.waiting,
        isError: true,
        errorMessage: 'Accepting horse transfers is not implemented yet.',
      ),
    );
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

  /// Returns true if the message is a pending request for the current user
  bool _isPendingRequestForUser(Message? m) {
    if (m == null) return false;
    final isFromCurrentUser = m.sender == state.usersProfile?.name;
    final isRequestType =
        m.messageType == MessageType.INSTRUCTOR_REQUEST ||
        m.messageType == MessageType.STUDENT_HORSE_REQUEST ||
        m.messageType == MessageType.STUDENT_REQUEST ||
        m.messageType == MessageType.TRANSFER_HORSE_REQUEST;
    final notAccepted = !(m.requestItem?.isSelected ?? false);
    return !isFromCurrentUser && isRequestType && notAccepted;
  }

  /// Pending request conversations derived from recentMessage only
  List<Conversation> pendingRequestConversations() {
    final cons = state.conversations ?? const <Conversation>[];
    return cons
        .where((c) => _isPendingRequestForUser(c.recentMessage))
        .toList();
  }

  /// Count of pending requests (recent-only heuristic)
  int pendingRequestCount() => pendingRequestConversations().length;

  /// Save a messaged to the database
  Future<void> _persistMessage(Message message) async {
    try {
      await _messagesRepository.createOrUpdateMessage(message: message);
    } on RepositoryException catch (e) {
      emit(state.copyWith(isError: true, errorMessage: 'Failed: ${e.message}'));
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
      return state.usersProfile?.instructors?.any(
            (element) => element.name == message.sender,
          ) ??
          false;
    } else if (message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
      final senderProfile = await _fetchRiderProfile(
        message.requestItem!.extra!,
      );

      debugPrint(
        'StudentHorses: ${senderProfile?.studentHorses?.map((e) => e.name)}',
      );
      debugPrint('message.requestItem?.name: ${message.requestItem?.name}');
      return senderProfile?.studentHorses?.any(
            (element) => element.name == message.requestItem?.name,
          ) ??
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
        emit(state.copyWith(index: index, pageStatus: AppPageStatus.profile));
        break;
      case 1:
        emit(state.copyWith(index: index, pageStatus: AppPageStatus.skillTree));
        break;
      case 2:
        loadResourcesIfNeeded();
        emit(
          state.copyWith(index: index, pageStatus: AppPageStatus.resourceList),
        );
        break;
    }
  }

  /// Skill Tree Tab Navigation
  void setSkillTreeTabIndex(int index) {
    debugPrint('Navigating to Skill Tree Tab Index: $index');
    emit(state.copyWith(skillTreeTabIndex: index));
  }

  /// Set the page status to Loading
  void setLoading() {
    emit(state.copyWith(pageStatus: AppPageStatus.loading));
  }

  void setProfile() {
    emit(state.copyWith(index: 0, pageStatus: AppPageStatus.profile));
  }

  void navigateToAuth() {
    emit(state.copyWith(index: 0, pageStatus: AppPageStatus.auth));
  }

  /// Navigate to the Horse Profile Page
  void setHorseProfile() {
    emit(
      state.copyWith(
        index: 0,
        isViewing: false,
        isForRider: false,
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  /// Resets from Horse Profile to the Rider Profile
  void resetFromHorseProfile() {
    debugPrint('resetFromHorseProfile');
    unawaited(_horseProfileSubscription?.cancel());
    _horseProfileSubscription = null;
    emit(
      state.copyWith(
        index: 0,
        horseId: '',
        isForRider: true,
        isViewing: state.viewingProfile != null,
        clearHorseProfile: true,
        clearOwnersProfile: true,
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
        isForRider: state.horseProfile == null,
        isViewing: false,
        clearViewingProfile: true,
        viewingProfielEmail: '',
        pageStatus: AppPageStatus.profile,
      ),
    );
  }

  /// Set the Resources List
  void setResourcesList() {
    loadResourcesIfNeeded();
    emit(state.copyWith(index: 2, pageStatus: AppPageStatus.resourceList));
  }

  void setResource() {
    loadResourcesIfNeeded();
    emit(state.copyWith(index: 2, pageStatus: AppPageStatus.resource));
  }

  /// Set the Skill Tree Page
  void setSkillTree() {
    emit(state.copyWith(index: 1, pageStatus: AppPageStatus.skillTree));
  }

  ///Reset from the Resource Page to the Resource List
  void resetFromResource() {
    debugPrint('resetFromResource');
    emit(
      state.copyWith(
        index: 2,
        pageStatus: AppPageStatus.resourceList,
        resourceComments: const [],
        clearResource: true,
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

  void navigateToSkillLevel({required Skill? skill}) {
    debugPrint('navigateToSkillLevel for ${skill?.skillName}');
    emit(
      state.copyWith(
        skill: skill,
        clearSkill: skill == null,
        isSearch: false,
        isFromProfile: state.index == 0,
        pageStatus: AppPageStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.SkillLevel,
      ),
    );
  }

  /// Set the flag of from Training Path for when the user clicks a skill
  /// from the Training Path View so when they click back we know to return
  /// to the Training Path View
  void setIsFromTrainingPath({required bool isFromTrainingPath}) {
    debugPrint('setIsFromTrainingPath: $isFromTrainingPath');
    emit(state.copyWith(isFromTrainingPath: isFromTrainingPath));
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
  void navigateToTrainingPath({required TrainingPath? trainingPath}) {
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
    emit(state.copyWith(pageStatus: AppPageStatus.settings));
  }

  /// Navigates to the Resources Page
  void navigateToResources(Resource resource) {
    debugPrint('navigateToResources');
    loadResourcesIfNeeded();
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
      state.copyWith(resource: resource, pageStatus: AppPageStatus.resource),
    );
  }

  /// Create Error
  void createError(String message) {
    debugPrint('Creating Error Message: $message');
    emit(state.copyWith(isError: true, errorMessage: message));
  }

  /// Clears the Error Message and Snackbar
  void clearErrorMessage() {
    debugPrint('Clearing Error Message');
    emit(state.copyWith(isMessage: false, errorMessage: '', isError: false));
  }

  /// Create a Snackbar Message
  void createMessage(String message) {
    debugPrint('Creating Message: $message');
    emit(state.copyWith(isMessage: true, errorMessage: message));
  }

  /// Clear the isMessage
  void clearMessage() {
    emit(state.copyWith(isMessage: false, errorMessage: ''));
  }

  @override
  Future<void> close() {
    _emailVerificationTimer?.cancel();
    _userSubscription.cancel();
    _conversationsStream?.cancel();
    _resourcesStream?.cancel();
    _skillsSubscription?.cancel();
    // _trainingPathsStream?.cancel(); // Training paths disabled.
    _horseProfileSubscription?.cancel();
    _usersProfileSubscription?.cancel();
    return super.close();
  }
}
