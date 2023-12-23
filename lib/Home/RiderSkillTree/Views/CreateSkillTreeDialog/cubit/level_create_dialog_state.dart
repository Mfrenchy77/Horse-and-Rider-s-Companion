// part of './level_create_dialog_cubit.dart';

// class CreateLevelDialogState extends Equatable {
//   const CreateLevelDialogState({
//     this.learningDescription = '',
//     this.completeDescription = '',
//     this.status = FormzStatus.pure,
//     this.name = const SingleWord.pure(),
//     this.description = const SingleWord.pure(),
//   });

//   final SingleWord name;
//   final FormzStatus status;
//   final SingleWord description;
//   final String learningDescription;
//   final String completeDescription;

//   CreateLevelDialogState copyWith({
//     SingleWord? name,
//     FormzStatus? status,
//     SingleWord? description,
//     String? learningDescription,
//     String? completeDescription,
//   }) {
//     return CreateLevelDialogState(
//       name: name ?? this.name,
//       status: status ?? this.status,
//       description: description ?? this.description,
//       learningDescription: learningDescription ?? this.learningDescription,
//       completeDescription: completeDescription ?? this.completeDescription,
//     );
//   }

//   @override
//   List<Object> get props => [
//         name,
//         status,
//         description,
//         learningDescription,
//         completeDescription,
//       ];
// }
