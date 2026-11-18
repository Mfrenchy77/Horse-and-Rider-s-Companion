import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Animations/app_dialog.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/resource_item_placeholder.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/guest_spotlight_tour.dart';
import 'package:horseandriderscompanion/MainPages/Onboarding/resources_spotlight_tour.dart';
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
          previous.resources != current.resources ||
          previous.hasResourceCatalogue != current.hasResourceCatalogue ||
          previous.isError != current.isError,
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
                ValueListenableBuilder<bool>(
                  valueListenable: ResourcesSpotlightTour.isTourActive,
                  builder: (context, tourActive, child) => KeyedSubtree(
                    key: tourActive
                        ? ResourcesSpotlightTour.sortControlKey
                        : null,
                    child: child!,
                  ),
                  child: InkWell(
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
                ),
              ],
            );

            Widget buildLazyRows(
              int itemCount,
              Widget Function(int) itemBuilder,
            ) {
              if (columns == 1) {
                return SliverList.separated(
                  itemCount: itemCount,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => itemBuilder(index),
                );
              }
              final rowCount = (itemCount + columns - 1) ~/ columns;
              return SliverList.separated(
                itemCount: rowCount,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, rowIndex) {
                  final start = rowIndex * columns;
                  final end = (start + columns) > itemCount
                      ? itemCount
                      : start + columns;
                  final sliceCount = end - start;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 16,
                    children: [
                      for (var i = start; i < end; i++)
                        Expanded(child: itemBuilder(i)),
                      for (var pad = sliceCount; pad < columns; pad++)
                        const Expanded(child: SizedBox.shrink()),
                    ],
                  );
                },
              );
            }

            final isLoading =
                !state.hasResourceCatalogue &&
                items.isEmpty &&
                !state.isError;
            final isFailed = state.isError && items.isEmpty;

            final Widget sliverContent;
            if (isSavedView && items.isEmpty) {
              sliverContent = const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppEmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'No saved resources yet',
                    description:
                        'Tap the heart on any resource to save it here for '
                        'quick access.',
                  ),
                ),
              );
            } else if (isFailed) {
              sliverContent = SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Column(
                    spacing: AppTokens.spaceMd,
                    children: [
                      const AppEmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Unable to load resources',
                        description:
                            'Check your connection and try loading resources '
                            'again.',
                      ),
                      FilledButton.icon(
                        key: const Key('resourcesRetryButton'),
                        onPressed: cubit.loadResourcesIfNeeded,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else if (isLoading) {
              final skeletonCount = columns == 1 ? 3 : columns * 2;
              sliverContent = buildLazyRows(
                skeletonCount,
                (_) => const ResourceItemPlaceholder(),
              );
            } else if (items.isEmpty) {
              sliverContent = const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: AppEmptyState(
                    icon: Icons.menu_book_outlined,
                    title: 'No resources yet',
                    description:
                        'Educational articles, videos, and links added by '
                        'the community will appear here.',
                  ),
                ),
              );
            } else {
              sliverContent = buildLazyRows(
                items.length,
                (index) => ResourcesItem(
                  key: ValueKey(items[index].id ?? index),
                  resource: items[index],
                  isResourceList: true,
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: ValueListenableBuilder<bool>(
                  valueListenable: ResourcesSpotlightTour.isTourActive,
                  builder: (context, tourActive, child) => KeyedSubtree(
                    key: tourActive
                        ? ResourcesSpotlightTour.libraryListKey
                        : null,
                    child: child!,
                  ),
                  child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      sliver: SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: GuestSpotlightTour.resourcesHeaderKey,
                          child: header,
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                      sliver: sliverContent,
                    ),
                  ],
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
