import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/CommonWidgets/search_confimatio_dialog.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:searchfield/searchfield.dart';

class SkillTreeSearchTitleBar extends StatelessWidget {
  const SkillTreeSearchTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return state.isSearch
            ? SearchField<String>(
                autofocus: true,
                textInputAction: TextInputAction.search,
                // textCapitalization: TextCapitalization.words,
                onSubmit: (p0) {
                  debugPrint('Search: $p0');
                },
                suggestionState:
                    state.isSearch ? Suggestion.expand : Suggestion.hidden,
                inputType: TextInputType.name,
                hint: state.skillTreeNavigation == SkillTreeNavigation.SkillList
                    ? 'Search Skills'
                    : state.skillTreeNavigation ==
                            SkillTreeNavigation.SkillLevel
                        ? 'Search Resources'
                        : 'Search Training Paths',
                onSearchTextChanged: (query) {
                  state.skillTreeNavigation == SkillTreeNavigation.SkillList
                      ? cubit.skillSearchQueryChanged(searchQuery: query)
                      : state.skillTreeNavigation ==
                              SkillTreeNavigation.SkillLevel
                          ? cubit.resourceSearchQueryChanged(searchQuery: query)
                          : cubit.trainingPathSearchQueryChanged(
                              searchQuery: query,
                            );
                  return state.searchList
                      .map(
                        (e) => SearchFieldListItem<String>(
                          e ?? '',
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(e ?? ''),
                          ),
                        ),
                      )
                      .toList();
                },
                searchInputDecoration: SearchInputDecoration(
                  filled: true,
                  textCapitalization: TextCapitalization.words,
                  iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
                  fillColor:
                      HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                  suffixIcon: IconButton(
                    onPressed: cubit.toggleSearch,
                    icon: const Icon(Icons.clear),
                  ),
                  hintText:
                      state.skillTreeNavigation == SkillTreeNavigation.SkillList
                          ? 'Search Skills'
                          : 'Search Resources',
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(40)),
                  ),
                ),
                suggestions: state.searchList
                    .map(
                      (e) => SearchFieldListItem<String>(
                        e ?? '',
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(e ?? ''),
                        ),
                      ),
                    )
                    .toList(),
                onSuggestionTap: (value) {
                  cubit.toggleSearch();
                  state.skillTreeNavigation == SkillTreeNavigation.SkillList
                      ? cubit.navigateToSkillLevel(
                          skill: state.allSkills.firstWhere(
                            (skill) => skill?.skillName == value.searchKey,
                          ),
                        )
                      : state.skillTreeNavigation ==
                              SkillTreeNavigation.TrainingPathList
                          ? cubit.navigateToTrainingPath(
                              trainingPath: state.trainingPaths.firstWhere(
                                (element) => element?.name == value.item,
                              ),
                            )
                          : showDialog<AlertDialog>(
                              context: context,
                              builder: (context) => searchConfirmationDialog(
                                title: (state.resources
                                            .firstWhereOrNull(
                                              (resource) =>
                                                  resource.name ==
                                                  value.searchKey,
                                            )
                                            ?.skillTreeIds
                                            ?.contains(state.skill?.id) ??
                                        false)
                                    ? 'Remove'
                                    : 'Add',
                                text: (state.resources
                                            .firstWhereOrNull(
                                              (resource) =>
                                                  resource.name ==
                                                  value.searchKey,
                                            )
                                            ?.skillTreeIds
                                            ?.contains(state.skill?.id) ??
                                        false)
                                    ? 'Remove ${value.searchKey} from '
                                        '${state.skill?.skillName}'
                                    : 'Add ${value.searchKey} to '
                                        '${state.skill?.skillName}',
                                confirmTap: () {
                                  cubit
                                    ..addResourceToSkill(
                                      skill: state.skill,
                                      resource: state.resources.firstWhere(
                                        (resource) =>
                                            resource.name == value.searchKey,
                                      ),
                                    )
                                    ..toggleSearch();
                                  Navigator.pop(context);
                                },
                                cancelTap: () {
                                  cubit.toggleSearch();
                                  Navigator.pop(context);
                                },
                              ),
                            );
                },
              )
            : const AppTitle();
      },
    );
  }
}
