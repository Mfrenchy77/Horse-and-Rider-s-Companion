import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skills_list_view.dart';

class SkillTreeSecondaryView extends StatelessWidget {
  const SkillTreeSecondaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        switch (state.skillTreeNavigation) {
          case SkillTreeNavigation.SkillList:
          case SkillTreeNavigation.SkillLevel:
            return const SkillsListView(key: Key('SkillsListView'));
        }
      },
    );
  }
}
