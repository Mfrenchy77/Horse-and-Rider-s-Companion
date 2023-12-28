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
    required RiderProfile? usersProfile,
    required RiderProfile? viewingProfile,
    required MessagesRepository messagesRepository,
    required ResourcesRepository resourcesRepository,
    required SkillTreeRepository skillTreeRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
  })  : _messagesRepository = messagesRepository,
        _skillTreeRepository = skillTreeRepository,
        _resourcesRepository = resourcesRepository,
        _horseProfileRepository = horseProfileRepository,
        _riderProfileRepository = riderProfileRepository,
        super(const HomeState()) {
    emit(state.copyWith(viewingProfile: viewingProfile));
    if (usersProfile != null) {
      debugPrint('Users Profile: ${usersProfile.email}');
      emit(state.copyWith(usersProfile: usersProfile));
    } else {
      debugPrint('userProfile is null');
    }
    if (!user.isGuest) {
      debugPrint('Trying to get Rider Profile for ${user.email}');
      _riderProfileSubscription = _riderProfileRepository
          .getRiderProfile(email: user.email)
          .listen((event) {
        final profile = event.data() as RiderProfile?;
        debugPrint('Received Rider Profile: ${profile?.name}');

        if (profile != null) {
          emit(state.copyWith(usersProfile: profile));
        } else {
          debugPrint('Creating Rider Profile for ${user.name}');
          createRiderProfile(user: user);
        }
        profileNavigationSelected();
      });
    } else {
      debugPrint('User is a Guest');
      // ignore: avoid_redundant_argument_values
      emit(state.copyWith(usersProfile: null, isGuest: true));
    }
    if (horseId != null) {
      horseProfileSelected(id: horseId);
    }

    ///   Stream to listen to changes in HorseProfile and retrieves
    ///   the owner's profile if not the user
    // if (horseId != null) {
    //   if (state.horseProfile == null || state.horseProfile?.id != horseId) {
    //     debugPrint('Getting HorseProfile for $horseId');
    //     _horseProfileSubscription = _horseProfileRepository
    //         .getHorseProfileById(id: horseId)
    //         .listen((event) {
    //       final horseProfile = event.data() as HorseProfile?;
    //       debugPrint('HorseProfile: ${horseProfile?.name}');
    //       if (!_isOwner()) {
    //         _riderProfileRepository
    //             .getRiderProfile(email: horseProfile?.currentOwnerId)
    //             .listen((event) {
    //           final ownersProfile = event.data() as RiderProfile?;
    //           debugPrint('Owners Profile: ${ownersProfile?.name}');
    //           emit(state.copyWith(ownersProfile: ownersProfile));
    //         });
    //       } else {
    //         debugPrint('User is the Owner');
    //         emit(state.copyWith(ownersProfile: usersProfile));
    //       }
    //       debugPrint('Setting HorseProfile');
    //       emit(
    //         state.copyWith(
    //           horseProfile: horseProfile,
    //           isOwner: _isOwner(),
    //           isForRider: false,
    //         ),
    //       );
    //     });
    //   } else {
    //     debugPrint('HorseProfile already set');
    //   }
    // } else {
    //   debugPrint('HorseId is null');
    // }

    ///   Stream of Resources

    //FIXME:  Resources for TESTING
    if (state.allResources == null) {
      debugPrint('Getting Resources');
      final resources = TestResource.generateTestResources();
      emit(state.copyWith(allResources: resources));
      _sortResources();
    } else {
      debugPrint('Resources already set');
    }
    _resourcesStream = _resourcesRepository.getResources().listen((event) {
      debugPrint('Resources Stream: got data ${event.docs.length}');
      // _resources = event.docs.map((doc) => (doc.data()) as Resource?).toList();

      // emit(
      //   state.copyWith(allResources: _resources),
      // );
    });

    ///   Stream of Categoies
    // if (state.categories == null) {
    //   debugPrint('Getting Categories');
    //   _categoryStream =
    //       _skillTreeRepository.getCatagoriesForRiderSkillTree().listen((event) {
    //     debugPrint('Categories Stream: got data ${event.docs.length}');
    //     final categories =
    //         event.docs.map((doc) => (doc.data()) as Catagorry?).toList();
    //     emit(state.copyWith(categories: categories));
    //   });
    // }

    ///   Stream of SubCategories
    // if (state.subCategories == null) {
    //   debugPrint('Getting SubCategories');
    //   _subCategoryStream = _skillTreeRepository
    //       .getSubCategoriesForRiderSkillTree()
    //       .listen((event) {
    //     debugPrint('SubCategories Stream: got data ${event.docs.length}');
    //     final subCategories =
    //         event.docs.map((e) => (e.data()) as SubCategory?).toList();
    //     emit(state.copyWith(subCategories: subCategories));
    //     _sortSubCategories(category: null);
    //   });
    // } else {
    //   debugPrint('SubCategories already set');
    // }
    /// Stream of Training Paths
    _getTrainingPaths();

    ///   Stream of Skills

    if (state.allSkills == null) {
      debugPrint('Getting Skills');
      getSkills();

      //   _skillsStream = _skillTreeRepository.getSkills().listen((event) {
      //     debugPrint('Skills Stream: got data ${event.docs.length}');
      //     final skills = TestSkills.generateTestSkills()
      //       ..sort((a, b) => a.position.compareTo(b.position));

      //     debugPrint('Setting allSkills: ${skills.length}');
      //     emit(state.copyWith(allSkills: skills));
      //     sortSkills(subCategory: null);
      //     // final skills = event.docs.map((doc) => (doc.data()) as Skill?).toList();
      //     // debugPrint('Setting allSkills: ${skills.length}');
      //     // emit(state.copyWith(allSkills: skills));
      //   });
    } else {
      debugPrint('Skills already set');
    }

    ///   Stream of Groups to get unread messages
    ///   Groups Stream
    if (state.usersProfile != null) {
      debugPrint('Getting Groups');
      _groupsStream = _messagesRepository
          .getGroups(
        userEmail: state.usersProfile!.email,
      )
          .listen((event) {
        debugPrint('Groups Stream: got data ${event.docs.length}');
        final groups = event.docs.map((e) => e.data() as Group?).toList();

        final unreadMessages = groups.fold(0, (int total, Group? group) {
          if (group?.messageState == MessageState.UNREAD &&
              group?.recentMessage?.sender != state.usersProfile!.email) {
            return total + 1;
          }
          return total;
        });

        emit(state.copyWith(unreadMessages: unreadMessages));
      });
    }

    ///     Load Ad
    _loadBannerAds();

    // profileNavigationSelected();
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
  late final StreamSubscription<QuerySnapshot<Object?>> _trainingPathsStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _categoryStream;
  StreamSubscription<QuerySnapshot<Object?>>? _groupsStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _resourcesStream;
  late final StreamSubscription<QuerySnapshot<Object?>> _subCategoryStream;

  ///   Rider Profile for the current user

  ///   Viewing Profile if not null

  /// HorseProfile

  ///   Resources

  ///   Categories

  ///   SubCategories

  ///   Skills

  ///   Messages

  /// Ads
  BannerAd? bannerAd;

  /* ***********************************************************************
                          Navigation
  *************************************************************************** */
  /// Handles the Navigation when the back button is pressed from Resources, Skill Tree
  /// Messages, HorseProfile or Viewing a Rider Profile
  void backPressed() {
    if (state.index == 0 && state.isViewing) {
      goBackToUsersProfile();
    } else if (state.index == 1 &&
        state.skillTreeNavigation == SkillTreeNavigation.SkillList) {
      navigateToTrainingPathList();
    } else if (state.index == 1 &&
        state.skillTreeNavigation == SkillTreeNavigation.SkillLevel) {
      navigateToTrainingPathList();
    } else if (state.index == 1 &&
        state.skillTreeNavigation == SkillTreeNavigation.TrainingPathList) {
      profileNavigationSelected();
    } else if (state.index == 1 &&
        state.skillTreeNavigation == SkillTreeNavigation.TrainingPath) {
      navigateToTrainingPathList();
    } else if (state.index == 0 && !state.isForRider) {
      goBackToUsersProfile();
    } else if (state.index == 2) {
      navigateToTrainingPathList();
    }
  }

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
        state.usersProfile != null
            ? showDialog<EditRiderProfileDialog>(
                context: context,
                builder: (context) => EditRiderProfileDialog(
                  riderProfile: state.usersProfile!,
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
        riderProfile: state.usersProfile!,
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
    final currentUserProfile = state.usersProfile;
    if (currentUserProfile == null) {
      // Handle the case where the user profile is not available
      debugPrint('User profile is not available');
      return;
    }

    final note = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Is Trainer: $isTrainer',
      date: DateTime.now(),
      message: currentUserProfile.name,
      parentId: currentUserProfile.email,
    );

    currentUserProfile.isTrainer = isTrainer;
    if (!isTrainer) {
      currentUserProfile.notes?.add(note);
    }
    _riderProfileRepository.createOrUpdateRiderProfile(
      riderProfile: currentUserProfile,
    );

    if (isTrainer) {
      showDialog<EditRiderProfileDialog>(
        context: context,
        builder: (context) =>
            EditRiderProfileDialog(riderProfile: currentUserProfile),
      );
    }
  }

  /// Navigates to the Rider Profile Screen
  void profileNavigationSelected() {
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
              errorSnackBar: true,
            ),
          );
        }
      });
    } catch (e) {
      emit(
        state.copyWith(
          formzStatus: FormzStatus.submissionFailure,
          error: e.toString(),
          errorSnackBar: true,
        ),
      );
      debugPrint("Failed with error '$e': $e");
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
      'gotoProfilePage for $toBeViewedEmail, for User: ${state.usersProfile?.email}',
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
            usersProfile: state.usersProfile,
          ),
        );
      });
    } else {
      //throw error and goto profile page
      debugPrint('Cannot view own profile');
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
    return state.usersProfile?.editor ?? false;
  }

  bool isAuthtorized() {
    // TODO(mfrenchy): This logic seems backwards
    if (state.viewingProfile != null) {
      return state.viewingProfile?.instructors
              ?.contains(state.usersProfile?.email ?? false) ??
          false;
    } else {
      return true;
    }
  }

  void openSearchForHorsesOrRiders() {
    emit(state.copyWith(isSearching: true));
  }

  void closeSearchForHorsesOrRiders() {
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
    emit(
      state.copyWith(
        isViewing: false,
        viewingProfile: null,
        index: 0,
        isForRider: true,
      ),
    );
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
            state.usersProfile?.email.toLowerCase() as String,
          ),
        )
        ..write(
          convertEmailToPath(
            Constants.HORSEANDRIDERCOMPANIONEMAIL.toLowerCase(),
          ),
        );
      final recipients = <String>[
        state.usersProfile?.email.toLowerCase() as String,
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
      id: user.email.toLowerCase(),
      name: user.name,
      imageUrl: user.picUrl,
      isCollapsed: true,
      isSelected: false,
    );

    final id = StringBuffer()
      ..write(convertEmailToPath(user.email.toLowerCase()))
      ..write(
        convertEmailToPath(instructorProfile.email.toLowerCase()),
      );
    final memberNames = <String>[
      user.name,
      instructorProfile.name,
    ];
    final memberIds = <String>[
      user.email.toLowerCase(),
      instructorProfile.email.toLowerCase(),
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
      createdBy: user.name,
      createdOn: DateTime.now(),
      lastEditDate: DateTime.now(),
      lastEditBy: user.name,
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
      id: user?.email.toLowerCase(),
      name: user?.name,
      imageUrl: user?.picUrl,
      isCollapsed: true,
      isSelected: false,
    );

    final id = StringBuffer()
      ..write(convertEmailToPath(user?.email.toLowerCase() as String))
      ..write(
        convertEmailToPath(studentProfile.email.toLowerCase()),
      );
    final memberNames = <String>[
      user?.name as String,
      studentProfile.name,
    ];
    final memberIds = <String>[
      user?.email.toLowerCase() as String,
      studentProfile.email.toLowerCase(),
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
      parentId: user.email.toLowerCase(),
      name: 'Removed ${studentProfile.name} as Student',
    );
    final studentNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email.toLowerCase(),
      name: '${user.name} removed themselves as an Instructor',
    );

    user.students?.removeWhere(
      (element) => element.id == studentProfile.email.toLowerCase(),
    );
    user.notes?.add(userNote);
    studentProfile.instructors?.removeWhere(
      (element) => element.id == user.email.toLowerCase(),
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
      parentId: user.email.toLowerCase(),
      name: 'Removed ${instructor.name} as Instructor',
    );
    final instructorNote = BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      message: user.name,
      parentId: user.email.toLowerCase(),
      name: '${user.name} removed themselves as a Student',
    );

    user.instructors?.removeWhere(
      (element) => element.id == instructor.email.toLowerCase(),
    );
    instructor.students
        ?.removeWhere((element) => element.id == user.email.toLowerCase());
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
        id: riderProfile.email.toLowerCase(),
        name: riderProfile.name,
        imageUrl: riderProfile.picUrl,
        //this sets the item to a rider profile
        isCollapsed: true,
        isSelected: false,
      );
      final userContact = BaseListItem(
        id: user!.email.toLowerCase(),
        name: user.name,
        imageUrl: user.picUrl,
        isCollapsed: true,
        isSelected: false,
      );
      final userNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email.toLowerCase() as String,
        name: 'Added ${riderProfile.name} to contacts',
      );
      final riderNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email.toLowerCase() as String,
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
        parentId: user!.email.toLowerCase(),
        message: user.name,
        name: 'Removed ${riderProfile.name} from contacts',
      );
      final newContactNote = BaseListItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        message: user.name,
        parentId: user.email.toLowerCase(),
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
        riderProfile: state.usersProfile,
      ),
    );
  }

  /// Opens the Horse Profile Page
  void _gotoHorseHomePage({
    required BuildContext context,
    required String horseProfileId,
  }) {
    Navigator.of(context, rootNavigator: true).pushNamed(
      HomePage.routeName,
      arguments: HomePageArguments(
        usersProfile: state.usersProfile,
        horseId: horseProfileId,
        viewingProfile: state.viewingProfile,
      ),
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
  void horseProfileSelected({
    required String id,
  }) {
    emit(state.copyWith(index: 0, isForRider: false, horseId: id));
    _getHorseProfile(id: id);
    // Navigator.of(context, rootNavigator: true).pushNamed(
    //   HomePage.routeName,
    //   arguments: HomePageArguments(
    //     usersProfile: state.usersProfile,
    //     horseId: id,
    //     viewingProfile: state.viewingProfile,
    //   ),
    // );
  }

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
          emit(
            state.copyWith(
              horseProfile: horseProfile,
              horseId: horseProfile?.id,
              isForRider: false,
              isOwner:
                  state.usersProfile?.email == horseProfile?.currentOwnerId,
            ),
          );
        });
      } on FirebaseException catch (e) {
        debugPrint('Failed to get Horse Profile: $e');
        emit(state.copyWith(error: e.message.toString()));
      }
    }
  }

  bool isStudentHorse({required HorseProfile horseProfile}) {
    var isStudent = false;
    if (horseProfile.instructors != null) {
      for (final instructors in horseProfile.instructors!) {
        if (instructors.id == state.usersProfile?.email) {
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
    state.usersProfile?.studentHorses
        ?.removeWhere((element) => element.id == horseProfile.id);
    horseProfile.instructors
        ?.removeWhere((element) => element.id == state.usersProfile?.email);

    try {
      _horseProfileRepository.createOrUpdateHorseProfile(
        horseProfile: horseProfile,
      );
      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: state.usersProfile as RiderProfile,
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
    if (state.ownersProfile == null) {
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
    final memberNames = [state.usersProfile?.name, state.ownersProfile?.name]
        .map((e) => e as String)
        .toList();
    final memberIds = [state.usersProfile?.email, state.ownersProfile?.email]
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
      recipients: [state.usersProfile?.name, state.ownersProfile?.name]
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
          state.usersProfile?.email.toLowerCase() as String,
        ),
      )
      ..write(
        convertEmailToPath(
          state.ownersProfile?.email.toLowerCase() as String,
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

  /* *********************************************************************
                               Skill Tree Navigation 
  *************************************************************** */
  ///   SkillTree Tab Selected
  // void skillTreeNavigationSelected() {
  //   debugPrint('skillTreeNavigationSelected');
  //   sortSkills(allSkills: state.allSkills);
  //   sortSkillForDifficulty();
  //   emit(
  //     state.copyWith(
  //       index: 1,
  //       homeStatus: HomeStatus.skillTree,
  //       difficultyState: DifficultyState.all,
  //       skillTreeNavigation: SkillTreeNavigation.TrainingPath,
  //     ),
  //   );
  // }

  void navigateToTrainingPathList() {
    debugPrint('navigateToTrainingPathList');
    emit(
      state.copyWith(
        index: 1,
        homeStatus: HomeStatus.skillTree,
        isFromTrainingPath: false,
        isFromTrainingPathList: true,
        skillTreeNavigation: SkillTreeNavigation.TrainingPathList,
      ),
    );
  }

  void navigateToTrainingPath({required TrainingPath? trainingPath}) {
    debugPrint('navigateToTrainingPath ${trainingPath?.name}');
    emit(
      state.copyWith(
        isFromTrainingPath: true,
        trainingPath: trainingPath,
        isFromTrainingPathList: false,
        homeStatus: HomeStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.TrainingPath,
      ),
    );
  }

  void navigateToSkillsList() {
    debugPrint('navigateToSkillsList');
    emit(
      state.copyWith(
        index: 1,
        homeStatus: HomeStatus.skillTree,
        skillTreeNavigation: SkillTreeNavigation.SkillList,
        isFromTrainingPath: false,
        isFromTrainingPathList: false,
      ),
    );
  }

  void navigateToSkillLevel({
    required Skill? skill,
    required bool isSplitScreen,
  }) {
    debugPrint('navigateToSkillLevel for ${skill?.skillName}');
    if (!isSplitScreen) {
      emit(
        state.copyWith(
          index: 1,
          skill: skill,
          isSearch: false,
          homeStatus: HomeStatus.skillTree,
          skillTreeNavigation: SkillTreeNavigation.SkillLevel,
        ),
      );
    } else {
      emit(
        state.copyWith(
          skill: skill,
          skillTreeNavigation: SkillTreeNavigation.SkillLevel,
        ),
      );
    }
  }

/* ********************************************************
                          Search
 ***********************************************************/
  void closeSearch() {
    emit(state.copyWith(isSearch: false));
  }

  Future<void> search({required List<String?>? searchList}) async {
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

/* ****************************************************************
                          Training Paths
  ************************************************************** */
  Future<void> _getTrainingPaths() async {
    debugPrint('getTrainingPaths');
    _trainingPathsStream =
        _skillTreeRepository.getAllTrainingPaths().listen((event) {
      final trainingPaths =
          event.docs.map((doc) => (doc.data()) as TrainingPath?).toList();
      emit(state.copyWith(trainingPaths: trainingPaths));
    });
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

  /* **************************************************************
                          Skills
   *************************************************************/

  /// Calls the skills from the repository
  Future<void> getSkills() async {
    debugPrint('getSkills');
    final skills = TestSkills.generateTestSkills()
      ..sort((a, b) => a.position.compareTo(b.position));
    sortSkills(allSkills: skills);
    sortSkillForDifficulty();
    // _skillsStream= _skillTreeRepository.getSkills().listen((event) {
    //      final skills = event.docs.map((doc) => (doc.data()) as Skill?).toList();
    //   emit(state.copyWith(allSkills: skills));
    // });
  }

  void setFromSkills() {
    emit(
      state.copyWith(
        isFromTrainingPath: false,
        isFromTrainingPathList: false,
      ),
    );
  }

  List<Skill?>? getSkillsForResource({required List<String?>? ids}) {
    final skills = <Skill?>[];
    if (ids != null) {
      if (state.allSkills != null) {
        for (final skill in state.allSkills!) {
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

  void sortSkills({
    required List<Skill?>? allSkills,
  }) {
    final skills = <Skill>[];

    debugPrint('subcategory is null');
    //if subcategory is null we are going to return all the skills
    if (allSkills != null) {
      for (final skill in allSkills) {
        skills.add(skill!);
      }
      emit(
        state.copyWith(
          allSkills: allSkills,
          sortedSkills: _sortedSkillsForHorseOrRider(skills: skills),
        ),
      );
    } else {
      debugPrint('allSkills is null');
    }
  }

  void sortSkillForDifficulty() {
    final skills = state.sortedSkills;
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

  ///  Can Potenially get rid of this

  // void showTrainingSelectedPathsDialog(BuildContext context) {
  //   showDialog<AlertDialog>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: const Text('Training Paths'),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: state.trainingPaths
  //                 .map(
  //                   (trainingPath) => trainingPath != null
  //                       ? ListTile(
  //                           title: Text(trainingPath.name),
  //                           onTap: () {
  //                             trainingPathSelected(trainingPath: trainingPath);
  //                             Navigator.of(context).pop();
  //                           },
  //                         )
  //                       : Container(),
  //                 )
  //                 .toList(),
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

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
    var skills = <Skill?>[];
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
            skillTreeNavigation: SkillTreeNavigation.SkillList,
          ),
        );
      } else {
        emit(
          state.copyWith(
            sortedSkills: state.allSkills,
            difficultyState: difficultyState,
            skillTreeNavigation: SkillTreeNavigation.SkillList,
          ),
        );
      }
    } else {
      debugPrint('sorted skills is null');
    }
    emit(state.copyWith(difficultyState: difficultyState));
  }

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

  /// Sort skills by horse or rider
  List<Skill?>? _sortedSkillsForHorseOrRider({required List<Skill?>? skills}) {
    return state.isForRider
        ? skills?.where((element) => element?.rider ?? true == true).toList()
        : skills?.where((element) => element?.rider == false).toList();
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
                lastEditBy: state.usersProfile?.name,
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
        emit(
          state.copyWith(
            errorSnackBar: true,
            error: 'skill is null',
          ),
        );
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
              lastEditBy: state.usersProfile?.name,
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
  ///    Rider or Horse's profile
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
    if (state.viewingProfile != null) {
      return state.viewingProfile!;
    } else if (state.usersProfile != null) {
      return state.usersProfile!;
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
          '${state.usersProfile?.name} changed ${state.skill?.skillName} level to ${levelState.name} for ${state.viewingProfile?.name ?? 'themself'}';
    }
    return BaseListItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      name: noteMessage,
      parentId: state.usersProfile?.email,
      message: state.usersProfile?.name,
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
              lastEditBy: state.usersProfile?.name,
              lastEditDate: timestamp,
            ),
          ) ??
          SkillLevel(
            skillId: state.skill?.id,
            lastEditBy: state.usersProfile?.name,
            lastEditDate: timestamp,
          );

      riderProfile.skillLevels?.remove(skillLevel);
      riderProfile.skillLevels?.add(
        SkillLevel(
          skillId: state.skill?.id,
          levelState: levelState,
          lastEditBy: state.usersProfile?.name,
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
                  messageSnackBar: true,
                  message:
                      'Updated ${state.skill?.skillName} to ${levelState.name}',
                ),
              ),
            );
      } catch (error) {
        emit(
          state.copyWith(
            levelSubmissionStatus: LevelSubmissionStatus.initial,
            errorSnackBar: true,
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
      if (state.viewingProfile != null) {
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
    state.usersProfile != null
        ? showDialog<CreateResourcDialog>(
            context: context,
            builder: (context) => CreateResourcDialog(
              skills: state.allSkills,
              userProfile: state.usersProfile!,
              resource: resource,
            ),
          )
        : emit(
            state.copyWith(
              error: 'You Are Not Authorized To Edit Until Logged In',
              errorSnackBar: true,
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
    final sortedList = state.allResources;
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
    final sortedList = state.allResources;
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
    final sortedList = state.allResources;
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
    if (state.usersProfile != null) {
      if (state.usersProfile?.savedResourcesList != null) {
        if (state.resource != null) {
          for (final resource in state.allResources!) {
            if (state.usersProfile!.savedResourcesList!
                .contains(resource!.id)) {
              savedResources.add(resource);
            }
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
    final currentUserProfile = state.usersProfile;
    if (currentUserProfile != null) {
      List<String> savedResourcesList;
      if (currentUserProfile.savedResourcesList != null) {
        savedResourcesList =
            currentUserProfile.savedResourcesList as List<String>;
      } else {
        savedResourcesList = [];
      }

      if (!savedResourcesList.contains(resource.id)) {
        savedResourcesList.add(resource.id as String);
      } else {
        savedResourcesList.remove(resource.id);
      }
      currentUserProfile.savedResourcesList = savedResourcesList;

      _riderProfileRepository.createOrUpdateRiderProfile(
        riderProfile: currentUserProfile,
      );
    } else {
      // Handle the case where the user profile is not available
      debugPrint('User profile is not available');
      emit(
        state.copyWith(
          error: 'Unautherized to Edit Resources, Login or Create an account',
          errorSnackBar: true,
        ),
      );
    }
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
    final userEmail = state.usersProfile?.email as String;

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
  // TODO(mfrenchy): implement this
  void openResourceSkillTreeDialog({
    required BuildContext context,
    required Resource resource,
  }) {
    showDialog<AlertDialog>(
      context: context,
      builder: (context) => const AlertDialog(),
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
      debugPrint('Loading Banner Ad');
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
    } else {
      debugPrint('Not Loading Banner Ad');
    }
  }

  ///   Clear the snackbars
  void clearSnackBar() {
    emit(
      state.copyWith(
        errorSnackBar: false,
        snackBar: false,
        messageSnackBar: false,
        message: '',
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
    _trainingPathsStream.cancel();
    _riderProfileSubscription?.cancel();
    _horseProfileSubscription?.cancel();
    return super.close();
  }
}
