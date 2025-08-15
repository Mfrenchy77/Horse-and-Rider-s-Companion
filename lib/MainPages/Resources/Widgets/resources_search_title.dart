import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/appbar_title.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class ResourcesSearchTitle extends StatelessWidget {
  const ResourcesSearchTitle({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();

        if (!state.isSearch) {
          return const AppTitle(key: Key('ResourcesTitle'));
        }

        // Use built-in Autocomplete so we can remove the 'searchfield' package
        return Autocomplete<String>(
          // Filter suggestions based on current text.
          optionsBuilder: (TextEditingValue text) {
            final query = text.text.trim().toLowerCase();
            if (query.isEmpty) return const Iterable<String>.empty();
            final items = state.searchList
                .whereType<String>() // ignore any nulls from state
                .where((e) => e.toLowerCase().contains(query));
            return items;
          },
          // How to display each option as a string.
          displayStringForOption: (option) => option,

          // Shown when user taps a suggestion.
          onSelected: (value) {
            cubit
              ..resourceSearchQueryChanged(searchQuery: value)
              ..toggleSearch();
          },

          // Custom field so we can style like your old SearchField.
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
            // Seed controller with current query (optional).
            // textController.text = state.currentSearchQuery ?? '';

            return TextField(
              controller: textController,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              keyboardType: TextInputType.text,
              onChanged: (q) =>
                  cubit.resourceSearchQueryChanged(searchQuery: q),
              onSubmitted: (q) {
                cubit
                  ..resourceSearchQueryChanged(searchQuery: q)
                  ..toggleSearch();
              },
              decoration: InputDecoration(
                filled: true,
                iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
                fillColor:
                    HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                hintText: 'Search Resources',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(40)),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                suffixIcon: IconButton(
                  onPressed: () {
                    textController.clear();
                    cubit.toggleSearch();
                  },
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                ),
              ),
            );
          },

          // Custom list to make suggestions look like your previous widget.
          optionsViewBuilder: (context, onSelected, options) {
            final theme = Theme.of(context);
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 420, maxHeight: 300),
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
