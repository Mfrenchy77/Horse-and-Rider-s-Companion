// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'dart:async';

import 'package:authentication_repository/authentication_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:formz/formz.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/Home/Home/RidersLog/riders_log_view.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Home/Resources/View/CreateResourceDialog/View/create_resource_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/add_horse_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/edit_rider_profile_dialog.dart';
import 'package:horseandriderscompanion/HorseProfile/view/horse_home_page.dart';
import 'package:horseandriderscompanion/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/utils/ad_helper.dart';
import 'package:horseandriderscompanion/utils/constants.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';
import 'package:url_launcher/url_launcher.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    this.bannerAd,
    required User user,
    required this.viewingProfile,
    required MessagesRepository messagesRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
    required ResourcesRepository resourcesRepository,
    required SkillTreeRepository skillTreeRepository,
  })  : _skillTreeRepository = skillTreeRepository,
        _messagesRepository = messagesRepository,
        _horseProfileRepository = horseProfileRepository,
        _resourcesRepository = resourcesRepository,
        _riderProfileRepository = riderProfileRepository,
        _user = user,
        super(const HomeState()) {
    ///   Create a  Stream to listen to changes in RiderProfile
    _riderProfileSubscription = _riderProfileRepository
        .getRiderProfile(email: _user.email)
        .listen((event) {
      _usersProfile = event.data() as RiderProfile?;
      if (state.homeStatus == HomeStatus.profile) {
        emit(state.copyWith(usersProfile: _usersProfile));
        if (_usersProfile == null) {
          debugPrint(
            '!!!   !!!   Creating Rider Profile for ${_user.name}   !!!!   !!!',
          );
          createRiderProfile(user: user);
        }
      }
    });

    ///   Stream of Resources
    _resourcesStream = _resourcesRepository.getResources().listen((event) {
      _resources = event.docs.map((doc) => (doc.data()) as Resource?).toList();
      if (state.homeStatus == HomeStatus.resource) {
        emit(
          state.copyWith(resources: _resources, usersProfile: _usersProfile),
        );
      }
    });

    ///   Stream of Categoies
    _categoryStream =
        _skillTreeRepository.getCatagoriesForRiderSkillTree().listen((event) {
      _categories =
          event.docs.map((doc) => (doc.data()) as Catagorry?).toList();
      debugPrint(
        'getting Categories for Rider Skill Tree ${_categories?.length}',
      );

      if (state.homeStatus == HomeStatus.skillTree) {
        emit(state.copyWith(categories: _categories));
      }
    });

    ///   Stream of SubCategories
    _subCategoryStream = _skillTreeRepository
        .getSubCategoriesForRiderSkillTree()
        .listen((event) {
      _subCategories =
          event.docs.map((e) => (e.data()) as SubCategory?).toList();
    });

    ///   Stream of Skills
    _skillsStream =
        _skillTreeRepository.getSkillsForRiderSkillTree().listen((event) {
      _skills = event.docs.map((doc) => (doc.data()) as Skill?).toList();
      debugPrint('getting Skills ${_skills?.length}');
      if (state.homeStatus == HomeStatus.skillTree) {
        emit(state.copyWith(skills: _skills));
      }
    });

    ///   Stream of Levels
    _levelsStream =
        _skillTreeRepository.getLevelsForRiderSkillTree().listen((event) {
      _levels = event.docs.map((doc) => (doc.data()) as Level?).toList();
    });

    debugPrint('getting Levels ${_levels?.length}');

    if (state.homeStatus == HomeStatus.skillTree) {
      emit(state.copyWith(levels: _levels));
    }
    if (viewingProfile != null) {
      emit(state.copyWith(viewingProfile: viewingProfile, isViewing: true));
    }

    ///   Stream of Groups to get unread messages
    ///   Groups Stream
    _groupsStream = _messagesRepository
        .getGroups(
      userEmail: state.usersProfile?.email ?? _user.email as String,
    )
        .listen((event) {
      _groups = event.docs.map((e) => (e.data()) as Group?).toList();
      int unreadMessages;
      for (final group in _groups!) {
        unreadMessages = 0;
        for (final group in _groups!) {
          if (group?.messageState == MessageState.UNREAD) {
            if (group?.recentMessage?.sender != _user.email) {
              unreadMessages++;
            }
          }
        }
        unreadMessages = unreadMessages;
        emit(state.copyWith(unreadMessages: unreadMessages));
      }
    });

    ///     Load Ad
    _loadBannerAds();

    riderProfileNavigationSelected();
  }

  ///   Rider Profile
  final User _user;
  RiderProfile? _usersProfile;
  RiderProfile? viewingProfile;
  final RiderProfileRepository _riderProfileRepository;
  late final StreamSubscription<DocumentSnapshot<Object?>>
      _riderProfileSubscription;

  /// HorseProfile
  final HorseProfileRepository _horseProfileRepository;

  ///   Resources
  List<Resource?>? _resources;
  final ResourcesRepository _resourcesRepository;
  late final StreamSubscription<QuerySnapshot<Object?>> _resourcesStream;

  ///   Skill Tree Repository
  final SkillTreeRepository _skillTreeRepository;

  ///   Categories
  late final StreamSubscription<QuerySnapshot<Object?>> _categoryStream;
  List<Catagorry?>? _categories;

  late final StreamSubscription<QuerySnapshot<Object?>> _subCategoryStream;
  List<SubCategory?>? _subCategories;

  ///   Skills
  late final StreamSubscription<QuerySnapshot<Object?>> _skillsStream;
  List<Skill?>? _skills;

  ///   Levels
  late final StreamSubscription<QuerySnapshot<Object?>> _levelsStream;
  List<Level?>? _levels;

  ///   Messages
  final MessagesRepository _messagesRepository;
  List<Group?>? _groups;
  late final StreamSubscription<QuerySnapshot<Object?>>? _groupsStream;

  /// Ads
  BannerAd? bannerAd;

