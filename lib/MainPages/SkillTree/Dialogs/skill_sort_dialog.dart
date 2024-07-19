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
          insetPadding: const EdgeInsets.all(8),
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
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<CategorySortState>(
                  segments: const [
                    ButtonSegment(
                      label: Text('All'),
                      value: CategorySortState.All,
                    ),
                    ButtonSegment(
                      label: Text('Husbandry'),
                      value: CategorySortState.Husbandry,
                    ),
                    ButtonSegment(
                      label: Text('In Hand'),
                      value: CategorySortState.In_Hand,
                    ),
                    ButtonSegment(
                      label: Text('Mounted'),
                      value: CategorySortState.Mounted,
                    ),
                  ],
                  selected: <CategorySortState>{
                    state.categorySortState,
                  },
                  onSelectionChanged: (p0) =>
                      cubit.categorySortChanged(p0.first),
                ),
              ),
              gap(),
              const Text(
                'Select Difficulty:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<DifficultySortState>(
                  segments: const [
                    ButtonSegment(
                      label: Text(
                        'All',
                      ),
                      value: DifficultySortState.All,
                    ),
                    ButtonSegment(
                      label: Text(
                        'Introductory',
                      ),
                      value: DifficultySortState.Introductory,
                    ),
                    ButtonSegment(
                      label: Text(
                        'Intermediate',
                      ),
                      value: DifficultySortState.Intermediate,
                    ),
                    ButtonSegment(
                      label: Text(
                        'Advanced',
                      ),
                      value: DifficultySortState.Advanced,
                    ),
                  ],
                  selected: <DifficultySortState>{
                    state.difficultySortState,
                  },
                  onSelectionChanged: (p0) =>
                      cubit.difficultySortChanged(p0.first),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
