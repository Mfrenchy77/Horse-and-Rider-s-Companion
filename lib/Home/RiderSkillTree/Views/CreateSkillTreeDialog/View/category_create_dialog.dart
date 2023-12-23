// // ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:formz/formz.dart';
// import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/cubit/category_create_dialog_cubit.dart';
// import 'package:horseandriderscompanion/Theme/theme.dart';

// class CreateCategoryDialog extends StatelessWidget {
//   const CreateCategoryDialog({
//     super.key,
//     this.category,
//     required this.isRider,
//     required this.isEdit,
//     required String userName,
//     required int position,
//   })  : _userName = userName,
//         _position = position;

//   final Catagorry? category;
//   final bool isEdit;
//   final bool isRider;
//   final String? _userName;
//   final int _position;

//   @override
//   Widget build(BuildContext context) {
//     String displayText;
//     if (isEdit) {
//       displayText = 'Edit ${category?.name}';
//     } else {
//       displayText = 'Create New Category';
//     }
//     return RepositoryProvider(
//       create: (context) => SkillTreeRepository(),
//       child: BlocProvider(
//         create: (context) => CreateCategoryDialogCubit(
//           isRider: isRider,
//           name: _userName,
//           catagorryRepository: context.read<SkillTreeRepository>(),
//           position: _position,
//         ),
//         child:
//             BlocBuilder<CreateCategoryDialogCubit, CreateCategoryDialogState>(
//           builder: (context, state) {
//             if (state.status == FormzStatus.submissionSuccess) {
//               Navigator.of(context).pop();
//             }
//             return Scaffold(
//               appBar: AppBar(
//                 title: Text(
//                   displayText,
//                 ),
//               ),
//               body: AlertDialog(
//                 //  backgroundColor: COLOR_CONST.DEFAULT_5,
//                 scrollable: true,
//                 // titleTextStyle: FONT_CONST.MEDIUM_WHITE,
//                 title: Text(
//                   displayText,
//                   style: const TextStyle(fontSize: 15),
//                 ),
//                 content: Padding(
//                   padding: const EdgeInsets.all(8),
//                   child: Form(
//                     child: Column(
//                       children: <Widget>[
//                         ///   Name
//                         TextFormField(
//                           initialValue: isEdit ? category?.name : '',
//                           textCapitalization: TextCapitalization.words,
//                           onChanged: (categoryName) => context
//                               .read<CreateCategoryDialogCubit>()
//                               .categoryNameChanged(categoryName),
//                           keyboardType: TextInputType.text,
//                           decoration: InputDecoration(
//                             border: const UnderlineInputBorder(),
//                             labelText: displayText,
//                             hintText: displayText,
//                             icon: const Icon(Icons.arrow_circle_up),
//                           ),
//                         ),

//                         ///   Description
//                         TextFormField(
//                           initialValue: isEdit ? category?.description : '',
//                           textCapitalization: TextCapitalization.sentences,
//                           maxLines: 8,
//                           minLines: 3,
//                           onChanged: (categoryDescription) => context
//                               .read<CreateCategoryDialogCubit>()
//                               .categoryDescriptionChanged(categoryDescription),
//                           keyboardType: TextInputType.multiline,
//                           decoration: InputDecoration(
//                             border: const UnderlineInputBorder(),
//                             labelText: isEdit
//                                 ? 'Category Description'
//                                 : 'New Category Description',
//                             hintText: isEdit
//                                 ? 'Category Description'
//                                 : 'Enter a detailed description for the new Category',
//                             icon: const Icon(Icons.arrow_circle_up),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//                 actions: [
//                   Row(
//                     children: [
//                       ///Delete
//                       Expanded(
//                         flex: 6,
//                         child: Visibility(
//                           visible: isEdit,
//                           child: IconButton(
//                             onPressed: () {
//                               context
//                                   .read<CreateCategoryDialogCubit>()
//                                   .deleteCategory(
//                                     category: category as Catagorry,
//                                   );
//                               Navigator.pop(context);
//                             },
//                             icon: const Icon(Icons.delete),
//                           ),
//                         ),
//                       ),
//                       if (state.status.isSubmissionInProgress)
//                         const CircularProgressIndicator()
//                       else
//                         ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor:
//                                 HorseAndRidersTheme().getTheme().primaryColor,
//                           ),
//                           onPressed:
//                               //  !state.status.isValid
//                               //     ? null
//                               //     :
//                               () {
//                             isEdit
//                                 ? context
//                                     .read<CreateCategoryDialogCubit>()
//                                     .editCategory(editedCategory: category)
//                                 : context
//                                     .read<CreateCategoryDialogCubit>()
//                                     .createCategory(_position);
//                             // Navigator.pop(context);
//                           },
//                           child: Text(isEdit ? 'Submit Edit' : 'Submit'),
//                         ),
//                     ],
//                   ),
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
