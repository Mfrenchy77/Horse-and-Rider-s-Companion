// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:database_repository/database_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:horseandriderscompanion/Home/Home/RidersLog/riders_log_view.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_page.dart';
import 'package:horseandriderscompanion/Home/RiderProfile/Views/add_horse_dialog.dart';
import 'package:horseandriderscompanion/Messages/view/messages_page.dart';
import 'package:horseandriderscompanion/utils/ad_helper.dart';
import 'package:horseandriderscompanion/utils/view_utils.dart';

part 'horse_profile_state.dart';

class HorseHomeCubit extends Cubit<HorseHomeState> {
  HorseHomeCubit({
    required this.isOwned,
    required MessagesRepository messagesRepository,
    required SkillTreeRepository skillTreeRepository,
    required HorseProfileRepository horseProfileRepository,
    required RiderProfileRepository riderProfileRepository,
    required this.horseId,
    required RiderProfile? usersProfile,
  })  : _usersProfile = usersProfile,
        _messagesRepository = messagesRepository,
        _skillTreeRepository = skillTreeRepository,
        _riderProfileRepository = riderProfileRepository,
        _horseProfileRepository = horseProfileRepository,
        super(const HorseHomeState()) {
    _horseProfileSubscription =
        _horseProfileRepository.getHorseProfile(id: horseId).listen((event) {
      _horseProfile = event.data() as HorseProfile?;
      emit(state.copyWith(horseProfile: _horseProfile));

      /// Check that the user is the Horses owner or not
      if (_horseProfile?.currentOwnerId != _usersProfile?.email) {
        _riderProfileRepository
            .getRiderProfile(email: _horseProfile?.currentOwnerId)
            .listen((event) {
          _ownersProfile = event.data() as RiderProfile;
          emit(
            state.copyWith(
              ownersProfile: _ownersProfile,
              usersProfile: _usersProfile,
            ),
          );
        });
      } else {
        _ownersProfile = _usersProfile;
        emit(
          state.copyWith(
            ownersProfile: _ownersProfile,
            usersProfile: _usersProfile,
          ),
        );
      }
    });

    ///   Stream of Categoies
    _categoryStream =
        _skillTreeRepository.getCatagoriesForHorseSkillTree().listen((event) {
      _categories =
          event.docs.map((doc) => (doc.data()) as Catagorry?).toList();
      if (state.horseHomePageStatus == HorseHomePageStatus.skillTree) {
        emit(
          state.copyWith(categories: _categories),
        );
      }
    });

    ///  Stream of SubCategories
    _subCategoryStream = _skillTreeRepository
        .getSubCategoriesForHorseSkillTree()
        .listen((event) {
      _subCategories =
          event.docs.map((e) => (e.data()) as SubCategory?).toList();
      debugPrint('Streaming SubCategories: ${_subCategories?.length}');
      if (state.horseHomePageStatus == HorseHomePageStatus.skillTree) {
        emit(
          state.copyWith(subCategories: _subCategories),
        );
      }
    });

    ///   Stream of Skills
    _skillsStream =
        _skillTreeRepository.getSkillsForHorseSkillTree().listen((event) {
      _skills = event.docs.map((e) => (e.data()) as Skill?).toList();

      if (state.horseHomePageStatus == HorseHomePageStatus.skillTree) {
        emit(
          state.copyWith(skills: _skills),
        );
      }
    });

    ///   Stream of Levels
    _levelsStream =
        _skillTreeRepository.getLevelsForHorseSkillTree().listen((event) {
      _levels = event.docs.map((e) => (e.data()) as Level?).toList();
      if (state.horseHomePageStatus == HorseHomePageStatus.skillTree) {
        emit(
          state.copyWith(levels: _levels),
        );
      }
    });

    /// Load Ads
    _loadBannerAds();
  }

  HorseProfile? _horseProfile;
  // final User _user;
  final RiderProfile? _usersProfile;
  RiderProfile? _ownersProfile;
  final RiderProfileRepository _riderProfileRepository;
  final HorseProfileRepository _horseProfileRepository;
  final String horseId;
  late final StreamSubscription<DocumentSnapshot<Object?>>
      _horseProfileSubscription;

  final MessagesRepository _messagesRepository;

