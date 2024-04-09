// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateSkillDialog/Cubit/skill_create_dialog_cubit.dart';

class CreateSkillDialog extends StatelessWidget {
  const CreateSkillDialog({
    super.key,
    this.skill,
    required this.isEdit,
    required this.isForRider,
    required int position,
    required RiderProfile usersProfile,
  })  : _position = position,
        _usersProfile = usersProfile;

  final bool isEdit;
  final Skill? skill;
  final bool isForRider;
  final int _position;
  final RiderProfile _usersProfile;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SkillTreeRepository(),
      child: BlocProvider(
        create: (context) => CreateSkillDialogCubit(
          skill: skill,
          isForRider: isForRider,
          usersProfile: _usersProfile,
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
              final cubit = context.read<CreateSkillDialogCubit>();
              return AlertDialog(
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
                          onChanged: cubit.skillNameChanged,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: isEdit ? 'Skill Name' : 'New Skill Name',
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
                          onChanged: cubit.skillDescriptionChanged,
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
                          onChanged: cubit.skillLearningDescriptionChanged,
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
                          onChanged: cubit.skillProficientDescriptionChanged,
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
                        smallGap(),
                        // Is for Horse/Rider
                        const Center(
                          child: Text('Rider or Horse'),
                        ),
                        SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                              value: true,
                              label: Text(
                                'Rider',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: false,
                              label: Text(
                                'Horse',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          selected: <bool>{
                            state.isForRider,
                          },
                          onSelectionChanged: (value) {
                            debugPrint('Rider or Horse: $value');
                            cubit.isForRiderChanged(isForRider: value.first);
                          },
                        ),
                        // Difficulty
                        const Center(
                          child: Text('Difficulty'),
                        ),
                        SegmentedButton<DifficultyState>(
                          segments: const [
                            ButtonSegment(
                              value: DifficultyState.Introductory,
                              label: Text(
                                'Introductory',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: DifficultyState.Intermediate,
                              label: Text(
                                'Intermediate',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: DifficultyState.Advanced,
                              label: Text(
                                'Advanced',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          selected: <DifficultyState>{
                            state.difficulty,
                          },
                          onSelectionChanged: (value) {
                            debugPrint('Difficulty: $value');
                            cubit.skillDifficultyChanged(value.first);
                          },
                        ),

                        smallGap(),

                        // Category
                        const Center(
                          child: Text('Category'),
                        ),
                        SegmentedButton<SkillCategory>(
                          segments: const [
                            ButtonSegment(
                              value: SkillCategory.Mounted,
                              label: Text(
                                'Mounted',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: SkillCategory.In_Hand,
                              label: Text(
                                'In Hand',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: SkillCategory.Husbandry,
                              label: Text(
                                'Husbandry',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            ButtonSegment(
                              value: SkillCategory.Other,
                              label: Text(
                                'Other',
                                overflow: TextOverflow.visible,
                                style: TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          selected: <SkillCategory>{
                            state.category,
                          },
                          onSelectionChanged: (value) {
                            debugPrint('Category: $value');
                            cubit.skillCategoryChanged(value.first);
                          },
                        ),

                        /// Filter chips of all the SubCategories,
                        ///  set selected if the skill is in that subcategory
                        /// and the user can select or deselect the subcategory
                      ],
                    ),
                  ),
                ),
                actions: [
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => context.pop(),
                        child: const Text('Cancel'),
                      ),

                      ///Delete
                      Visibility(
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
              );
            },
          ),
        ),
      ),
    );
  }
}