/* ************************************************************************* 
                          Rider Profile
 ********************************************************************/

  ///   Called when a new [user] creates and account,
  ///   but a Horse and Rider Profile   is not set up for them
  Future<void> createRiderProfile({required User user}) async {
    debugPrint(
      '111   111   Creating a New Profile for ${user.name}   !!!   !!!',
    );

    final note = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: '${user.name} joined Horse and Rider Companion',
      date: DateTime.now(),
      message: user.name,
      parentId: user.email,
    );

    final riderProfile = RiderProfile(
      picUrl: user.photo,
      name: user.name,
      email: user.email,
      lastEditBy: user.name,
      lastEditDate: DateTime.now(),
      notes: [note],
    );
    try {
      await _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: riderProfile,
      );
    } on FirebaseException catch (e) {
      debugPrint('ERROR Occurred in bloc: $e');
      emit(state.copyWith(error: e.toString()));
    }
  }

  ///   Opens the Edit Profile Dialog
  void menuItemSelected({
    required String choice,
    required BuildContext context,
  }) {
    debugPrint('Menu Selection: $choice');
    switch (choice) {
      case 'Edit':
        showDialog<EditRiderProfileDialog>(
          context: context,
          builder: (context) => EditRiderProfileDialog(
            riderProfile: _usersProfile as RiderProfile,
          ),
        );
        break;
      case 'Add Horse':
        showDialog<AddHorseDialog>(
          context: context,
          builder: (context) => AddHorseDialog(
            riderProfile: _usersProfile,
            editProfile: false,
          ),
        );
        break;
    }
  }

  void openEditDialog({required BuildContext context}) {
    showDialog<EditRiderProfileDialog>(
      context: context,
      builder: (context) => EditRiderProfileDialog(
        riderProfile: _usersProfile as RiderProfile,
      ),
    );
  }

  ///   Open the Rider's Log Book
  void openLogBook(BuildContext context) {
    showModalBottomSheet<LogView>(
      context: context,
      elevation: 20,
      builder: (context) => LogView(
        horseState: null,
        isRider: true,
        state: state,
      ),
    );
  }

  /// Opens the Add Horse Dialog
  void openAddHorseDialog({required BuildContext context}) {
    showDialog<AddHorseDialog>(
      context: context,
      builder: (context) => AddHorseDialog(
        riderProfile: _usersProfile,
        editProfile: false,
      ),
    );
  }

  /// Toggles if the user is a trainer or not
  void toggleIsTrainerState({
    required bool isTrainer,
    required BuildContext context,
  }) {
    final note = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Is Trainer: $isTrainer',
      date: DateTime.now(),
      message: _user.name,
      parentId: _user.email,
    );

    if (isTrainer) {
      _usersProfile?.isTrainer = true;

      ///open dialog to set trainer info
      showDialog<EditRiderProfileDialog>(
        context: context,
        builder: (context) =>
            EditRiderProfileDialog(riderProfile: _usersProfile as RiderProfile),
      );
    } else {
      _usersProfile?.isTrainer = false;
      _usersProfile?.notes?.add(note);
      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _usersProfile as RiderProfile,
      );
    }
  }

  /// Navigates to the Rider Profile Screen
  void riderProfileNavigationSelected() {
    emit(
      state.copyWith(
        index: 0,
        homeStatus: HomeStatus.profile,
      ),
    );
  }

  /// Monitors the Name Field's [value] in the Search Dialog
  void nameChanged(String value) {
    final name = Name.dirty(value);
    emit(state.copyWith(name: name, formzStatus: Formz.validate([name])));
  }

  /// Monitors the HorseName Field's [value] in the Search Dialog
  void horseNameChanged(String value) {
    final name = Name.dirty(value);
    emit(state.copyWith(name: name, formzStatus: Formz.validate([name])));
  }

  /// Monitor the Email Field's [value] in the Search Dialog
  void emailChanged(String value) {
    final email = Email.dirty(value);
    emit(state.copyWith(email: email, formzStatus: Formz.validate([email])));
  }

  /// Change the [searchState]
  void toggleSearchState({required SearchState searchState}) {
    if (state.searchState == searchState) {
      emit(
        state.copyWith(
          searchState: searchState,
          searchType: SearchType.ititial,
          name: const Name.pure(),
          email: const Email.pure(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          searchState: searchState,
          name: const Name.pure(),
          email: const Email.pure(),
        ),
      );
    }
  }

  /// Change the [searchType]
  void changeSearchType({required SearchType searchType}) {
    if (searchType == state.searchType) {
      emit(state.copyWith(searchType: SearchType.ititial));
    } else {
      emit(state.copyWith(searchType: searchType));
    }
  }

  /// Search for a Rider Profile by Name
  void searchProfilesByName() {
    emit(state.copyWith(formzStatus: FormzStatus.submissionInProgress));
    debugPrint('getProfile by Name for ${state.name.value}');
    try {
      _riderProfileRepository
          .getProfilesByName(name: state.name.value.trim())
          .listen((event) {
        final results =
            event.docs.map((e) => (e.data()) as RiderProfile).toList();
        if (results.isNotEmpty) {
          emit(
            state.copyWith(
              searchResult: results,
              formzStatus: FormzStatus.submissionSuccess,
            ),
          );
        } else {
          emit(
            state.copyWith(
              formzStatus: FormzStatus.submissionFailure,
              error: 'No Results',
            ),
          );
        }
      });
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          formzStatus: FormzStatus.submissionFailure,
          error: e.message,
        ),
      );
      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  /// Search for a Horse by Name
  void searchForHorseByName() {
    emit(state.copyWith(formzStatus: FormzStatus.submissionInProgress));
    try {
      _horseProfileRepository
          .getHorseByName(name: state.name.value.trim())
          .listen((event) {
        final results =
            event.docs.map((e) => (e.data()) as HorseProfile).toList();
        if (results.isNotEmpty) {
          emit(
            state.copyWith(
              horseSearchResult: results,
              formzStatus: FormzStatus.submissionSuccess,
            ),
          );
        } else {
          emit(
            state.copyWith(
              formzStatus: FormzStatus.submissionFailure,
              error: 'No Results',
            ),
          );
        }
      });
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          formzStatus: FormzStatus.submissionFailure,
          error: e.message,
        ),
      );

      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  ///  Search results for a horseProfile by Nick Name
  void searchForHorseByNickName() {
    emit(state.copyWith(formzStatus: FormzStatus.submissionInProgress));
    try {
      _horseProfileRepository
          .getHorseByNickName(nickName: state.name.value.trim())
          .listen((event) {
        final results =
            event.docs.map((e) => (e.data()) as HorseProfile).toList();
        if (results.isNotEmpty) {
          emit(
            state.copyWith(
              horseSearchResult: results,
              formzStatus: FormzStatus.submissionSuccess,
            ),
          );
        } else {
          emit(
            state.copyWith(
              formzStatus: FormzStatus.submissionFailure,
              error: 'No Results',
            ),
          );
        }
      });
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          formzStatus: FormzStatus.submissionFailure,
          error: e.message,
        ),
      );

      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  // search results by Email
  void getProfileByEmail() {
    emit(state.copyWith(formzStatus: FormzStatus.submissionInProgress));
    final profileResults = <RiderProfile?>[];
    try {
      _riderProfileRepository
          .getRiderProfile(email: state.email.value.trim().toLowerCase())
          .listen((event) {
        final profile = event.data() as RiderProfile?;
        profileResults.add(profile);
        if (profileResults.isNotEmpty) {
          emit(
            state.copyWith(
              searchResult: profileResults,
              formzStatus: FormzStatus.submissionSuccess,
            ),
          );
        } else {
          emit(
            state.copyWith(
              formzStatus: FormzStatus.submissionFailure,
              error: 'No Results',
            ),
          );
        }
      });
    } on FirebaseException catch (e) {
      emit(
        state.copyWith(
          formzStatus: FormzStatus.submissionFailure,
          error: e.message,
        ),
      );

      debugPrint("Failed with error '${e.code}': ${e.message}");
    }
  }

  /// Clears the search results
  void clearSearchResults() {
    debugPrint('Clear Search Results');
    emit(state.copyWith(searchResult: [], horseSearchResult: []));
  }

  /// Opens a Rider Profile Page for  [toBeViewedEmail]
  void gotoProfilePage({
    required BuildContext context,
    required String toBeViewedEmail,
  }) {
    debugPrint(
      'gotoProfilePage for $toBeViewedEmail, for User: ${state.usersProfile?.name}',
    );
    if (state.usersProfile?.email != toBeViewedEmail) {
      _riderProfileRepository
          .getRiderProfile(email: toBeViewedEmail.toLowerCase())
          .first
          .then((value) {
        emit(
          state.copyWith(
            viewingProfile: value.data() as RiderProfile,
            isViewing: true,
          ),
        );
        Navigator.of(context, rootNavigator: true).pushNamed(
          HomePage.routeName,
          arguments: HomePageArguments(
            viewingProfile: value.data() as RiderProfile,
          ),
        );
      });
    } else {
      //throw error and goto profile page

      emit(
        state.copyWith(
          homeStatus: HomeStatus.profile,
          errorSnackBar: true,
          error: 'Cannot view own profile',
        ),
      );
      // Navigator.of(context, rootNavigator: true).popAndPushNamed(
      //   RiderProfileViewerPage.routeName,
      // arguments: RiderProfileViewerArgs(
      //     state: state,
      //     usersProfile: state.usersProfile as RiderProfile,
      //     riderProfile: state.riderProfile as RiderProfile,
      //     user: _user,
      //   ),
      // );
    }
  }

  bool iEditor() {
    return _usersProfile?.editor ?? false;
  }

  bool isAuthtorized() {
    if (viewingProfile != null) {
      return viewingProfile?.instructors
              ?.contains(state.usersProfile?.email ?? false) ??
          false;
    } else {
      return true;
    }
  }

  void searchClicked() {
    emit(state.copyWith(isSearching: true));
  }

  void clearSearch() {
    emit(state.copyWith(isSearching: false));
  }

  void setViewingProfile(RiderProfile viewingProfile) {
    debugPrint('setting to ViewingProfile');

    emit(
      state.copyWith(
        viewingProfile: viewingProfile,
        isViewing: true,
      ),
    );
  }

  void goBackToUsersProfile() {
    debugPrint('goBackToUsersProfile, setting isViewing to false');

    // ignore: avoid_redundant_argument_values
    emit(state.copyWith(isViewing: false, viewingProfile: null));
  }

  ///emits a  state flag that open a message dialog to HorseAndRidersSupport

  void openMessageToSupportDialog() {
    emit(state.copyWith(isSendingMessageToSupport: true));
  }

  void closeMessageToSupport() {
    emit(state.copyWith(isSendingMessageToSupport: false));
  }

  ///monitors the message entered into the message support dialog
  void messageToSupportChanged(String value) {
    emit(
      state.copyWith(
        message: value,
      ),
    );
  }

  void sendMessageToSupport() {
    if (state.message.isEmpty) {
      emit(state.copyWith(errorSnackBar: true, error: 'Message is empty'));
      return;
    } else {
      emit(state.copyWith(formzStatus: FormzStatus.submissionInProgress));
      final id = StringBuffer()
        ..write(
          convertEmailToPath(
            state.usersProfile?.email?.toLowerCase() as String,
          ),
        )
        ..write(
          convertEmailToPath(
            Constants.HORSEANDRIDERCOMPANIONEMAIL.toLowerCase(),
          ),
        );
      final recipients = <String>[
        state.usersProfile?.email?.toLowerCase() as String,
        Constants.HORSEANDRIDERCOMPANIONEMAIL.toLowerCase(),
      ];

      final memberNames = <String>[
        state.usersProfile?.name as String,
        Constants.HORSEANDRIDERCOMPANIONNAME,
      ];

      final supportMessage = Message(
        id: id.toString(),
        date: DateTime.now(),
        sender: state.usersProfile?.name,
        subject: 'Message to Support',
        message: state.message,
        messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
        recipients: memberNames,
        senderProfilePicUrl: state.usersProfile?.picUrl,
      );

      final group = Group(
        id: id.toString(),
        type: GroupType.private,
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
          ..createOrUpdateGroup(group: group)
          ..createOrUpdateMessage(
            message: supportMessage,
            id: supportMessage.id,
          );
        emit(
          state.copyWith(
            formzStatus: FormzStatus.submissionSuccess,
            isSendingMessageToSupport: false,
            messageSnackBar: true,
            error: "Sent Message to the Horse & Rider's Companion Support Team",
          ),
        );
      } on FirebaseException catch (e) {
        emit(
          state.copyWith(
            formzStatus: FormzStatus.submissionFailure,
            errorSnackBar: true,
            error: e.message,
          ),
        );

        debugPrint("Failed with error '${e.code}': ${e.message}");
      }
    }
  }

  /// sends a message to the a riderProfile with a
  /// request to be added as an instructor
  void createInstructorRequest({
    required BuildContext context,
    required RiderProfile instructorProfile,
  }) {
    final user = state.usersProfile as RiderProfile;
    final messageId = DateTime.now().millisecondsSinceEpoch.toString();
    final studentRequestItem = BaseListItem(
      id: user.email?.toLowerCase() as String,
      name: user.name,
      imageUrl: user.picUrl,
      isCollapsed: true,
      isSelected: false,
    );

    final id = StringBuffer()
      ..write(convertEmailToPath(user.email?.toLowerCase() as String))
      ..write(
        convertEmailToPath(instructorProfile.email?.toLowerCase() as String),
      );
    final memberNames = <String>[
      user.name as String,
      instructorProfile.name as String,
    ];
    final memberIds = <String>[
      user.email?.toLowerCase() as String,
      instructorProfile.email?.toLowerCase() as String,
    ];
    final message = Message(
      date: DateTime.now(),
      id: id.toString(),
      sender: user.name,
      senderProfilePicUrl: user.picUrl,
      messsageId: messageId,
      recipients: memberNames,
      subject: 'Instructor Request',
      message:
          '${user.name} has requested ${instructorProfile.name} to be their Instructor',
      messageType: MessageType.INSTRUCTOR_REQUEST,
      requestItem: studentRequestItem,
    );

    final group = Group(
      id: id.toString(),
      type: GroupType.private,
      parties: memberNames,
      partiesIds: memberIds,
      createdBy: user.name as String,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      lastEditBy: user.name as String,
      recentMessage: message,
    );
    try {
      _messagesRepository
        ..createOrUpdateGroup(group: group)
        ..createOrUpdateMessage(
          message: message,
          id: message.messsageId,
        ).then(
          (value) => emit(
            state.copyWith(
              messageSnackBar: true,
              error: 'Instructor request sent to ${instructorProfile.name}',
            ),
          ),
        );
    } on FirebaseException catch (e) {
      debugPrint("Failed with error '${e.code}': ${e.message}");
      emit(
        state.copyWith(errorSnackBar: true, error: e.message.toString()),
      );
    }
  }

  /// sends a message to a riderProfile with a
  /// request to be added as a student
  void createStudentRequest({
    required BuildContext context,
    required RiderProfile studentProfile,
  }) {
    final user = state.usersProfile;
    debugPrint('user: ${user?.email}');
    debugPrint('student: ${studentProfile.email}');
    final instructorRequestItem = BaseListItem(
      id: user?.email?.toLowerCase(),
      name: user?.name,
      imageUrl: user?.picUrl,
      isCollapsed: true,
      isSelected: false,
    );

    final id = StringBuffer()
      ..write(convertEmailToPath(user?.email?.toLowerCase() as String))
      ..write(
        convertEmailToPath(studentProfile.email?.toLowerCase() as String),
      );
    final memberNames = <String>[
      user?.name as String,
      studentProfile.name as String,
    ];
    final memberIds = <String>[
      user?.email?.toLowerCase() as String,
      studentProfile.email?.toLowerCase() as String,
    ];
    final message = Message(
      date: DateTime.now(),
      id: id.toString(),
      sender: user?.name,
      senderProfilePicUrl: user?.picUrl,
      messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
      recipients: memberNames,
      subject: 'Student Request',
      message:
          '${user?.name} has requested ${studentProfile.name} to be their Student',
      messageType: MessageType.STUDENT_REQUEST,
      requestItem: instructorRequestItem,
    );
    final group = Group(
      id: id.toString(),
      type: GroupType.private,
      parties: memberNames,
      partiesIds: memberIds,
      createdBy: user?.name as String,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      lastEditBy: user?.name as String,
      recentMessage: message,
    );
    try {
      _messagesRepository
        ..createOrUpdateGroup(group: group)
        ..createOrUpdateMessage(
          message: message,
          id: message.messsageId,
        );
      emit(
        state.copyWith(
          messageSnackBar: true,
          error: 'Student request sent to ${studentProfile.name}',
        ),
      );
    } on FirebaseException catch (e) {
      debugPrint('Failed to create student request $e');
      state.copyWith(
        errorSnackBar: true,
        error: e.message.toString(),
      );
    }
  }

  ///  removes a student from the instructors list
  ///  and removes the instructor from the students list
  ///  and adds a note to both users
  void removeStudent({
    required RiderProfile studentProfile,
    required BuildContext context,
  }) {
    final user = state.usersProfile as RiderProfile;
    final userNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email?.toLowerCase() as String,
      name: 'Removed ${studentProfile.name} as Student',
    );
    final studentNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email?.toLowerCase() as String,
      name: '${user.name} removed themselves as an Instructor',
    );

    user.students?.removeWhere(
      (element) => element.id == studentProfile.email?.toLowerCase(),
    );
    user.notes?.add(userNote);
    studentProfile.instructors?.removeWhere(
      (element) => element.id == user.email?.toLowerCase(),
    );
    studentProfile.notes?.add(studentNote);

    try {
      _riderProfileRepository
        ..createOrUpdateRiderProfile(riderProfile: user)
        ..createOrUpdateRiderProfile(riderProfile: studentProfile).then(
          (value) => emit(
            state.copyWith(
              snackBar: true,
              error: 'Removed ${studentProfile.name} as a Student',
            ),
          ),
        );
    } on FirebaseException catch (e) {
      debugPrint("Failed with error '${e.code}': ${e.message}");
      emit(
        state.copyWith(
          errorSnackBar: true,
          error: e.message.toString(),
        ),
      );
    }
  }

  ///  removes an [instructor] from the students list
  ///  and removes the student from the instructors list
  ///  and adds a note to both users
  void removeInstructor({
    required RiderProfile instructor,
    required BuildContext context,
  }) {
    final user = state.usersProfile as RiderProfile;
    final userNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email?.toLowerCase() as String,
      name: 'Removed ${instructor.name} as Instructor',
    );
    final instructorNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email?.toLowerCase() as String,
      name: '${user.name} removed themselves as a Student',
    );

    user.instructors?.removeWhere(
      (element) => element.id == instructor.email?.toLowerCase(),
    );
    instructor.students
        ?.removeWhere((element) => element.id == user.email?.toLowerCase());
    user.notes?.add(userNote);
    instructor.notes?.add(instructorNote);

    try {
      _riderProfileRepository
        ..createOrUpdateRiderProfile(riderProfile: user)
        ..createOrUpdateRiderProfile(riderProfile: instructor).then(
          (value) => emit(
            state.copyWith(
              snackBar: true,
              error: 'Removed ${instructor.name} as Instructor',
            ),
          ),
        );
    } on FirebaseException catch (e) {
      debugPrint("Failed with error '${e.code}': ${e.message}");
      emit(
        state.copyWith(
          errorSnackBar: true,
          error: e.message.toString(),
        ),
      );
    }
  }

  /// adds a [riderProfile] to the users contacts
  /// and adds a note to both users
  void addToContact({
    required RiderProfile riderProfile,
    required BuildContext context,
  }) {
    if (state.usersProfile != null) {
      final user = state.usersProfile;
      final newContact = BaseListItem(
        id: riderProfile.email?.toLowerCase() as String,
        name: riderProfile.name,
        imageUrl: riderProfile.picUrl,
        //this sets the item to a rider profile
        isCollapsed: true,
        isSelected: false,
      );
      final userContact = BaseListItem(
        id: user!.email?.toLowerCase() as String,
        name: user.name,
        imageUrl: user.picUrl,
        isCollapsed: true,
        isSelected: false,
      );
      final userNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email?.toLowerCase() as String,
        name: 'Added ${riderProfile.name} to contacts',
      );
      final riderNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email?.toLowerCase() as String,
        name: '${state.usersProfile?.name} added you to their contacts',
      );
      if (riderProfile.savedProfilesList != null) {
        riderProfile.savedProfilesList!.add(userContact);
      } else {
        riderProfile.savedProfilesList = [userContact];
      }
      riderProfile.notes?.add(riderNote);
      if (user.savedProfilesList != null) {
        user.savedProfilesList!.add(newContact);
      } else {
        user.savedProfilesList = [newContact];
      }
      user.notes?.add(userNote);
      try {
        _riderProfileRepository.createOrUpdateRiderProfile(
          riderProfile: riderProfile,
        );
        _riderProfileRepository
            .createOrUpdateRiderProfile(
              riderProfile: user,
            )
            .then(
              (value) => emit(
                state.copyWith(
                  snackBar: true,
                  error: 'Added ${riderProfile.name} to contacts',
                ),
              ),
            );
      } on FirebaseException catch (e) {
        debugPrint(e.message as String);
        emit(state.copyWith(errorSnackBar: true, error: e.message.toString()));
      }
    } else {
      debugPrint('UserProfile is Null');
      emit(
        state.copyWith(
          errorSnackBar: true,
          error: 'Error: Could not add Contact',
        ),
      );
    }
  }

  // removes a rider from the users contacts
  // and adds a note to both users
  void removeFromContacts({
    required RiderProfile riderProfile,
    required BuildContext context,
  }) {
    if (state.usersProfile != null) {
      final user = state.usersProfile;
      final userNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        parentId: user!.email?.toLowerCase() as String,
        message: user.name,
        name: 'Removed ${riderProfile.name} from contacts',
      );
      final newContactNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: user.name,
        parentId: user.email?.toLowerCase() as String,
        name: '${user.name} removed you from their contacts',
      );

      riderProfile.savedProfilesList
          ?.removeWhere((element) => element.id == user.email);
      riderProfile.notes?.add(newContactNote);
      user.savedProfilesList
          ?.removeWhere((element) => element.id == riderProfile.email);
      user.notes?.add(userNote);
      try {
        _riderProfileRepository
          ..createOrUpdateRiderProfile(
            riderProfile: user,
          )
          ..createOrUpdateRiderProfile(
            riderProfile: riderProfile,
          ).then(
            (value) => emit(
              state.copyWith(
                snackBar: true,
                error: 'Removed ${riderProfile.name} from contacts',
              ),
            ),
          );
      } on FirebaseException catch (e) {
        debugPrint('Failed with error ${e.code}: ${e.message}');
        emit(state.copyWith(errorSnackBar: true, error: e.message.toString()));
      }
    } else {
      debugPrint('UserProfile is Null');
      emit(
        state.copyWith(
          errorSnackBar: true,
          error: 'Error: Could not remove Contact',
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

  ///  Returns true if the userProfile is an instructor of the [viewingProfile]
  bool isInstuctor() {
    return state.viewingProfile?.instructors
            ?.any((element) => element.id == state.usersProfile?.email) ??
        false;
  }

  ///   Open the Messages Page
  void openMessages({required BuildContext context}) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      MessagesPage.routeName,
      arguments: MessageArguments(
        group: null,
        riderProfile: _usersProfile as RiderProfile,
      ),
    );
  }

  /// Opens the Horse Profile Page
  void horseSelected({
    required BuildContext context,
    required String horseProfileId,
  }) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      HorseHomePage.routeName,
      arguments: HorseHomePageArgs(
        horseProfileId: horseProfileId,
        usersProfile: state.usersProfile,
        user: _user,
      ),
    );
    debugPrint('Horse Profile Selected: $horseProfileId');
  }

  /// Toggles whether the User sees the edit tools
  /// for the Resources
  void toggleIsEditState() {
    emit(
      state.copyWith(
        homeStatus: HomeStatus.resource,
        isResourcesEdit: !state.isResourcesEdit,
      ),
    );
  }

  /* *********************************************************************
                                 Rider Skill Tree
  *************************************************************** */

  /// Toggles whether the User sees the edit tools
  /// for the Categories in the Skill Tree
  void toggleCategoryEdit({required bool isEdit}) {
    emit(
      state.copyWith(
        isSkillTreeEdit: isEdit,
      ),
    );
  }

  /// Toggles whether the User sees the edit tools
  /// for the SubCategories in the Skill Tree
  void toggleSubCategoryEdit({
    required bool isEdit,
    required Catagorry? category,
    required List<SubCategory?>? subCategories,
  }) {
    emit(
      state.copyWith(
        isSkillTreeEdit: isEdit,
      ),
    );
  }

  /// Toggles whether the User sees the edit tools
  /// for the Skills in the Skill Tree
  void toggleSkillsEdit({
    required bool isEdit,
    required Catagorry? category,
    required List<Skill?>? skills,
  }) {
    emit(
      state.copyWith(
        isSkillTreeEdit: isEdit,
      ),
    );
  }

  /// Toggles whether the User sees the edit tools
  /// for the Levels in the Skill Tree
  void toggleLevelsEdit({
    required bool isEdit,
    required Catagorry? category,
    required Skill? skill,
    List<Skill?>? skills,
    required List<Level?>? levels,
  }) {
    emit(
      state.copyWith(
        isSkillTreeEdit: isEdit,
      ),
    );
  }

  /// Toggles the Description in the Skill Tree
  void toggleIsDescriptionHidden() {
    emit(state.copyWith(isDescriptionHidden: !state.isDescriptionHidden));
  }

  ///   Called when we want to see the base of the skill tree
  void skillTreeNavigationSelected() {
    if (viewingProfile != null) {
      if (viewingProfile?.instructors
              ?.any((element) => element.id == state.usersProfile?.email) ??
          false) {
        emit(
          state.copyWith(
            index: 1,
            homeStatus: HomeStatus.skillTree,
            skillTreeStatus: SkillTreeStatus.categories,
          ),
        );
      } else {
        emit(
          state.copyWith(
            errorSnackBar: true,
            error: 'You are not an authorized to view this page',
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          index: 1,
          homeStatus: HomeStatus.skillTree,
          skillTreeStatus: SkillTreeStatus.categories,
          categories: _categories,
        ),
      );
    }
  }

  //viewing profile contains users profile in instructors list
  //if true then show the riders log
  // if notViewing then we can see the riders log
  void ridersLogNavigationSelected() {
    if (viewingProfile != null) {
      if (state.viewingProfile?.instructors
              ?.any((element) => element.id == state.usersProfile?.email) ??
          false) {
        emit(
          state.copyWith(
            index: 1,
            homeStatus: HomeStatus.ridersLog,
          ),
        );
      } else {
        emit(
          state.copyWith(
            errorSnackBar: true,
            error: 'You are not an authorized to view this page',
          ),
        );
      }
    } else {
      emit(
        state.copyWith(
          index: 1,
          homeStatus: HomeStatus.ridersLog,
        ),
      );
    }
  }

  ///   Called when a Category is Selected and
  ///   we want to see it's associated SubCategories
  /// a SubCategory is determined by if
  /// the subcategory has a parentId that matches the categoryId selected
  ///   Also, when we press back from Skill State
  void categorySelected({required Catagorry? category}) {
    if (_subCategories != null) {
      debugPrint('Unsorted SubCategories: ${_subCategories!.length}');
    } else {
      debugPrint('Unsorted SubCategories: null');
    }
    final subCategories = <SubCategory?>[];
    if (_subCategories != null) {
      subCategories.addAll(
        _subCategories!
            .where(
              (element) => element?.parentId == category?.id,
            )
            .toList(),
      );
    }
    debugPrint('categorySelected SubCategories: ${subCategories.length}');
    emit(
      state.copyWith(
        homeStatus: HomeStatus.skillTree,
        skillTreeStatus: SkillTreeStatus.subCategories,
        category: category,
        subCategories: subCategories,
        skills: _skills,
      ),
    );
  }

  /// Called when a SubCategory is Selected and we
  ///  want to see it's associated Skills
  // void subCategorySelected({
  //   required SubCategory subCategory,
  //   required Catagorry? category,
  // }) {
  //   final skills = <Skill?>[];
  //   if (_skills != null) {
  //     skills.addAll(
  //       _skills!
  //           .where(
  //             (element) =>
  //                 element!.subCategoryIds?.contains(subCategory.id) ?? false,
  //           )
  //           .toList(),
  //     );
  //   }
  //   emit(
  //     state.copyWith(
  //       homeStatus: HomeStatus.skillTree,
  //       skillTreeStatus: SkillTreeStatus.skill,
  //       category: category,
  //       subCategory: subCategory,
  //       skills: skills,
  //     ),
  //   );
  // }

  /// Called when a Skill is Selected and we
  ///   want to see it's associated Levels
  void skillSelected({
    required Skill skill,
    required SubCategory? subCategory,
    required Catagorry? category,
  }) {
    List<Level?>? skillLevels;
    if (_levels != null) {
      skillLevels = _levels
          ?.where(
            (element) => element?.skillId == skill.id,
          )
          .toList();
    }
    emit(
      state.copyWith(
        homeStatus: HomeStatus.skillTree,
        categories: _categories,
        skillTreeStatus: SkillTreeStatus.level,
        skill: skill,
        subCategory: subCategory,
        levels: skillLevels,
        category: category,
      ),
    );
  }

  ///  Determines if the [level] is verified or not
  /// If the [level] is not verified, then it is grey
  /// If the [level] is verified, then it is yellow
  Color isVerified({required RiderProfile riderProfile, required Level level}) {
    var isVerified = false;
    if (riderProfile.skillLevels != null &&
        riderProfile.skillLevels!.isNotEmpty) {
      final skillLevel = riderProfile.skillLevels?.firstWhere(
        (element) => element.levelId == level.id,
        orElse: () => SkillLevel(
          levelId: level.id,
          lastEditBy: null,
          lastEditDate: level.lastEditDate,
        ),
      );
      if (skillLevel?.lastEditBy != null &&
          skillLevel?.lastEditBy != riderProfile.name) {
        isVerified = true;
      }
    }
    return isVerified ? Colors.yellow : Colors.grey;
  }

  ///  Determines if the [level] is locked or not
  /// If the [level] is locked, then it is grey
  /// If the [level] is unlocked, then it is blue
  Color isLevelUnlocked({
    required Level level,
    required LevelState levelState,
    required RiderProfile riderProfile,
  }) {
    var isVerified = false;
    if (riderProfile.skillLevels != null &&
        riderProfile.skillLevels!.isNotEmpty) {
      final skillLevel = riderProfile.skillLevels?.firstWhere(
        (element) => element.levelId == level.id,
        orElse: () => SkillLevel(
          levelId: level.id,
          lastEditBy: null,
          lastEditDate: level.lastEditDate,
        ),
      );
      if (skillLevel?.lastEditBy != null &&
          skillLevel?.lastEditBy != riderProfile.name) {
        isVerified = true;
      }
      if (skillLevel!.levelState.index == levelState.index) {
        return isVerified ? Colors.yellow : Colors.blue;
      }
    }
    return Colors.grey;
  }

  ///    Called when a [level] is selected and we
  ///    want to change the [levelState] of the SkillLevel in the
  ///    Rider's profile or the Horse's profile
  void levelSelected({
    required Level level,
    required LevelState levelState,
    required RiderProfile usersProfile,
    required RiderProfile? viewingProfile,
  }) {
//  check to see if the viewingProfile is null
//  if it is null, then we are viewing the usersProfile
//  if it is not null, then we are viewing the viewingProfile
    final riderProfile = viewingProfile ?? usersProfile;

    emit(state.copyWith(levelSubmitionStatus: LevelSubmitionStatus.submitting));
    BaseListItem note;
    if (state.viewingProfile?.name == state.usersProfile?.name) {
      note = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        name:
            '${state.usersProfile?.name} has changed ${level.levelName} level to ${levelState.name}',
        parentId: state.usersProfile?.email,
        message: state.usersProfile?.name,
      );
    } else {
      note = BaseListItem(
        date: DateTime.now(),
        name:
            '${usersProfile.name} changed ${level.levelName} level to ${levelState.name} for ${state.viewingProfile?.name ?? 'themself'}',
        parentId: state.usersProfile?.email,
      );
    }
    final skillLevel = riderProfile.skillLevels?.firstWhere(
      (element) => element.levelId == level.id,
      orElse: () => SkillLevel(
        levelId: level.id,
        lastEditBy: level.lastEditBy,
        lastEditDate: level.lastEditDate,
      ),
    ) as SkillLevel;
    // remove the old skill level and add the new one
    riderProfile.skillLevels?.remove(skillLevel);
    riderProfile.skillLevels?.add(
      SkillLevel(
        levelId: level.id,
        levelState: levelState,
        lastEditBy: state.usersProfile?.name ?? '',
        lastEditDate: DateTime.now(),
      ),
    );
    if (riderProfile.notes != null || riderProfile.notes!.isNotEmpty) {
      riderProfile.notes!.add(note);
    }

    _riderProfileRepository
        .createOrUpdateRiderProfile(
          riderProfile: riderProfile,
        )
        .then(
          (value) => emit(
            state.copyWith(
              levelSubmitionStatus: LevelSubmitionStatus.ititial,
              snackBar: true,
              error: 'Updated ${level.levelName} to ${levelState.name}',
            ),
          ),
        );
  }

  /*  ******************************************************************
                      Resources
  ********************************************************************* */

  ///   Resources Tab Selected
  void resourcesNavigationSelected() {
    emit(
      state.copyWith(
        index: 2,
        homeStatus: HomeStatus.resource,
        resources: _resources,
      ),
    );
  }

  ///   Resource Menu Item Selected
  void resourceMenuItemSelected({
    required String choice,
    required BuildContext context,
  }) {
    debugPrint(choice);
    switch (choice) {
      case 'Edit':
        toggleIsEditState();
        break;
      case 'Sort':
        openSortDialog(context);
        break;
    }
  }

  ///   Resource Item Menu Item Selected
  void resourceItemMenuSelected({
    required String choice,
    required BuildContext context,
    required Resource resource,
  }) {
    debugPrint(choice);
    switch (choice) {
      case 'Edit':
        createOrEditResource(
          resource: resource,
          context: context,
        );
        break;
      case 'Delete':
        deleteResource(resource);
        break;
    }
  }

  void createOrEditResource({
    required Resource? resource,
    required BuildContext context,
  }) {
    showDialog<CreateResourcDialog>(
      context: context,
      builder: (context) => CreateResourcDialog(
        userProfile: _usersProfile as RiderProfile,
        resource: resource,
      ),
    );
  }

  ///   Open Sort Dialog for Resources and sort by
  ///  Most Recommended, Most Recent, Saved, Oldest
  /// and then close the dialog
  void openSortDialog(BuildContext context) {
    debugPrint('Open sort Dialog');
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                sortMostRecommended();
                Navigator.of(context).pop();
              },
              child: const Text('Most Recommended'),
            ),
            TextButton(
              onPressed: () {
                sortByNew();
                Navigator.of(context).pop();
              },
              child: const Text('Most Recent'),
            ),
            TextButton(
              onPressed: () {
                sortBySaved();
                Navigator.of(context).pop();
              },
              child: const Text('Saved'),
            ),
            TextButton(
              onPressed: () {
                sortByOld();
                Navigator.of(context).pop();
              },
              child: const Text('Oldest'),
            ),
          ],
        ),
      ),
    );
  }

  /// Sort the resources by the ones with the highest rating
  void sortMostRecommended() {
    final sortedList = _resources;
    sortedList!.sort(
      (a, b) => (b?.rating as int).compareTo(a!.rating as int),
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
    final sortedList = _resources;
    sortedList!.sort(
      (a, b) =>
          (a?.lastEditDate as DateTime).compareTo(b!.lastEditDate as DateTime),
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
    final sortedList = _resources;
    sortedList!.sort(
      (a, b) =>
          (a!.lastEditDate as DateTime).compareTo(b?.lastEditDate as DateTime),
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
    final savedResources = <Resource>[];
    if (_usersProfile != null) {
      if (_usersProfile?.savedResourcesList != null) {
        if (_resources != null) {
          for (final resource in _resources!) {
            if (_usersProfile!.savedResourcesList!.contains(resource!.id)) {
              savedResources.add(resource);
            }
          }
        }
      }
    }
    emit(
      state.copyWith(
        resources: savedResources,
        resourcesSortStatus: ResourcesSortStatus.saved,
      ),
    );
  }

  ///  User has clicked the recommend [resource] button
  void reccomendResource({required Resource? resource}) {
    final editedresource = resource as Resource;
    _setNewPositiveRating(resource: editedresource);
    _resourcesRepository.createOrUpdateResource(resource: editedresource);
  }

  ///  User has clicked the dont recommend [resource] button
  void dontReccomendResource({required Resource? resource}) {
    final editedresource = resource as Resource;
    _setNewNegativeRating(resource: editedresource);
    _resourcesRepository.createOrUpdateResource(resource: editedresource);
  }

  ///   Save [resource] to the users profile saved resources list
  void saveResource({required Resource resource}) {
    List<String> savedResourcesList;
    if (_usersProfile?.savedResourcesList != null) {
      savedResourcesList = _usersProfile?.savedResourcesList as List<String>;
    } else {
      savedResourcesList = [];
    }

    if (!savedResourcesList.contains(resource.id)) {
      savedResourcesList.add(resource.id as String);
    } else {
      savedResourcesList.remove(resource.id);
    }
    _usersProfile?.savedResourcesList = savedResourcesList;

    _riderProfileRepository.createOrUpdateRiderProfile(
      riderProfile: _usersProfile as RiderProfile,
    );
  }

  ///   Sets the new Rating on the [resource] based on whether or not they rated
  Resource _setNewPositiveRating({required Resource resource}) {
    ///   List item with user and rated is true
    final newuser = BaseListItem(
      id: _usersProfile?.email as String,
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
        ?.firstWhere((element) => element?.id == _usersProfile?.email);

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
        } else if (user.isSelected == true && user.isCollapsed == false) {
          ///   Already Positive Rating, -1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isCollapsed = false;
          resource.rating = newNegativeRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          ///   User does not have a registered rateing +1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == true) {
          ///   User already rated NEGATIVE, adding +2
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = true;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
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
    ///   List item with user and rated is true
    final newuser = BaseListItem(
      id: _usersProfile?.email as String,
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
        ?.firstWhere((element) => element?.id == _usersProfile?.email);

    if (resource.usersWhoRated != null) {
      ///  List is not NULL
      if (user != null) {
        ///  Found UserWhoRated
        if (user.isSelected == null && user.isCollapsed == null) {
          ///   Never Rated before addding User and -1
          resource.usersWhoRated?.add(newuser);
          resource.rating = newNegativeRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == true) {
          ///   Already Negative Rating, +1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isCollapsed = false;
          resource.rating = newPositiveRating;
          return resource;
        } else if (user.isSelected == false && user.isCollapsed == false) {
          ///   User does not have a registered rating -1
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isCollapsed = true;
          resource.rating = newNegativeRating;
          return resource;
        } else if (user.isSelected == true && user.isCollapsed == false) {
          ///   User already rated POSITIVE, adding -2
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
              ?.isSelected = false;
          resource.usersWhoRated
              ?.firstWhere((element) => element?.id == _usersProfile?.email)
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

  ///       Ads
  void _loadBannerAds() {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      BannerAd(
        size: AdSize.banner,
        adUnitId: AdHelper.bannerAdUnitId,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            bannerAd = ad as BannerAd;
            emit(state.copyWith(bannerAd: bannerAd, isBannerAdReady: true));
          },
          onAdFailedToLoad: (ad, error) {
            emit(
              state.copyWith(isBannerAdReady: false),
            );
            ad.dispose();
          },
        ),
        request: const AdRequest(),
      ).load();
    }
  }

  void errorSnackBar({required String error}) {
    emit(
      state.copyWith(
        errorSnackBar: true,
        error: error,
      ),
    );
  }

  void clearSnackBar() {
    emit(
      state.copyWith(
        errorSnackBar: false,
        snackBar: false,
        messageSnackBar: false,
        error: '',
      ),
    );
  }

  ///   Close all the open streams
  @override
  Future<void> close() {
    bannerAd?.dispose();
    _levelsStream.cancel();
    _skillsStream.cancel();
    _groupsStream?.cancel();
    _categoryStream.cancel();
    _resourcesStream.cancel();
    _subCategoryStream.cancel();
    _riderProfileSubscription.cancel();
    return super.close();
  }
}
