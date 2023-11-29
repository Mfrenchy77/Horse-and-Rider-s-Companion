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
import 'package:horseandriderscompanion/CommonWidgets/test_resources.dart';
import 'package:horseandriderscompanion/CommonWidgets/test_skills.dart';
import 'package:horseandriderscompanion/Home/Home/RidersLog/riders_log_view.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Home/Resources/View/CreateResourceDialog/View/create_resource_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/add_horse_dialog.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/edit_rider_profile_dialog.dart';
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
    required String? horseId,
    required RiderProfile? viewingProfile,
    required MessagesRepository messagesRepository,
    required ResourcesRepository resourcesRepository,
    required SkillTreeRepository skillTreeRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _user = user,
        _horseId = horseId,
        _viewingProfile = viewingProfile,
        _messagesRepository = messagesRepository,
        _skillTreeRepository = skillTreeRepository,
        _resourcesRepository = resourcesRepository,
        _horseProfileRepository = horseProfileRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const HomeState()) {
    if (!user.isGuest) {
      _riderProfileSubscription = _riderProfileRepository
          .getRiderProfile(email: _user.email)
          .listen((event) {
        final profile = event.data() as RiderProfile?;
        debugPrint('Received Rider Profile: ${profile?.name}');

        if (profile != null) {
          _usersProfile = profile;
          emit(state.copyWith(usersProfile: _usersProfile));
        } else {
          debugPrint('Creating Rider Profile for ${_user.name}');
          createRiderProfile(user: user);
        }
      });
    } else {
      debugPrint('User is a Guest');
      // ignore: avoid_redundant_argument_values
      emit(state.copyWith(usersProfile: null, isGuest: true));
    }

    ///   Stream to listen to changes in HorseProfile and retrieves
    ///   the owner's profile if not the user
    if (_horseId != null) {
      _horseProfileSubscription = _horseProfileRepository
          .getHorseProfileById(id: _horseId)
          .listen((event) {
        _horseProfile = event.data() as HorseProfile?;
        if (!_isOwner()) {
          _riderProfileRepository
              .getRiderProfile(email: _horseProfile?.currentOwnerId)
              .listen((event) {
            _ownersProfile = event.data() as RiderProfile?;
            emit(state.copyWith(ownersProfile: _ownersProfile));
          });
        } else {
          emit(state.copyWith(ownersProfile: _usersProfile));
        }
        debugPrint('HorseProfile: ${_horseProfile?.name}');
        emit(
          state.copyWith(
            horseProfile: _horseProfile,
            isOwner: _isOwner(),
            isForRider: false,
          ),
        );
      });
    } else {
      debugPrint('HorseId is null');
    }

    ///   Stream of Resources

    //FIXME:  Resources for TESTING

    _resources = TestResource.generateTestResources();
    emit(state.copyWith(allResources: _resources));
    _sortResources();

    // _resourcesStream = _resourcesRepository.getResources().listen((event) {
    //   _resources = event.docs.map((doc) => (doc.data()) as Resource?).toList();

    //   emit(
    //     state.copyWith(allResources: _resources),
    //   );
    // });

    ///   Stream of Categoies
    _categoryStream =
        _skillTreeRepository.getCatagoriesForRiderSkillTree().listen((event) {
      _categories =
          event.docs.map((doc) => (doc.data()) as Catagorry?).toList();
      emit(state.copyWith(categories: _categories));
    });

    ///   Stream of SubCategories
    _subCategoryStream = _skillTreeRepository
        .getSubCategoriesForRiderSkillTree()
        .listen((event) {
      _subCategories =
          event.docs.map((e) => (e.data()) as SubCategory?).toList();
      emit(state.copyWith(subCategories: _getSubCategories(category: null)));
    });

    ///   Stream of Skills
    //FIXME:  Skills for TESTING
    _skillsStream = _skillTreeRepository.getSkills().listen((event) {
      // _skills = event.docs.map((doc) => (doc.data()) as Skill?).toList();
      _skills = TestSkills.generateTestSkills();
      _skills!.sort((a, b) => a!.position.compareTo(b!.position));
      _sortSkillForDifficulty(skills: _skills);
      emit(
        state.copyWith(
          allSkills: _getSkills(subCategory: null),
        ),
      );
    });

    ///   Stream of Groups to get unread messages
    ///   Groups Stream
    if (state.usersProfile != null) {
      _groupsStream = _messagesRepository
          .getGroups(
        userEmail: state.usersProfile?.email ?? _user.email as String,
      )
          .listen((event) {
        _groups = event.docs.map((e) => e.data() as Group?).toList();

        final unreadMessages = _groups!.fold(0, (int total, Group? group) {
          if (group?.messageState == MessageState.UNREAD &&
              group?.recentMessage?.sender != _user.email) {
            return total + 1;
          }
          return total;
        });

        emit(state.copyWith(unreadMessages: unreadMessages));
      });
    }

    ///     Load Ad
    _loadBannerAds();

    riderProfileNavigationSelected();
  }

  ///   Repositories
  final MessagesRepository _messagesRepository;
  final ResourcesRepository _resourcesRepository;
  final SkillTreeRepository _skillTreeRepository;
  final HorseProfileRepository _horseProfileRepository;
  final RiderProfileRepository _riderProfileRepository;

  ///   Streams
  StreamSubscription<DocumentSnapshot<Object?>>? _riderProfileSubscription;
  StreamSubscription<DocumentSnapshot<Object?>>? _horseProfileSubscription;
  late final StreamSubscription<QuerySnapshot<Object?>> _skillsStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _categoryStream;
  StreamSubscription<QuerySnapshot<Object?>>? _groupsStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _resourcesStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _subCategoryStream;

  ///   Rider Profile for the current user
  final User _user;
  RiderProfile? _usersProfile;

  ///   Viewing Profile if not null
  final RiderProfile? _viewingProfile;

  /// HorseProfile
  final String? _horseId;
  HorseProfile? _horseProfile;
  RiderProfile? _ownersProfile;

  ///   Resources
  List<Resource?>? _resources;

  ///   Categories
  List<Catagorry?>? _categories;

  ///   SubCategories
  List<SubCategory?>? _subCategories;

  ///   Skills
  List<Skill?>? _skills;

  ///   Messages
  List<Group?>? _groups;

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
      name: '${user.name} joined Horse and Rider Companion!',
      date: DateTime.now(),
      message: user.name,
      parentId: user.email,
    );

    final riderProfile = RiderProfile(
      id: user.id,
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
      debugPrint('Error: ${e.message}');
      emit(state.copyWith(error: e.toString(), errorSnackBar: true));
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
        _usersProfile != null
            ? showDialog<EditRiderProfileDialog>(
                context: context,
                builder: (context) => EditRiderProfileDialog(
                  riderProfile: _usersProfile!,
                ),
              )
            : emit(
                state.copyWith(
                  error: 'User Profile is null',
                  errorSnackBar: true,
                ),
              );
        break;
      case 'Add Horse':
        openAddHorseDialog(
          context: context,
          isEdit: false,
          horseProfile: null,
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
        isRider: state.horseProfile == null,
        state: state,
      ),
    );
  }

  /// Opens the Add/Edit Horse Dialog
  void openAddHorseDialog({
    required BuildContext context,
    required bool isEdit,
    required HorseProfile? horseProfile,
  }) {
    if (state.usersProfile != null) {
      showDialog<AddHorseDialog>(
        context: context,
        builder: (context) => AddHorseDialog(
          horseProfile: horseProfile,
          userProfile: state.usersProfile!,
          editProfile: isEdit,
        ),
      );
    } else {
      debugPrint('Can not add horse, user profile is null');
    }
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
            horseId: null,
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
    }
  }

  bool iEditor() {
    return _usersProfile?.editor ?? false;
  }

  bool isAuthtorized() {
    if (_viewingProfile != null) {
      return _viewingProfile?.instructors
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

  ///  Returns true if the userProfile is an instructor of the viewingProfile
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
      HomePage.routeName,
      arguments:
          HomePageArguments(horseId: horseProfileId, viewingProfile: null),
    );
    debugPrint('Horse Profile Selected: $horseProfileId');
  }

  /// Toggles whether the User sees the edit tools
  void toggleIsEditState() {
    emit(
      state.copyWith(
        isEditState: !state.isEditState,
      ),
    );
  }

