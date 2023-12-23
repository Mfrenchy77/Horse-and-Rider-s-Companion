// // ignore_for_file: cast_nullable_to_non_nullable

// import 'package:bloc/bloc.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/material.dart';
// import 'package:form_inputs/form_inputs.dart';
// import 'package:formz/formz.dart';
// import 'package:horseandriderscompanion/utils/view_utils.dart';

// part 'level_create_dialog_state.dart';

// class CreateLevelDialogCubit extends Cubit<CreateLevelDialogState> {
//   CreateLevelDialogCubit({
//     required bool isForRider,
//     required String? name,
//     required SkillTreeRepository levelsRepository,
//     required Skill? skill,
//   })  : _isForRider = isForRider,
//         _levelsRepository = levelsRepository,
//         _name = name,
//         _skill = skill,
//         super(const CreateLevelDialogState());

//   final bool _isForRider;
//   final Skill? _skill;
//   final String? _name;
//   final SkillTreeRepository _levelsRepository;

//   void levelNameChanged(String value) {
//     final name = SingleWord.dirty(value);
//     emit(state.copyWith(name: name, status: Formz.validate([name])));
//   }

//   void levelDescriptionChanged(String value) {
//     final description = SingleWord.dirty(value);
//     emit(
//       state.copyWith(
//         description: description,
//         status: Formz.validate([description]),
//       ),
//     );
//   }

//   void levelLearningDescriptionChanged(String value) {
//     emit(state.copyWith(learningDescription: value));
//   }

//   void levelCompleteDescriptionChanged(String value) {
//     emit(state.copyWith(completeDescription: value));
//   }

//   Future<void> createLevel(int position) async {
//     emit(state.copyWith(status: FormzStatus.submissionInProgress));

//     final level = Level(
//       id: ViewUtils.createId(),
//       levelName: state.name.value,
//       skillId: _skill?.id,
//       description: state.description.value,
//       learningDescription: state.learningDescription,
//       completeDescription: state.completeDescription,
//       level: 0,
//       position: position,
//       rider: _isForRider,
//       lastEditBy: _name,
//       lastEditDate: DateTime.now(),
//       // levelState: LevelStates.NO_PROGRESS,
//     );

//     try {
//      await _levelsRepository.createOrEditLevel(level: level);
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(state.copyWith(status: FormzStatus.submissionFailure));
//     }
//   }

//   void deleteLevel({required Level level}) {
//     emit(
//       state.copyWith(status: FormzStatus.submissionInProgress),
//     );
//     try {
//       _levelsRepository.deleteLevel(
//         level: level,
//       );
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(
//         state.copyWith(status: FormzStatus.submissionFailure),
//       );
//     }
//   }

//   Future<void> editLevel({Level? level}) async {
//     emit(
//       state.copyWith(status: FormzStatus.submissionInProgress),
//     );
//     final editedLevel = Level(
//       id: level?.id,
//       levelName:
//           state.name.value.isNotEmpty ? state.name.value : level?.levelName,
//       skillId: level?.skillId,
//       description: state.description.value.isNotEmpty
//           ? state.description.value
//           : level?.description,
//       learningDescription: state.learningDescription.isNotEmpty
//           ? state.learningDescription
//           : level?.learningDescription,
//       completeDescription: state.completeDescription.isNotEmpty
//           ? state.completeDescription
//           : level?.completeDescription,
//       level: level?.level,
//       position: level?.position as int,
//       rider: level?.rider,
//       lastEditBy: _name,
//       lastEditDate: DateTime.now(),
//       // levelState: level?.levelState,
//     );
//     try {
//     await  _levelsRepository.createOrEditLevel(level: editedLevel);
//       emit(state.copyWith(status: FormzStatus.submissionSuccess));
//     } catch (e) {
//       debugPrint(e.toString());
//       emit(
//         state.copyWith(status: FormzStatus.submissionFailure),
//       );
//     }
//   }
// }
