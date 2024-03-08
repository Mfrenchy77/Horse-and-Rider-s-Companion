import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:searchfield/searchfield.dart';

class ResourcesSearchTitle extends StatelessWidget {
  const ResourcesSearchTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return state.isSearch
            ? SearchField<String>(
                autofocus: true,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.sentences,
                inputType: TextInputType.text,
                hint: 'Search Resources',
                onSearchTextChanged: (query) {
                  cubit.resourceSearchQueryChanged(searchQuery: query);
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
                searchInputDecoration: InputDecoration(
                  filled: true,
                  iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
                  fillColor:
                      HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                  suffixIcon: IconButton(
                    onPressed: cubit.toggleSearch,
                    icon: const Icon(Icons.clear),
                  ),
                  hintText: 'Search Resources',
                  border: const OutlineInputBorder(),
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
                onSuggestionTap: (p0) {
                  debugPrint('Suggestion Tapped: $p0');
                  cubit.toggleSearch();
                  // sort resources with suggestion on top
                },
              )
            : const AppTitle(
                key: Key('ResourcesTitle'),
              );
      },
    );
  }
}
