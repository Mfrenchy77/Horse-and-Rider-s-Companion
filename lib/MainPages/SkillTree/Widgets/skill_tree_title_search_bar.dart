import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/search_confimatio_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class SkillTreeSearchTitleBar extends StatelessWidget {
  const SkillTreeSearchTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        if (!state.isSearch) return const AppTitle();

        final isSkillList =
            state.skillTreeNavigation == SkillTreeNavigation.SkillList;
        final isTrainingPathList =
            state.skillTreeNavigation == SkillTreeNavigation.TrainingPathList;
        final hint = isSkillList ? 'Search Skills' : 'Search Resources';

        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue text) {
            return state.searchList.whereType<String>();
          },

          displayStringForOption: (s) => s,

          onSelected: (value) {
            cubit.toggleSearch();

            if (isSkillList) {
              cubit.navigateToSkillLevel(
                skill: state.allSkills.firstWhere(
                  (skill) => skill?.skillName == value,
                ),
              );
              return;
            }

            if (isTrainingPathList) {
              cubit.navigateToTrainingPath(
                trainingPath: state.trainingPaths.firstWhere(
                  (tp) => tp?.name == value,
                ),
              );
              return;
            }

            // SkillLevel: confirm add/remove resource
            final resource =
                state.resources.firstWhereOrNull((r) => r.name == value);
            final isLinked =
                resource?.skillTreeIds.contains(state.skill?.id) ?? false;

            showDialog<AlertDialog>(
              context: context,
              builder: (ctx) => searchConfirmationDialog(
                title: isLinked ? 'Remove' : 'Add',
                text: isLinked
                    ? 'Remove $value from ${state.skill?.skillName}'
                    : 'Add $value to ${state.skill?.skillName}',
                confirmTap: () {
                  if (resource != null) {
                    cubit
                      ..addResourceToSkill(
                        skill: state.skill,
                        resource: resource,
                      )
                      ..toggleSearch();
                  }
                  Navigator.pop(ctx);
                },
                cancelTap: () {
                  cubit.toggleSearch();
                  Navigator.pop(ctx);
                },
              ),
            );
          },

          // Same field UX/styling as Resources search
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
              onChanged: (query) {
                // Keep your existing per-mode query updates
                if (isSkillList) {
                  cubit.skillSearchQueryChanged(searchQuery: query);
                } else if (state.skillTreeNavigation ==
                    SkillTreeNavigation.SkillLevel) {
                  cubit.resourceSearchQueryChanged(searchQuery: query);
                } else {
                  cubit.trainingPathSearchQueryChanged(searchQuery: query);
                }
              },
              onSubmitted: (_) => onFieldSubmitted(),
              decoration: InputDecoration(
                filled: true,
                iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
                fillColor:
                    HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                hintText: hint,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  onPressed: () {
                    // toggle search state and if search is acitve,
                    // clear the search
                    if (state.isSearch) {
                      cubit.resetSkillSearchToAll();
                    }

                    cubit.toggleSearch();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                ),
              ),
            );
          },

          // Same suggestions overlay look as your Resources search
          optionsViewBuilder: (context, onSelected, options) {
            final theme = Theme.of(context);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 420, maxHeight: 320),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final opt = options.elementAt(index);
                      return InkWell(
                        onTap: () => onSelected(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(opt, style: theme.textTheme.bodyMedium),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
