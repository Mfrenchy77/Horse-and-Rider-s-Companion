import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

///  This dialog is used to sort the skills in the Skill Tree List
class SkillSortDialog extends StatelessWidget {
  const SkillSortDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        return AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
          title: const Text('Sort Skills'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Select Category:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              RadioListTile<CategorySortState>(
                title: const Text('All'),
                value: CategorySortState.All,
                groupValue: state.categorySortState,
                onChanged: (value) {
                  cubit.categorySortChanged(value!);
                },
              ),
              RadioListTile<CategorySortState>(
                title: const Text('Husbandry'),
                value: CategorySortState.Husbandry,
                groupValue: state.categorySortState,
                onChanged: (value) {
                  cubit.categorySortChanged(value!);
                },
              ),
              RadioListTile<CategorySortState>(
                title: const Text('In Hand'),
                value: CategorySortState.In_Hand,
                groupValue: state.categorySortState,
                onChanged: (value) {
                  cubit.categorySortChanged(value!);
                },
              ),
              RadioListTile<CategorySortState>(
                title: const Text('Mounted'),
                value: CategorySortState.Mounted,
                groupValue: state.categorySortState,
                onChanged: (value) {
                  cubit.categorySortChanged(value!);
                },
              ),
              RadioListTile<CategorySortState>(
                title: const Text('Other'),
                value: CategorySortState.Other,
                groupValue: state.categorySortState,
                onChanged: (value) {
                  cubit.categorySortChanged(value!);
                },
              ),
              gap(), //bold text
              const Text(
                'Select Difficulty:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              RadioListTile<DifficultySortState>(
                title: const Text('All'),
                value: DifficultySortState.All,
                groupValue: state.difficultySortState,
                onChanged: (value) {
                  cubit.difficultySortChanged(value!);
                },
              ),
              RadioListTile<DifficultySortState>(
                title: const Text('Introductory'),
                value: DifficultySortState.Introductory,
                groupValue: state.difficultySortState,
                onChanged: (value) {
                  cubit.difficultySortChanged(value!);
                },
              ),
              RadioListTile<DifficultySortState>(
                title: const Text('Intermediate'),
                value: DifficultySortState.Intermediate,
                groupValue: state.difficultySortState,
                onChanged: (value) {
                  cubit.difficultySortChanged(value!);
                },
              ),
              RadioListTile<DifficultySortState>(
                title: const Text('Advanced'),
                value: DifficultySortState.Advanced,
                groupValue: state.difficultySortState,
                onChanged: (value) {
                  cubit.difficultySortChanged(value!);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