/* ****************************************************************************
                          Horse Profile
***************************************************************************** */
  void horseProfileSelected({required String id}) {
    _horseProfile != null
        ? emit(state.copyWith(index: 0, horseProfile: _horseProfile))
        : getHorseProfile(id: id);
  }

  Future<void> getHorseProfile({required String id}) async {
    try {
      _horseProfileRepository.getHorseProfile(id: id).listen((event) {
        _horseProfile = event.data() as HorseProfile?;
        emit(state.copyWith(horseProfile: _horseProfile));
      });
    } on FirebaseException catch (e) {
      debugPrint('Failed to get Horse Profile: $e');
      emit(state.copyWith(error: e.message.toString()));
    }
  }

  /// Check if the user is the owner of the horse
  bool _isOwner() {
    return _horseProfile?.currentOwnerId == _usersProfile?.email;
  }

  bool isStudentHorse({required HorseProfile horseProfile}) {
    var isStudent = false;
    if (horseProfile.instructors != null) {
      for (final instructors in horseProfile.instructors!) {
        if (instructors.id == _usersProfile?.email) {
          isStudent = true;
          break;
        }
      }
    }
    return isStudent;
  }

  /// Create a request to the owner of the horse
  /// to add user as trainer and add horse as student horse
  void requestToBeStudentHorse({
    required bool isStudentHorse,
    required BuildContext context,
    required HorseProfile horseProfile,
  }) {
    if (isStudentHorse) {
      _removeStudentHorse(horseProfile);
    } else {
      _addStudentHorseRequest(context, horseProfile);
    }
  }

  ///  Removes the horse from the users student horse list
  void _removeStudentHorse(HorseProfile horseProfile) {
    debugPrint('Remove Student Horse');
    _usersProfile?.studentHorses
        ?.removeWhere((element) => element.id == horseProfile.id);
    horseProfile.instructors
        ?.removeWhere((element) => element.id == _usersProfile?.email);

    try {
      _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _usersProfile as RiderProfile,
      );
    } on FirebaseException catch (e) {
      debugPrint('Error: $e');
    }
  }

  ///  Creates a request to add the horse as a student horse
  void _addStudentHorseRequest(
    BuildContext context,
    HorseProfile horseProfile,
  ) {
    debugPrint('Request to add horse as student horse');
    if (_ownersProfile == null) {
      debugPrint('Something went Wrong, No owner profile found');
      return;
    }

    final requestHorse = _createRequestHorse(horseProfile);
    final group = _createStudentHorseRequestGroup(horseProfile, requestHorse);
    final message =
        _createStudentHorseRequestMessage(horseProfile, requestHorse, group.id);

    _messagesRepository
      ..createOrUpdateGroup(group: group)
      ..createOrUpdateMessage(message: message, id: message.messsageId);

    navigateToMessagesPage(context, group);
  }

  BaseListItem _createRequestHorse(HorseProfile horseProfile) {
    return BaseListItem(
      id: horseProfile.id,
      name: horseProfile.name,
      imageUrl: horseProfile.picUrl,
      parentId: horseProfile.currentOwnerId,
      message: horseProfile.currentOwnerName,
      isCollapsed: false,
      isSelected: false,
    );
  }

  Group _createStudentHorseRequestGroup(
    HorseProfile horseProfile,
    BaseListItem requestHorse,
  ) {
    final id = _createGroupId().toString();
    final memberNames = [state.usersProfile?.name, _ownersProfile?.name]
        .map((e) => e as String)
        .toList();
    final memberIds = [state.usersProfile?.email, _ownersProfile?.email]
        .map((e) => e?.toLowerCase() as String)
        .toList();

    return Group(
      id: id,
      type: GroupType.private,
      parties: memberNames,
      partiesIds: memberIds,
      createdBy: state.usersProfile?.name as String,
      createdOn: DateTime.now(),
      lastEditBy: state.usersProfile?.name as String,
      lastEditDate: DateTime.now(),
      recentMessage: _createStudentHorseRequestMessage(
        horseProfile,
        requestHorse,
        id,
      ),
    );
  }

  Message _createStudentHorseRequestMessage(
    HorseProfile horseProfile,
    BaseListItem requestHorse,
    String groupId,
  ) {
    return Message(
      date: DateTime.now(),
      id: groupId,
      sender: state.usersProfile?.name as String,
      senderProfilePicUrl: state.usersProfile?.picUrl as String,
      messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
      subject: 'Student Horse Request',
      message:
          '${state.usersProfile?.name} has requested to add ${horseProfile.name} as a student horse.',
      recipients: [state.usersProfile?.name, _ownersProfile?.name]
          .map((e) => e as String)
          .toList(),
      messageType: MessageType.STUDENT_HORSE_REQUEST,
      requestItem: requestHorse,
    );
  }

  StringBuffer _createGroupId() {
    return StringBuffer()
      ..write(
        convertEmailToPath(
          state.usersProfile?.email?.toLowerCase() as String,
        ),
      )
      ..write(
        convertEmailToPath(
          _ownersProfile?.email?.toLowerCase() as String,
        ),
      );
  }

  void navigateToMessagesPage(BuildContext context, Group group) {
    Navigator.of(context, rootNavigator: true).restorablePushNamed(
      MessagesPage.routeName,
      arguments: MessageArguments(
        group: group,
        riderProfile: state.usersProfile,
      ),
    );
  }

  void transferHorseProfile() {
    emit(
      state.copyWith(
        isSnackbar: true,
        message: 'Transfer Horse Profile Currently Not Available',
      ),
    );
    // TODO(mfrenchy77): Implement Transfer Horse Profile
    debugPrint('Transfer this dum horse!!');
  }

  void deleteHorseProfileFromUser() {
    debugPrint(
      'Deleting ${_horseProfile?.name} from ownedHorseList',
    );
    if (_ownersProfile != null) {
      _ownersProfile?.ownedHorses
          ?.removeWhere((element) => element.id == _horseProfile?.id);
      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: _ownersProfile as RiderProfile,
      );
      _horseProfile?.currentOwnerId = 'NONE';
      _horseProfile?.currentOwnerName = 'NONE';
      _horseProfile?.lastEditBy = _ownersProfile?.name;
      _horseProfile?.lastEditDate = DateTime.now();
      _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: _horseProfile as HorseProfile,
      );
    }
  }

  /* *********************************************************************
                               Skill Tree
  *************************************************************** */
  ///   Resources Tab Selected
  void skillTreeNavigationSelected() {
    _sortSkillForDifficulty(skills: state.allSkills);
    emit(
      state.copyWith(
        index: 1,
        homeStatus: HomeStatus.skillTree,
        difficultyState: DifficultyState.all,
        allSkills: _getSkills(subCategory: null),
        skillTreeNavigation: SkillTreeNavigation.Skill,
      ),
    );
  }

