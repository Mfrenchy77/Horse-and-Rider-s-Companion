import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/resource_item_placeholder.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Dialogs/resources_sort_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

class ResourcesListView extends StatelessWidget {
  const ResourcesListView({super.key});

  String _sortLabel(ResourcesSortStatus status) => switch (status) {
    ResourcesSortStatus.oldest => 'Oldest',
    ResourcesSortStatus.mostRecommended => 'Most Recommended',
    ResourcesSortStatus.leastRecommended => 'Least Recommended',
    ResourcesSortStatus.recent => 'Most Recent',
    ResourcesSortStatus.saved => 'Saved',
  };

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.resourcesSortStatus != current.resourcesSortStatus ||
          previous.savedResources != current.savedResources ||
          previous.resources != current.resources,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isSavedView =
            state.resourcesSortStatus == ResourcesSortStatus.saved;
        final items = isSavedView
            ? cubit.sortResources(state.savedResources)
            : cubit.sortResources(state.resources);
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width >= 1080
                ? 3
                : width >= 700
                ? 2
                : 1;
            final maxWidth = columns == 3
                ? 1320.0
                : columns == 2
                ? 1040.0
                : 620.0;

            final header = Row(
              children: [
                Expanded(
                  child: Text(
                    'Resources',
                    style: AppTokens.sectionTitleStyle(
                      context,
                    ).copyWith(fontSize: 26),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  onTap: () => showAppGlassDialog<void>(
                    context: context,
                    builder: (context) => const ResourcesSortDialog(
                      key: Key('resources_sort_dialog'),
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTokens.midnightButtonFill
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      border: Border.all(
                        color: isDark
                            ? AppTokens.midnightButtonBorder
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sort_rounded,
                            size: 18,
                            color: AppTokens.accentColor(context),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _sortLabel(state.resourcesSortStatus),
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppTokens.primaryTextColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: AppTokens.secondaryTextColor(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );

            Widget buildGrid(List<Widget> cards) {
              if (columns == 1) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: cards,
                );
              }
              final rows = <Widget>[];
              for (var i = 0; i < cards.length; i += columns) {
                final slice = cards.sublist(
                  i,
                  (i + columns) > cards.length ? cards.length : i + columns,
                );
                rows.add(
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      for (final card in slice) Expanded(child: card),
                      for (var pad = slice.length; pad < columns; pad++)
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: rows,
              );
            }

            final Widget content;
            if (isSavedView && items.isEmpty) {
              content = const Padding(
                padding: EdgeInsets.only(top: 24),
                child: AppEmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: 'No saved resources yet',
                  description:
                      'Tap the heart on any resource to save it here for '
                      'quick access.',
                ),
              );
            } else if (items.isEmpty) {
              content = buildGrid(
                List.generate(
                  columns == 1 ? 3 : columns * 2,
                  (_) => const ResourceItemPlaceholder(),
                ),
              );
            } else {
              content = buildGrid([
                for (final resource in items)
                  ResourcesItem(resource: resource, isResourceList: true),
              ]);
            }

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                  children: [header, const SizedBox(height: 16), content],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
