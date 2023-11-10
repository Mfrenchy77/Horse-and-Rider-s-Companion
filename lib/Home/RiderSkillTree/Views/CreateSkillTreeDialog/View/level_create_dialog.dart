// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/cubit/level_create_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class CreateLevelDialog extends StatelessWidget {
  const CreateLevelDialog({
    super.key,
    this.level,
    required this.isEdit,
    required bool isForRider,
    required Skill? skill,
    required String? userName,
    required int position,
  })  : _skill = skill,
        _isForRider = isForRider,
        _position = position,
        _userName = userName;
  final Level? level;
  final bool isEdit;
  final bool _isForRider;
  final Skill? _skill;
  final String? _userName;
  final int _position;
  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      create: (context) => SkillTreeRepository(),
      child: BlocProvider(
        create: (context) => CreateLevelDialogCubit(
          isForRider: _isForRider,
          levelsRepository: context.read<SkillTreeRepository>(),
          name: _userName,
          skill: _skill,
        ),
        child: BlocBuilder<CreateLevelDialogCubit, CreateLevelDialogState>(
          builder: (context, state) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  isEdit ? 'Edit: ${level?.levelName}' : 'Create New Level',
                ),
              ),
              body: AlertDialog(
                // backgroundColor: COLOR_CONST.DEFAULT_5,
                scrollable: true,
                //titleTextStyle: FONT_CONST.MEDIUM_WHITE,
                title: Text(
                  isEdit
                      ? 'Edit ${level?.levelName}'
                      : 'Create New Level For ${_skill?.skillName}',
                  style: const TextStyle(fontSize: 15),
                ),
                content: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Form(
                    child: Column(
                      children: [
                        ///   Level Name
                        TextFormField(
                          initialValue: isEdit ? level?.levelName : '',
                          textCapitalization: TextCapitalization.words,
                          maxLines: 3,
                          onChanged: (levelName) => context
                              .read<CreateLevelDialogCubit>()
                              .levelNameChanged(levelName),
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: isEdit ? 'Level Name' : 'New Level Name',
                            hintText: isEdit
                                ? 'Level Name'
                                : 'Enter a name for the new Level',
                            icon: const Icon(Icons.arrow_circle_up),
                          ),
                        ),

                        ///   Level Description
                        TextFormField(
                          initialValue: isEdit ? level?.description : '',
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 8,
                          minLines: 3,
                          onChanged: (levelDescription) => context
                              .read<CreateLevelDialogCubit>()
                              .levelDescriptionChanged(levelDescription),
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: isEdit
                                ? 'Level Description'
                                : 'New Level Description',
                            hintText: isEdit
                                ? 'Level Description'
                                : 'Enter a detailed description for the new Level',
                            icon: const Icon(Icons.arrow_circle_up),
                          ),
                        ),

                        ///  Learning  Description
                        TextFormField(
                          initialValue:
                              isEdit ? level?.learningDescription : '',
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 8,
                          minLines: 3,
                          onChanged: (skililDescription) => context
                              .read<CreateLevelDialogCubit>()
                              .levelLearningDescriptionChanged(
                                skililDescription,
                              ),
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: 'Learning Description',
                            hintText:
                                'Enter a detailed description for what it means to be learing ${_skill?.skillName}',
                            icon: const Icon(Icons.arrow_circle_up),
                          ),
                        ),

                        ///  Skill Complete Description
                        TextFormField(
                          initialValue:
                              isEdit ? level?.completeDescription : '',
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 8,
                          minLines: 3,
                          onChanged: (levelcomplete) => context
                              .read<CreateLevelDialogCubit>()
                              .levelCompleteDescriptionChanged(levelcomplete),
                          keyboardType: TextInputType.multiline,
                          decoration: InputDecoration(
                            border: const UnderlineInputBorder(),
                            labelText: 'Complete Description',
                            hintText:
                                'Enter a detailed description of what it mean to be complete with ${_skill?.skillName}',
                            icon: const Icon(Icons.arrow_circle_up),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  Row(
                    ///Delete
                    children: [
                      Expanded(
                        flex: 6,
                        child: Visibility(
                          visible: isEdit,
                          child: IconButton(
                            onPressed: () {
                              context
                                  .read<CreateLevelDialogCubit>()
                                  .deleteLevel(level: level as Level);
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.delete),
                          ),
                        ),
                      ),
                      if (state.status == FormzStatus.submissionInProgress)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                HorseAndRidersTheme().getTheme().primaryColor,
                          ),
                          onPressed:
                              // !state.status.isValid
                              //     ? null
                              //     :
                              () {
                            isEdit
                                ? context
                                    .read<CreateLevelDialogCubit>()
                                    .editLevel(level: level)
                                : context
                                    .read<CreateLevelDialogCubit>()
                                    .createLevel(_position);
                            Navigator.pop(context);
                          },
                          child: Text(
                            isEdit ? 'Submit Edited Level' : 'Submit',
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