/* ********************************************************
                          Search
 ***********************************************************/
  void cancelSearch() {
    emit(state.copyWith(isSearch: false));
  }

  Future<void> search({required List<String?>? searchList}) async {
    debugPrint('Search list: $searchList');
    emit(state.copyWith(isSearch: true, searchList: searchList));
  }

  void getSkillByName(String skillName) {
    final skill = state.allSkills!
        .firstWhere((element) => element!.skillName == skillName);

    emit(
      state.copyWith(
        skill: skill,
      ),
    );
  }

  void clearSearchQuery() {
    emit(state.copyWith(searchQuery: ''));
  }

  void skillSearchQueryChanged({required String searchQuery}) {
    final searchList = state.allSkills
        ?.map((e) => e?.skillName)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList));
  }

  void resourceSearchQueryChanged({required String searchQuery}) {
    final searchList = state.allResources
        ?.map((e) => e?.name)
        .toList()
        .where(
          (element) =>
              element?.toLowerCase().contains(searchQuery.toLowerCase()) ??
              false,
        )
        .toList();
    emit(state.copyWith(searchList: searchList));
  }

/* ********************************************************
                          Filter
  ***********************************************************/

  /// This method will be called when the user clicks the back button
  /// when in subcategories
  void backToCategory() {
    emit(
      state.copyWith(
        skillTreeNavigation: SkillTreeNavigation.Category,
        subCategories: _subCategories,
        allSkills: _skills,
      ),
    );
  }

  /* **************************************************************
                          Skills
   *************************************************************/

  /// This method will be called when the user clicks a skill
  /// it will change the filter to SkillLevel for that skill.
  void skillSelected({required Skill? skill}) {
    if (skill != null) {
      emit(
        state.copyWith(
          index: 1,
          homeStatus: HomeStatus.skillTree,
          skill: skill,
          skillTreeNavigation: SkillTreeNavigation.SkillLevel,
          isSearch: false,
        ),
      );
    } else {
      debugPrint('skill is null');
      emit(state.copyWith(error: 'skill is null', errorSnackBar: true));
    }
  }

  List<Skill?>? getSkillsForResource({required List<String?>? ids}) {
    final skills = <Skill?>[];
    if (ids != null) {
      if (_skills != null) {
        for (final skill in _skills!) {
          if (ids.contains(skill?.id)) {
            skills.add(skill);
          }
        }
      } else {
        debugPrint('skills is null');
      }
    } else {
      return null;
    }
    return skills;
  }

  List<Skill?>? getAllSkills() {
    return _skills;
  }

  List<Skill?>? _getSkills({required SubCategory? subCategory}) {
    final skills = <Skill>[];
    if (subCategory != null) {
      if (_skills != null) {
        for (final skill in _skills!) {
          if (subCategory.skills.contains(skill?.id)) {
            skills.add(skill!);
          }
        }
        emit(
          state.copyWith(
            sortedSkills: _sortedSkillsForHorseOrRider(skills: skills),
          ),
        );
      } else {
        debugPrint('skills is null');
      }
    } else {
      //if subcategory is null we are going to return all the skills
      if (_skills != null) {
        for (final skill in _skills!) {
          skills.add(skill!);
        }
        emit(
          state.copyWith(
            sortedSkills: _sortedSkillsForHorseOrRider(skills: skills),
          ),
        );
      } else {
        debugPrint('skills is null');
      }
    }
    return _sortedSkillsForHorseOrRider(skills: skills);
  }

  void _sortSkillForDifficulty({required List<Skill?>? skills}) {
    emit(
      state.copyWith(
        introSkills: _sortedSkillsForHorseOrRider(skills: skills)
            ?.where(
              (element) => element?.difficulty == DifficultyState.introductory,
            )
            .toList(),
        intermediateSkills: _sortedSkillsForHorseOrRider(skills: skills)
            ?.where(
              (element) => element?.difficulty == DifficultyState.intermediate,
            )
            .toList(),
        advancedSkills: _sortedSkillsForHorseOrRider(skills: skills)
            ?.where(
              (element) => element?.difficulty == DifficultyState.advanced,
            )
            .toList(),
      ),
    );
  }

  void showTrainingSelectedPathsDialog(BuildContext context) {
    showDialog<AlertDialog>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Training Paths'),
          content: SingleChildScrollView(
            child: ListBody(
              children: state.subCategories
                      ?.map(
                        (subcategory) => subcategory != null
                            ? ListTile(
                                title: Text(subcategory.name),
                                onTap: () {
                                  subCategorySelected(subCategory: subcategory);
                                  Navigator.of(context).pop();
                                },
                              )
                            : Container(),
                      )
                      .toList() ??
                  [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /* **************************************************************
                          Difficulty
   *************************************************************/

  Color getBackgroundColorForDifficulty(DifficultyState difficulty) {
    switch (difficulty) {
      case DifficultyState.introductory:
        return Colors.lightBlue.shade100;
      case DifficultyState.intermediate:
        return Colors.blue;
      case DifficultyState.advanced:
        return Colors.blue.shade900;
      case DifficultyState.all:
        return Colors.transparent; // Default color for undefined difficulty
    }
  }

  List<Skill?> sortedByDifficulty({required List<Skill?>? skills}) {
    // Assign each difficulty level a numerical value for sorting
    const difficultyOrder = {
      DifficultyState.introductory: 1,
      DifficultyState.intermediate: 2,
      DifficultyState.advanced: 3,
    };
    if (skills == null) {
      debugPrint('skills is null');
      return [];
    }

    // Sort the filtered list of skills by the
    // numerical value of their difficulty
    final filteredSkills = skills
        .where((skill) => skill!.difficulty != DifficultyState.all)
        .toList()
      ..sort((a, b) {
        final aDifficulty = difficultyOrder[a?.difficulty] ?? 0;
        final bDifficulty = difficultyOrder[b?.difficulty] ?? 0;
        return aDifficulty.compareTo(bDifficulty);
      });

    return filteredSkills;
  }

  void _sortSkillsByDifficulty({
    required DifficultyState difficultyState,
    required SubCategory? subCategory,
  }) {
    //if the user clicks a difficulty we are going to change the filter to
    //skills for that difficulty.
    // and select only the skills for that difficulty
    // if difficulty is all we are going to show all the skills

    var skills = <Skill?>[];
    emit(
      state.copyWith(
        allSkills: _getSkills(subCategory: subCategory),
      ),
    );
    debugPrint('DifficultyState: $difficultyState');

    if (state.sortedSkills != null) {
      if (difficultyState != DifficultyState.all) {
        skills = state.sortedSkills!
            .where((element) => element?.difficulty == difficultyState)
            .toList();

        emit(
          state.copyWith(
            sortedSkills: skills,
            difficultyState: difficultyState,
            skillTreeNavigation: SkillTreeNavigation.Skill,
          ),
        );
      } else {
        emit(
          state.copyWith(
            sortedSkills: _getSkills(subCategory: subCategory),
            difficultyState: difficultyState,
            skillTreeNavigation: SkillTreeNavigation.Skill,
          ),
        );
      }
    } else {
      debugPrint('skills is null');
    }
    emit(state.copyWith(difficultyState: difficultyState));
  }
// Open the difficulty select dialog
// this will allow the user to select a difficulty to filter by
// the user can select all, introductory, intermediate, or advanced

  void openDifficultySelectDialog({
    required BuildContext context,
    required SubCategory? subCategory,
  }) {
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.introductory,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Introductory'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.intermediate,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Intermediate'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  subCategory: subCategory,
                  difficultyState: DifficultyState.advanced,
                );
                Navigator.of(context).pop();
              },
              child: const Text('Advanced'),
            ),
            TextButton(
              onPressed: () {
                _sortSkillsByDifficulty(
                  difficultyState: DifficultyState.all,
                  subCategory: subCategory,
                );
                Navigator.of(context).pop();
              },
              child: const Text('All'),
            ),
          ],
        ),
      ),
    );
  }

  /* **************************************************************
                          Categories
   *************************************************************/

  /// This method will be called when the user clicks a category
  /// it will change the filter to subcategories for that category.
  void categorySelected({required Catagorry category}) {
    //if the user clicks a category we are going to change the filter
    //to subcategories for that category.
    // and select only the subcategories for that category
    var subCategories = <SubCategory?>[];
    if (state.subCategories != null) {
      subCategories = _subCategories!
          .where((element) => element?.parentId == category.id)
          .toList();

      emit(
        state.copyWith(
          categories: _categories,
          category: category,
          subCategories: subCategories,
          skillTreeNavigation: SkillTreeNavigation.SubCategory,
        ),
      );
    } else {
      debugPrint('subCategories is null');
    }
  }

  void skillTreeHome() {
    debugPrint('skillTreeHome');
    emit(
      state.copyWith(
        skillTreeNavigation: SkillTreeNavigation.Skill,
        subCategories: _subCategories,
        allSkills: _skills,
        sortedSkills: _skills,
      ),
    );
  }

  /* **************************************************************
                          SubCategories
   *************************************************************/

  /// This method will be called when the user clicks a subcategory
  /// it will change the filter to skills for that subcategory.
  /// and select only the skills for that subcategory
  void subCategorySelected({required SubCategory subCategory}) {
    emit(
      state.copyWith(
        subCategory: subCategory,
        sortedSkills: _getSkills(subCategory: subCategory),
        skillTreeNavigation: SkillTreeNavigation.Skill,
      ),
    );
  }

  /// Sort skills by horse or rider
  List<Skill?>? _sortedSkillsForHorseOrRider({required List<Skill?>? skills}) {
    return state.isForRider
        ? skills?.where((element) => element?.rider ?? true == true).toList()
        : skills?.where((element) => element?.rider == false).toList();
  }

  /// get SubCategories for a Category
  /// if the category is null we will return all the subcategories
  /// sorted by bool isForRider
  List<SubCategory?>? _getSubCategories({required Catagorry? category}) {
    final subCategories = <SubCategory?>[];
    if (category != null) {
      if (_subCategories != null) {
        for (final subCategory in _subCategories!) {
          if (subCategory?.parentId == category.id) {
            subCategories.add(subCategory);
          }
        }
        emit(
          state.copyWith(
            subCategories: _sortedSubCategoriesForHorseOrRider(
              subCategories: subCategories,
            ),
          ),
        );
      } else {
        debugPrint('subCategories is null');
      }
    } else {
      //if category is null we are going to return all the subcategories
      if (_subCategories != null) {
        for (final subCategory in _subCategories!) {
          subCategories.add(subCategory);
        }
        emit(
          state.copyWith(
            subCategories: _sortedSubCategoriesForHorseOrRider(
              subCategories: subCategories,
            ),
          ),
        );
      } else {
        debugPrint('subCategories is null');
      }
    }
    return _sortedSubCategoriesForHorseOrRider(subCategories: subCategories);
  }

  /// Sorted SubCategories by bool isForRider
  List<SubCategory?>? _sortedSubCategoriesForHorseOrRider({
    required List<SubCategory?>? subCategories,
  }) {
    return state.isForRider
        ? subCategories
            ?.where((element) => element?.isRider ?? true == true)
            .toList()
        : subCategories?.where((element) => element?.isRider == false).toList();
  }

  /* **************************************************************
                        Skill Level
   *************************************************************/

  Color levelColor({
    required LevelState levelState,
  }) {
    final skill = state.skill;
    final riderProfile = determineCurrentProfile();
    var isVerified = false;
    {
      if (skill != null) {
        if (riderProfile != null) {
          if (riderProfile.skillLevels != null &&
              riderProfile.skillLevels!.isNotEmpty) {
            final skillLevel = riderProfile.skillLevels?.firstWhere(
              (element) => element.skillId == skill.id,
              orElse: () => SkillLevel(
                skillId: skill.id,
                lastEditBy: _usersProfile?.name,
                lastEditDate: DateTime.now(),
              ),
            );

            if (skillLevel?.lastEditBy != null &&
                skillLevel?.lastEditBy != riderProfile.name) {
              isVerified = true;
            }
            if (skillLevel!.levelState.index >= levelState.index) {
              return isVerified ? Colors.yellow : Colors.blue;
            }
          }
        } else {
          debugPrint('isGuest');
          return Colors.grey;
        }
      } else {
        debugPrint('skill is null');
        emit(state.copyWith(isError: true, error: 'skill is null'));
      }
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
              skillId: skill.id,
              lastEditBy: _usersProfile?.name,
              lastEditDate: DateTime.now(),
            ),
          );
          if (skillLevel?.levelState == LevelState.NO_PROGRESS) {
            return skill.learningDescription ?? '';
          } else if (skillLevel?.levelState == LevelState.LEARNING) {
            return skill.proficientDescription ?? '';
          } else if (skillLevel?.levelState == LevelState.PROFICIENT) {
            return 'You should be able to do ${skill.skillName} without assistance anymore';
          } else {
            return '';
          }
        } else {
          debugPrint('skillLevels is null');
          return '';
        }
      } else {
        debugPrint('isGuest');
        return 'This is where you will be able to track your progress for this skill';
      }
    } else {
      debugPrint('skill is null');
      return '';
    }
  }

  ///    Called when a [level] is selected and we
  ///    want to change the [levelState] of the SkillLevel in the
  ///    Rider's profile or the Horse's profile
  void levelSelected({required LevelState levelState}) {
    // Determine the current profile being viewed.
    final riderProfile = determineCurrentProfile();

    // Start the level submission process.
    emitSubmittingStatus();

    // Create an audit note for the level change.
    final note = _createLevelChangeNote(levelState);

    // Update the skill level for the rider.
    _updateRiderSkillLevel(riderProfile, levelState, note);

    // Persist the changes to the repository.
    _persistRiderProfileChanges(riderProfile, levelState);
  }
  //the current profile being viewed

  RiderProfile? determineCurrentProfile() {
    if (_viewingProfile != null) {
      return _viewingProfile!;
    } else if (_usersProfile != null) {
      return _usersProfile!;
    } else {
      return null;
    }
  }

