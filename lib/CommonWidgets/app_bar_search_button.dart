import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

class AppBarSearchButton extends StatelessWidget {
  const AppBarSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Visibility(
          visible: !state.isSearch,
          child: Tooltip(
            message: _searchText(state),
            child: IconButton(
              icon: const Icon(Icons.search),
              onPressed: cubit.search,
            ),
          ),
        );
      },
    );
  }
}

String _searchText(AppState state) {
  return state.pageStatus == AppPageStatus.resource
      ? 'Search Resources'
      : state.skillTreeNavigation == SkillTreeNavigation.SkillList
          ? 'Search Skills'
          : state.skillTreeNavigation == SkillTreeNavigation.TrainingPathList
              ? 'Search Training Paths'
              : 'Search Resources';
}
