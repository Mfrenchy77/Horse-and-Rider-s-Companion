part of 'sub_category_create_dialog_cubit.dart';

class SubCategoryCreateDialogState extends Equatable {
  const SubCategoryCreateDialogState({
    this.skills = const [],
    this.status = FormzStatus.pure,
    this.name = const SingleWord.pure(),
    this.description = const SingleWord.pure(),
  });

  final SingleWord name;
  final FormzStatus status;
  final List<String> skills;
  final SingleWord description;

  SubCategoryCreateDialogState copyWith({
    SingleWord? name,
    FormzStatus? status,
    List<String>? skills,
    SingleWord? description,
  }) {
    return SubCategoryCreateDialogState(
      name: name ?? this.name,
      skills: skills ?? this.skills,
      status: status ?? this.status,
      description: description ?? this.description,
    );
  }

  @override
  List<Object?> get props => [
        name,
        status,
        skills,
        description,
      ];
}
