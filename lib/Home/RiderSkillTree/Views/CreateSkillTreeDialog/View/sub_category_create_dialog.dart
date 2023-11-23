import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:formz/formz.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/Home/RiderSkillTree/Views/CreateSkillTreeDialog/cubit/sub_category_create_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

///   This is the Dialog that is used to create a new SubCategory
/// or edit an existing SubCategory
class CreateSubCategoryDialog extends StatelessWidget {
  const CreateSubCategoryDialog({
    super.key,
    required this.subCategory,
    required this.isEdit,
    required Catagorry? category,
    required List<Skill?>? skills,
    required int position,
    required this.isRider,
  })  : _category = category,
        _position = position,
        _skills = skills;

  final SubCategory? subCategory;
  final bool isEdit;
  final Catagorry? _category;
  final List<Skill?>? _skills;
  final int _position;
  final bool isRider;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SubCategoryCreateDialogCubit,
        SubCategoryCreateDialogState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              isEdit
                  ? 'Edit ${subCategory?.name} for ${_category?.name}'
                  : 'Create New SubCategory for ${_category?.name}',
            ),
          ),
          body: AlertDialog(
            scrollable: true,
            title: Text(
              isEdit
                  ? 'Edit ${subCategory?.name} for ${_category?.name}'
                  : 'Create New SubCategory for ${_category?.name}',
              style: const TextStyle(fontSize: 15),
            ),
            content: Padding(
              padding: const EdgeInsets.all(8),
              child: Form(
                child: Column(
                  children: <Widget>[
                    ///   Name
                    TextFormField(
                      textCapitalization: TextCapitalization.words,
                      initialValue: isEdit ? subCategory?.name : '',
                      decoration: const InputDecoration(
                        labelText: 'Name',
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (value) => context
                          .read<SubCategoryCreateDialogCubit>()
                          .subCategoryNameChanged(value),
                    ),

                    ///   Description
                    TextFormField(
                      textCapitalization: TextCapitalization.sentences,
                      initialValue: isEdit ? subCategory?.description : '',
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: UnderlineInputBorder(),
                      ),
                      onChanged: (value) => context
                          .read<SubCategoryCreateDialogCubit>()
                          .subCategoryDescriptionChanged(value),
                    ),

                    ///   Skills picked from filter chips
                    if (_skills != null)
                      Column(
                        children: [
                          const Text(
                            'Choose the skills for this sub-category',
                          ),
                          Wrap(
                            spacing: 8,
                            children: _skills?.map(
                                  (Skill? skill) {
                                    return FilterChip(
                                      label: Text(skill?.skillName ?? ''),
                                      selected: subCategory != null
                                          ? subCategory!.skills
                                              .contains(skill?.id)
                                          : state.skills.contains(skill?.id),
                                      onSelected: (value) => context
                                          .read<SubCategoryCreateDialogCubit>()
                                          .subCategorySkillsChanged(
                                            skill?.id,
                                          ),
                                    );
                                  },
                                ).toList() ??
                                [const Text('No Skills Found')],
                          ),
                        ],
                      )
                    else
                      const Text('No Skills Found'),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                children: [
                  //Delete Button
                  Expanded(
                    flex: 5,
                    child: Visibility(
                      visible: isEdit,
                      child: IconButton(
                        onPressed: () {
                          context
                              .read<SubCategoryCreateDialogCubit>()
                              .deleteSubCategory(
                                subCategory: subCategory!,
                              );
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete),
                      ),
                    ),
                  ),
                  gap(),

                  //Cancel Button
                  Expanded(
                    flex: 5,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            HorseAndRidersTheme().getTheme().primaryColor,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                  gap(),

                  //Submit Button
                  if (state.status.isSubmissionInProgress)
                    const Expanded(
                      flex: 7,
                      child: CircularProgressIndicator(),
                    )
                  else
                    Expanded(
                      flex: 7,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              HorseAndRidersTheme().getTheme().primaryColor,
                        ),
                        onPressed: () {
                          isEdit
                              ? context
                                  .read<SubCategoryCreateDialogCubit>()
                                  .editSubCategory()
                              : context
                                  .read<SubCategoryCreateDialogCubit>()
                                  .createSubCategory(
                                    _position,
                                  );
                          Navigator.pop(context);
                        },
                        child: Text(
                          isEdit ? 'Submit Edited SubCategory' : 'Submit',
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