// Emits a status indicating the submission process has started
  void emitSubmittingStatus() {
    emit(
      state.copyWith(
        levelSubmissionStatus: LevelSubmissionStatus.submitting,
      ),
    );
  }

  /// Creates an audit note for the level change
  BaseListItem _createLevelChangeNote(
    LevelState levelState,
  ) {
    String noteMessage;
    if (state.viewingProfile?.name == state.usersProfile?.name) {
      noteMessage =
          '${state.usersProfile?.name} has changed ${state.skill?.skillName} level to ${levelState.name}';
    } else {
      noteMessage =
          '${_usersProfile?.name} changed ${state.skill?.skillName} level to ${levelState.name} for ${state.viewingProfile?.name ?? 'themself'}';
    }
    return BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      name: noteMessage,
      parentId: _usersProfile?.email,
      message: _usersProfile?.name,
    );
  }

  /// Updates the skill level for the rider
  void _updateRiderSkillLevel(
    RiderProfile? riderProfile,
    LevelState levelState,
    BaseListItem note,
  ) {
    if (riderProfile != null) {
      final timestamp = DateTime
          .now(); // Reuse the same timestamp for all operations in this method
      final skillLevel = riderProfile.skillLevels?.firstWhere(
            (element) => element.skillId == state.skill?.id,
            orElse: () => SkillLevel(
              skillId: state.skill?.id,
              lastEditBy: _usersProfile?.name,
              lastEditDate: timestamp,
            ),
          ) ??
          SkillLevel(
            skillId: state.skill?.id,
            lastEditBy: _usersProfile?.name,
            lastEditDate: timestamp,
          );

      riderProfile.skillLevels?.remove(skillLevel);
      riderProfile.skillLevels?.add(
        SkillLevel(
          skillId: state.skill?.id,
          levelState: levelState,
          lastEditBy: _usersProfile?.name,
          lastEditDate: timestamp,
        ),
      );

      _addNoteToProfile(riderProfile, note);
    } else {
      debugPrint('riderProfile is null');
    }
  }