  ///   Skill Tree
  ///
  ///   Categories
  //final CatagorryRepository _catgegoryRepository;
  final SkillTreeRepository _skillTreeRepository;
  late final StreamSubscription<QuerySnapshot<Object?>> _categoryStream;
  List<Catagorry?>? _categories;

  ///   SubCategories
  late final StreamSubscription<QuerySnapshot<Object?>> _subCategoryStream;
  List<SubCategory?>? _subCategories;

  ///   Skills
  // final SkillsRepository _skillsRepository;
  late final StreamSubscription<QuerySnapshot<Object?>> _skillsStream;
  List<Skill?>? _skills;

  ///   Levels
  // final LevelsRepository _levelsRepository;
  late final StreamSubscription<QuerySnapshot<Object?>> _levelsStream;
  List<Level?>? _levels;
  bool isOwned;

  /// Ads
  BannerAd? bannerAd;

/*          
                      Horse Profile
*/

  void horseProfileSelected() {
    emit(
      state.copyWith(
        index: 0,
        horseProfile: _horseProfile,
        horseHomePageStatus: HorseHomePageStatus.profile,
      ),
    );
  }

// TODO(mfrenchy77): change this to route to the home page but with viewing profile
  void openOwnersProfilePage({
    required BuildContext context,
    required String email,
  }) {
    if (email != state.ownersProfile?.email) {
      _riderProfileRepository.getRiderProfile(email: email).first.then((value) {
        Navigator.of(context, rootNavigator: true).pushNamed(
          HomePage.routeName,
          arguments: HomePageArguments(
            viewingProfile: value.data() as RiderProfile,
          ),
        );
      });
    } else {
      Navigator.of(context, rootNavigator: true).pushNamed(
        HomePage.routeName,
        arguments: HomePageArguments(
          viewingProfile: state.ownersProfile,
        ),
      );
    }
  }

// Open the Horse's Log Book
  void openHorseLogBook(BuildContext context) {
    showModalBottomSheet<LogView>(
      context: context,
      elevation: 20,
      builder: (context) =>
          LogView(horseState: state, isRider: false, state: null),
    );
  }

  // void menuItemSelected({
  //   required String choice,
  //   required BuildContext context,
  // }) {
  //   debugPrint('Menu Selection: $choice');
  //   switch (choice) {
  //     case 'Edit':
  //       showDialog<AddHorseDialog>(
  //         context: context,
  //         builder: (context) => AddHorseDialog(
  //           riderProfile: _ownersProfile,
  //           editProfile: true,
  //           horseProfile: _horseProfile,
  //         ),
  //       );
  //       break;
  //     case 'Delete':
  //       _deleteHorseProfileFromUser(
  //         horseProfile: _horseProfile as HorseProfile,
  //       );
  //       break;
  //     case 'Transfer':
  //       debugPrint('Transfer this dum horse!!');

  //       break;
  //   }
  // }

// method sends message request to the horses owner from the current user to add horse as
// a  studentHorse

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

  void requestToBeStudentHorse({
    required bool isStudentHorse,
    required BuildContext context,
    required HorseProfile horseProfile,
  }) {
    if (isStudentHorse) {
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
    } else {
      debugPrint('Request to add horse as student horse');
      final requestHorse = BaseListItem(
        id: horseProfile.id,
        name: horseProfile.name,
        imageUrl: horseProfile.picUrl,
        parentId: horseProfile.currentOwnerId,
        message: horseProfile.currentOwnerName,
        isCollapsed: false,
        isSelected: false,
      );

      if (_ownersProfile != null) {
        final id = StringBuffer()
          ..write(
            convertEmailToPath(
              state.usersProfile?.email?.toLowerCase() as String,
            ),
          )
          ..write(
            convertEmailToPath(
              state.ownersProfile?.email?.toLowerCase() as String,
            ),
          );
        final memberNames = <String>[
          state.usersProfile?.name as String,
          _ownersProfile?.name as String,
        ];
        final memberIds = <String>[
          state.usersProfile?.email?.toLowerCase() as String,
          _ownersProfile?.email?.toLowerCase() as String,
        ];
        debugPrint(
          'memberNames: $memberNames memberIds: $memberIds, Groupid: $id',
        );

        final message = Message(
          date: DateTime.now(),
          id: id.toString(),
          sender: state.usersProfile?.name as String,
          senderProfilePicUrl: state.usersProfile?.picUrl as String,
          messsageId: DateTime.now().millisecondsSinceEpoch.toString(),
          subject: 'Student Horse Request',
          message:
              '${state.usersProfile?.name as String} has requested to add ${horseProfile.name} as a student horse.',
          recipients: memberNames,
          messageType: MessageType.STUDENT_HORSE_REQUEST,
          requestItem: requestHorse,
        );
        final group = Group(
          id: id.toString(),
          type: GroupType.private,
          parties: memberNames,
          partiesIds: memberIds,
          createdBy: state.usersProfile?.name as String,
          createdOn: DateTime.now(),
          lastEditBy: state.usersProfile?.name as String,
          lastEditDate: DateTime.now(),
          recentMessage: message,
        );

        _messagesRepository
          ..createOrUpdateGroup(group: group)
          ..createOrUpdateMessage(message: message, id: message.messsageId);

//open messagespage
        Navigator.of(context, rootNavigator: true).restorablePushNamed(
          MessagesPage.routeName,
          arguments: MessageArguments(
            group: group,
            riderProfile: state.usersProfile,
          ),
        );
      } else {
        debugPrint('Something went Wrong, No owner profile found');
      }
    }
  }

