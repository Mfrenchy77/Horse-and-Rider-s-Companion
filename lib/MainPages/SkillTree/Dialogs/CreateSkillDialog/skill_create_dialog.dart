// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/Cubit/skill_create_dialog_cubit.dart';


class CreateSkillDialog extends StatelessWidget {
  const CreateSkillDialog({
    super.key,
    this.skill,
    required this.isEdit,
    required this.isRider,
    required int position,
    required String? userName,
   // required List<SubCategory?>? allSubCategories,
  })  : _userName = userName,
        _position = position;
       // _allSubCategories = allSubCategories;

  final bool isEdit;
  final Skill? skill;
  final bool isRider;
  final int _position;
  final String? _userName;
 // final List<SubCategory?>? _allSubCategories;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SkillTreeRepository(),
      child: BlocProvider(
        create: (context) => CreateSkillDialogCubit(
          skill: skill,
          name: _userName,
          isForRider: isRider,
         // allSubCategories: _allSubCategories,
          skillsRepository: context.read<SkillTreeRepository>(),
        ),
        child: BlocListener<CreateSkillDialogCubit, CreateSkillDialogState>(
          listener: (context, state) {
            if (state.status.isSubmissionSuccess) {
              Navigator.pop(context);
            }
            if (state.status.isSubmissionFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Submission Failure'),
                  ),
                );
            }
            if (state.updateSubCategoryList == UpdateSubCategoryList.error) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  const SnackBar(
                    content: Text('Error Updating SubCategory List'),
                  ),
                );
            }
          },
          child: BlocBuilder<CreateSkillDialogCubit, CreateSkillDialogState>(
            builder: (context, state) {
              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    isEdit ? 'Edit ${skill?.skillName}' : 'Create New Skill',
                  ),
                ),
                body: AlertDialog(
                  scrollable: true,
                  title: Text(
                    isEdit ? 'Edit ${skill?.skillName}' : 'Create New Skill',
                    style: const TextStyle(fontSize: 15),
                  ),
                  content: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Form(
                      child: Column(
                        children: <Widget>[
                          ///   Name
                          TextFormField(
                            initialValue: isEdit ? skill?.skillName : '',
                            textCapitalization: TextCapitalization.words,
                            onChanged: (categoryName) => context
                                .read<CreateSkillDialogCubit>()
                                .skillNameChanged(categoryName),
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText:
                                  isEdit ? 'Skill Name' : 'New Skill Name',
                              hintText: 'Enter a name for the new Skill',
                              icon: const Icon(Icons.arrow_circle_up),
                            ),
                          ),

                          ///   Description
                          TextFormField(
                            initialValue: isEdit ? skill?.description : '',
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 8,
                            minLines: 3,
                            onChanged: (skillDescription) => context
                                .read<CreateSkillDialogCubit>()
                                .skillDescriptionChanged(skillDescription),
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText: isEdit
                                  ? 'Skill Description'
                                  : 'New Skill Description',
                              hintText:
                                  'Enter a detailed description for the new Skill',
                              icon: const Icon(Icons.arrow_circle_up),
                            ),
                          ),
                          smallGap(),

                          ///   Learning Description
                          TextFormField(
                            initialValue:
                                isEdit ? skill?.learningDescription : '',
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 8,
                            minLines: 3,
                            onChanged: (learningDescription) => context
                                .read<CreateSkillDialogCubit>()
                                .skillLearningDescriptionChanged(
                                  learningDescription,
                                ),
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText: isEdit
                                  ? 'Learning Description'
                                  : 'New Learning Description',
                              hintText:
                                  'Describe what should be it means to be learning ${state.name.value}',
                              icon: const Icon(Icons.arrow_circle_up),
                            ),
                          ),
                          smallGap(),

                          ///   Proficient Description
                          TextFormField(
                            initialValue:
                                isEdit ? skill?.proficientDescription : '',
                            textCapitalization: TextCapitalization.sentences,
                            maxLines: 8,
                            minLines: 3,
                            onChanged: (proficientDescription) => context
                                .read<CreateSkillDialogCubit>()
                                .skillProficientDescriptionChanged(
                                  proficientDescription,
                                ),
                            keyboardType: TextInputType.multiline,
                            decoration: InputDecoration(
                              border: const UnderlineInputBorder(),
                              labelText: isEdit
                                  ? 'Proficient Description'
                                  : 'New Proficient Description',
                              hintText:
                                  'Describe what it means to be proficient at ${state.name.value}',
                              icon: const Icon(Icons.arrow_circle_up),
                            ),
                          ),

                          ///   Difficulty radio buttons
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Introductory'),
                                    smallGap(),
                                    Radio(
                                      value: DifficultyState.introductory,
                                      groupValue: state.difficulty,
                                      onChanged: (value) => context
                                          .read<CreateSkillDialogCubit>()
                                          .skillDifficultyChanged(value!),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Intermediate'),
                                    smallGap(),
                                    Radio(
                                      value: DifficultyState.intermediate,
                                      groupValue: state.difficulty,
                                      onChanged: (difficulty) => context
                                          .read<CreateSkillDialogCubit>()
                                          .skillDifficultyChanged(difficulty!),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    const Text('Advanced'),
                                    smallGap(),
                                    Radio(
                                      value: DifficultyState.advanced,
                                      groupValue: state.difficulty,
                                      onChanged: (difficulty) => context
                                          .read<CreateSkillDialogCubit>()
                                          .skillDifficultyChanged(difficulty!),
                                    ),
                                  ],
                                ),
                              ),
                              Visibility(
                                visible: state.updateSubCategoryList ==
                                    UpdateSubCategoryList.inProgress,
                                child: const CircularProgressIndicator(),
                              ),
                            ],
                          ),
                          smallGap(),

                          /// Filter chips of all the SubCategories,
                          ///  set selected if the skill is in that subcategory
                          /// and the user can select or deselect the subcategory
                          if (state.allSubCategories != null)
                            Wrap(
                              spacing: 5,
                              children: [
                                for (final subCategory
                                    in state.allSubCategories!)
                                  FilterChip(
                                    selected: state.subCategoryList
                                            ?.contains(subCategory) ??
                                        false,
                                    label: Text(subCategory?.name ?? ''),
                                    onSelected: (selected) {
                                      context
                                          .read<CreateSkillDialogCubit>()
                                          .updateSubCategoryList(
                                            subCategory: subCategory!,
                                          );
                                    },
                                  ),
                              ],
                            )
                          else
                            const Text('No Subcategories'),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    Row(
                      children: [
                        ///Delete
                        Expanded(
                          flex: 6,
                          child: Visibility(
                            visible: isEdit,
                            child: IconButton(
                              onPressed: () {
                                context
                                    .read<CreateSkillDialogCubit>()
                                    .deleteSkill(skill: skill as Skill);
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ),
                        ),

                        if (state.status.isSubmissionInProgress)
                          const CircularProgressIndicator()
                        else
                          FilledButton(
                            onPressed: state.name.value.isEmpty
                                ? null
                                : () {
                                    isEdit
                                        ? context
                                            .read<CreateSkillDialogCubit>()
                                            .editSkill(editedSkill: skill)
                                        : context
                                            .read<CreateSkillDialogCubit>()
                                            .createSkill(_position);
                                  },
                            child:
                                Text(isEdit ? 'Submit Edited Skill' : 'Submit'),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
