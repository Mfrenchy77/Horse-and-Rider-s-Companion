import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'skill_tree_state.dart';

class SkillTreeCubit extends Cubit<SkillTreeState> {
  SkillTreeCubit({
    required bool isGuest,
    required bool isViewing,
    required bool isForRider,
  }) : super(const SkillTreeState()) {
    emit(
      state.copyWith(
        isGuest: isGuest,
        isViewing: isViewing,
        isForRider: isForRider,
      ),
    );
  }
}