  void editHorseProfile({
    required BuildContext context,
  }) {
    showDialog<AddHorseDialog>(
      context: context,
      builder: (context) => AddHorseDialog(
        riderProfile: _ownersProfile,
        editProfile: true,
        horseProfile: _horseProfile,
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

  ///   Add a Log Entry
  void addLogEntry({required BuildContext context}) {
    debugPrint('ADD LOG ENTRY, Yo!');
  }

/*
                    Skill Tree
 */

  ///   Called when we want to see the base of the skill tree
  void skillTreeSelected() {
    emit(
      state.copyWith(
        index: 1,
        horseHomePageStatus: HorseHomePageStatus.skillTree,
        status: SkillTreeStatus.categories,
        categories: _categories,
      ),
    );
  }

  void subCategorySelected({
    required SubCategory? subCategory,
  }) {
    List<Skill?>? subCategorySkills;
    if (_skills != null) {
      subCategorySkills = _skills
          ?.where(
            (element) => subCategory?.skills.contains(element?.id) ?? false,
          )
          .toList();
    }
    emit(
      state.copyWith(
        category: state.category,
        status: SkillTreeStatus.subCategories,
        subCategory: subCategory,
        skills: subCategorySkills,
      ),
    );
  }

  ///   Called when a Category is Selected and
  ///   we want to see it's associated SubCategories
  ///   Also, when we press back from Level State
  void categorySelected({required Catagorry? category}) {
    List<SubCategory?>? subCategories;
    if (_subCategories != null) {
      subCategories = _subCategories
          ?.where((element) => element?.parentId == category?.id)
          .toList();
    }

    emit(
      state.copyWith(
        status: SkillTreeStatus.subCategories,
        category: category,
        subCategories: subCategories,
      ),
    );
  }

  /// Called when a Skill is Selected and we
  ///   want to see it's associated Levels
  void skillSelected({
    required Skill skill,
    required Catagorry? category,
    required SubCategory? subCategory,
    required List<Skill?>? skills,
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
        categories: _categories,
        skills: skills,
        status: SkillTreeStatus.level,
        skill: skill,
        subCategory: subCategory,
        levels: skillLevels,
        category: category,
      ),
    );
  }

// a method that returns blue if skillLevel is verified and grey if it is not
  Color isVerified({required HorseProfile horseProfile, required Level level}) {
    var isVerified = false;
    if (horseProfile.skillLevels != null &&
        horseProfile.skillLevels!.isNotEmpty) {
      final skillLevel = horseProfile.skillLevels?.firstWhere(
        (element) => element.levelId == level.id,
        orElse: () => SkillLevel(
          levelId: level.id,
          lastEditBy: null,
          lastEditDate: level.lastEditDate,
        ),
      );
      if (skillLevel?.lastEditBy != null &&
          skillLevel?.lastEditBy != horseProfile.currentOwnerName) {
        isVerified = true;
      }
    }
    return isVerified ? Colors.yellow : Colors.grey;
  }

// A Method that returns a Color depending on the riders skilllevel and the level selected
// as well as if the level is verified or not

  Color isLevelUnlocked({
    required Level level,
    required LevelState levelState,
    required HorseProfile horseProfile,
  }) {
    var isVerified = false;
    if (horseProfile.skillLevels != null &&
        horseProfile.skillLevels!.isNotEmpty) {
      final skillLevel = horseProfile.skillLevels?.firstWhere(
        (element) => element.levelId == level.id,
        orElse: () => SkillLevel(
          levelId: level.id,
          lastEditBy: null,
          lastEditDate: level.lastEditDate,
        ),
      );

      if (skillLevel?.lastEditBy != null &&
          skillLevel?.lastEditBy != horseProfile.currentOwnerName) {
        isVerified = true;
      }

      if (skillLevel!.levelState.index == levelState.index) {
        return isVerified ? Colors.yellow : Colors.blue;
      }
    }
    return Colors.grey;
  }

  //    Called when a level is selectedd and we
  //    want to change the state of the SkillLevel in the
  //    Rider's profile or the Horse's profile

  void levelSelected({required Level level, required LevelState levelState}) {
    emit(state.copyWith(levelSubmitionStatus: LevelSubmitionStatus.submitting));
    if (state.horseProfile != null) {
      final note = BaseListItem(
        id: DateTime.now().toString(),
        date: DateTime.now(),
        name:
            "_${state.usersProfile?.name} changed ${state.horseProfile?.name}'s' ${level.levelName} level to ${levelState.name}",
        message: state.usersProfile?.name,
        parentId: state.usersProfile?.email,
      );

      final horseProfile = state.horseProfile as HorseProfile;
      final skillLevel = horseProfile.skillLevels?.firstWhere(
        (element) => element.levelId == level.id,
        orElse: () => SkillLevel(
          levelId: level.id,
          lastEditBy: level.lastEditBy,
          lastEditDate: level.lastEditDate,
        ),
      );
      // we want to remove the old skill level and add the new one
      horseProfile.skillLevels?.remove(skillLevel);
      horseProfile.skillLevels?.add(
        SkillLevel(
          levelId: level.id,
          levelState: levelState,
          lastEditBy: state.usersProfile?.name ?? '',
          lastEditDate: DateTime.now(),
        ),
      );
      _horseProfile?.notes?.add(note);
      _horseProfileRepository
          .createOrUpdateHorseProfile(
            horseProfile: horseProfile,
          )
          .then(
            (value) => emit(
              state.copyWith(
                horseProfile: horseProfile,
                levelSubmitionStatus: LevelSubmitionStatus.ititial,
              ),
            ),
          );
    } else {
      debugPrint('Horse Profile is Null can not update the skillLevel');
      emit(state.copyWith(levelSubmitionStatus: LevelSubmitionStatus.ititial));
    }
  }

  void toggleCategoryEdit({required bool isEdit}) {
    emit(
      state.copyWith(
        isEditState: isEdit,
        categories: _categories,
        levels: _levels,
        skills: _skills,
      ),
    );
  }

  void toogleSubCategoryEdit({required bool isEdit}) {
    emit(
      state.copyWith(
        isEditState: isEdit,
        subCategories: _subCategories,
      ),
    );
  }

  void toggleSkillsEdit({
    required bool isEdit,
    required Catagorry? category,
    required List<Skill?>? skills,
  }) {
    emit(
      state.copyWith(
        category: category,
        status: SkillTreeStatus.skill,
        isEditState: isEdit,
        categories: _categories,
        levels: _levels,
        skills: _skills,
      ),
    );
  }

  void toggleLevelsEdit({
    required bool isEdit,
    required Catagorry? category,
    required Skill? skill,
    List<Skill?>? skills,
    required List<Level?>? levels,
  }) {
    emit(
      state.copyWith(
        skill: skill,
        category: category,
        status: SkillTreeStatus.level,
        isEditState: isEdit,
        categories: _categories,
        levels: levels,
        skills: skills,
      ),
    );
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

  void clearSnackbar() {
    emit(state.copyWith(isSnackbar: false, message: ''));
  }

  void clearErrorSnackBar() {
    emit(state.copyWith(isErrorSnackBar: false, error: ''));
  }

  @override
  Future<void> close() {
    _skillsStream.cancel();
    _levelsStream.cancel();
    _categoryStream.cancel();
    _subCategoryStream.cancel();
    _horseProfileSubscription.cancel();
    return super.close();
  }
}
