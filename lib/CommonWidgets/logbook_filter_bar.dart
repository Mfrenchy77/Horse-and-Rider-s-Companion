import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Filter pill item for [LogbookFilterBar].
class LogbookFilterOption<T> {
  const LogbookFilterOption({
    required this.value,
    required this.label,
  });

  final T value;
  final String label;
}

/// Shared category filter pills, optional search box, and sort control
/// for Rider and Horse logbooks.
class LogbookFilterBar<T> extends StatelessWidget {
  const LogbookFilterBar({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.newestFirst,
    required this.onSortChanged,
    this.onSearchChanged,
    this.searchLabel = 'Search entries',
  });

  final List<LogbookFilterOption<T>> options;
  final T selected;
  final ValueChanged<T> onSelected;
  final bool newestFirst;
  final ValueChanged<bool> onSortChanged;
  final ValueChanged<String>? onSearchChanged;
  final String searchLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTokens.accentColor(context);
    final borderColor = isDark
        ? AppTokens.midnightButtonBorder
        : theme.colorScheme.outlineVariant;
    final fillColor = isDark
        ? AppTokens.midnightInputFill
        : theme.colorScheme.surface;

    final sortControl = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTokens.midnightButtonFill
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<bool>(
          value: newestFirst,
          icon: Icon(
            Icons.sort_rounded,
            size: 18,
            color: AppTokens.secondaryTextColor(context),
          ),
          dropdownColor: isDark
              ? AppTokens.midnightCardBottom
              : theme.colorScheme.surface,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTokens.primaryTextColor(context),
            fontWeight: FontWeight.w500,
          ),
          onChanged: (value) {
            if (value != null) onSortChanged(value);
          },
          items: const [
            DropdownMenuItem(value: true, child: Text('Newest first')),
            DropdownMenuItem(value: false, child: Text('Oldest first')),
          ],
        ),
      ),
    );

    final searchField = onSearchChanged == null
        ? null
        : TextField(
            onChanged: onSearchChanged,
            style: TextStyle(color: AppTokens.primaryTextColor(context)),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppTokens.secondaryTextColor(context),
              ),
              labelText: searchLabel,
              labelStyle: TextStyle(
                color: AppTokens.secondaryTextColor(context),
              ),
              filled: true,
              fillColor: fillColor,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                borderSide: BorderSide(color: accent, width: 1.5),
              ),
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              _FilterPill(
                label: option.label,
                selected: selected == option.value,
                onTap: () => onSelected(option.value),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (searchField != null)
          LayoutBuilder(
            builder: (context, constraints) => constraints.maxWidth >= 460
                ? Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 12),
                      sortControl,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      searchField,
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: sortControl,
                      ),
                    ],
                  ),
          )
        else
          Align(
            alignment: Alignment.centerRight,
            child: sortControl,
          ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AppTokens.accentColor(context);
    final selectedInk = isDark
        ? AppTokens.coralText
        : theme.colorScheme.onPrimary;
    final unselectedBg = isDark
        ? AppTokens.midnightButtonFill
        : theme.colorScheme.surfaceContainerLow;
    final unselectedBorder = isDark
        ? AppTokens.midnightButtonBorder
        : theme.colorScheme.outlineVariant;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: true,
      checkmarkColor: selectedInk,
      selectedColor: accent,
      backgroundColor: unselectedBg,
      surfaceTintColor: Colors.transparent,
      side: BorderSide(
        color: selected ? accent : unselectedBorder,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        color: selected
            ? selectedInk
            : AppTokens.primaryTextColor(context),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
