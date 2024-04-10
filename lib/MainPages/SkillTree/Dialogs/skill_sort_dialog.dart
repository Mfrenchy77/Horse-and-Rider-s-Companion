import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

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
              child: const Text('Cancel'),
            ),
          ],
          title: const Text('Sort Skills'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Radio Buttons to select the skillTreeSortState
              RadioListTile<SkillTreeSortState>(
                title: const Text('All'),
                value: SkillTreeSortState.All,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<SkillTreeSortState>(
                title: const Text('Introductory'),
                value: SkillTreeSortState.Introductory,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<SkillTreeSortState>(
                title: const Text('Intermediate'),
                value: SkillTreeSortState.Intermediate,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile<SkillTreeSortState>(
                title: const Text('Advanced'),
                value: SkillTreeSortState.Advanced,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
              ),
              RadioListTile(
                value: SkillTreeSortState.Husbandry,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
                title: const Text('Husbandry'),
              ),
              RadioListTile(
                value: SkillTreeSortState.In_Hand,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
                title: const Text('In Hand'),
              ),
              RadioListTile(
                value: SkillTreeSortState.Mounted,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
                title: const Text('Mounted'),
              ),
              RadioListTile(
                value: SkillTreeSortState.Other,
                groupValue: state.skillTreeSortState,
                onChanged: (value) {
                  cubit.skillTreeSortChanged(value!);
                  Navigator.of(context).pop();
                },
                title: const Text('Other'),
              ),
            ],
          ),
        );
      },
    );
  }
}
