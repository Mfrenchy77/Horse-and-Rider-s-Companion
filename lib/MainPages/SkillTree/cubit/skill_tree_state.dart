part of 'skill_tree_cubit.dart';

class SkillTreeState extends Equatable {
  const SkillTreeState({
    this.isGuest = false,
    this.isViewing = false,
    this.isForRider = false,
  });
  final bool isGuest;
  final bool isForRider;
  final bool isViewing;

  SkillTreeState copyWith({
    bool? isGuest,
    bool? isViewing,
    bool? isForRider,
  }) {
    return SkillTreeState(
      isGuest: isGuest ?? this.isGuest,
      isViewing: isViewing ?? this.isViewing,
      isForRider: isForRider ?? this.isForRider,
    );
  }

  @override
  List<Object> get props => [
        isGuest,
        isViewing,
        isForRider,
      ];
}