// Adds a note to the rider's profile if necessary
  void _addNoteToProfile(RiderProfile riderProfile, BaseListItem note) {
    if (riderProfile.notes != null && riderProfile.notes!.isEmpty) {
      riderProfile.notes!.add(note);
    }
  }

// Persists the changes to the rider profile to the repository
  void _persistRiderProfileChanges(
    RiderProfile? riderProfile,
    LevelState levelState,
  ) {
    if (riderProfile != null) {
      try {
        _riderProfileRepository
            .createOrUpdateRiderProfile(riderProfile: riderProfile)
            .then(
              (value) => emit(
                state.copyWith(
                  levelSubmissionStatus: LevelSubmissionStatus.initial,
                  isError: false,
                  message:
                      'Updated ${state.skill?.skillName} to ${levelState.name}',
                ),
              ),
            );
      } catch (error) {
        emit(
          state.copyWith(
            levelSubmissionStatus: LevelSubmissionStatus.initial,
            isError: true,
            error:
                'Failed to update ${state.skill?.skillName} to ${levelState.name}: $error',
          ),
        );
      }
    } else {
      debugPrint('riderProfile is null');
    }
  }

  //viewing profile contains users profile in instructors list
  //if true then show the riders log
  // if notViewing then we can see the riders log
  void logNavigationSelected() {
    if (state.horseProfile == null) {
      if (_viewingProfile != null) {
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
    } else {
      emit(
        state.copyWith(
          index: 1,
          homeStatus: HomeStatus.horseLog,
        ),
      );
    }
  }

  ///   Add a Log Entry
  // TODO(mfrenchy): implemente add log entry
  void addLogEntry({required BuildContext context}) {
    debugPrint('ADD LOG ENTRY, Yo!');
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
        allResources: state.allResources,
      ),
    );
  }

  ///  Editing a resource set it to state
  void editingResource({required Resource? resource}) {
    debugPrint('Editing Resource: ${resource?.name}');
    debugPrint('number of skills: ${resource?.skillTreeIds?.length}');
    emit(state.copyWith(resource: resource));
  }

  ///Resource is selected to be added to a Skill

  void addResourceToSkill({
    required Resource? resource,
    required Skill? skill,
  }) {
    if (resource != null) {
      debugPrint('Resource Selected: ${resource.name}');

      if (skill != null) {
        debugPrint('Skill Selected: ${skill.skillName}');
        // Initialize skillTreeIds with an empty list if null, otherwise use the existing list
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
          emit(state.copyWith(error: e.toString(), errorSnackBar: true));
        }
      } else {
        debugPrint('skill is null');
        emit(state.copyWith(error: 'skill is null', errorSnackBar: true));
      }
    } else {
      debugPrint('resource is null');
      emit(state.copyWith(error: 'resource is null', errorSnackBar: true));
    }
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
        skills: state.allSkills,
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
        allResources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.mostRecommended,
      ),
    );
  }

  void _sortResources() {
    switch (state.resourcesSortStatus) {
      case ResourcesSortStatus.recent:
        sortByNew();
        break;
      case ResourcesSortStatus.oldest:
        sortByOld();
        break;
      case ResourcesSortStatus.saved:
        sortBySaved();
        break;
      case ResourcesSortStatus.mostRecommended:
        sortMostRecommended();
        break;
    }
  }

  ///  Sort the resources by the newest last edit date
  void sortByNew() {
    debugPrint('Sorting by New');
    final sortedList = _resources;
    sortedList!.sort(
      (a, b) =>
          (b?.lastEditDate as DateTime).compareTo(a!.lastEditDate as DateTime),
    );
    emit(
      state.copyWith(
        allResources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.recent,
      ),
    );
  }

  /// Sort the resources by the ones that have the oldest
  /// last edit date
  void sortByOld() {
    debugPrint('Sorting by Old');
    final sortedList = _resources;
    sortedList!.sort(
      (a, b) =>
          (a!.lastEditDate as DateTime).compareTo(b?.lastEditDate as DateTime),
    );
    emit(
      state.copyWith(
        allResources: sortedList,
        resourcesSortStatus: ResourcesSortStatus.oldest,
      ),
    );
  }

  /// Sort the resources by the ones that have been saved
  /// by the user
  void sortBySaved() {
    debugPrint('Sorting by Saved');
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
        allResources: savedResources,
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

  /// Open Resource Skill Tree Dialog
  // dialog to show all the skills accociated with the resource
  // and the user can select a skill to view
  // or add a skill to the resource
  //TODO(mfrenchy): implement this
  void openResourceSkillTreeDialog({
    required BuildContext context,
    required Resource resource,
  }) {
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => const AlertDialog(),
    );
  }

  ///  Convert all the http urls to uppercase
  List<Resource?>? _convertResourceUrls(
    List<Resource?>? resources,
  ) {
    if (resources == null) return null;

    return resources.map((resource) {
      if (resource != null && resource.url != null) {
        final newUrl = _modifyUrl(resource.url!);
        final newThumbnail = _modifyUrl(resource.thumbnail!);
        return resource.copyWith(url: newUrl, thumbnail: newThumbnail);
      }
      return resource;
    }).toList();
  }

  String _modifyUrl(String url) {
    // Convert http or https to uppercase
    final httpRegExp = RegExp('https?', caseSensitive: false);
    var modifiedUrl = url.replaceAllMapped(
      httpRegExp,
      (match) => match.group(0)!.toUpperCase(),
    );

    // Add 'www.' if it is not present after 'http://' or 'https://'
    final wwwRegExp = RegExp(r'^(HTTP://|HTTPS://)(?!www\.)');
    return modifiedUrl = modifiedUrl.replaceAllMapped(
      wwwRegExp,
      (match) => '${match.group(0)}www.',
    );
  }

  bool isNewResource(Resource resource) {
    final now = DateTime.now();
    final difference = now.difference(resource.lastEditDate as DateTime);
    return difference.inDays < 10;
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
    _skillsStream.cancel();
    _groupsStream?.cancel();
    _categoryStream.cancel();
    _resourcesStream.cancel();
    _subCategoryStream.cancel();
    _riderProfileSubscription?.cancel();
    _horseProfileSubscription?.cancel();
    return super.close();
  }
}
