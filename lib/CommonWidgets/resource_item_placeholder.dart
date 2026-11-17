import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';

/// Lightweight static skeleton card for resources while initial data loads.
class ResourceItemPlaceholder extends StatelessWidget {
  const ResourceItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? AppTokens.midnightButtonFill.withValues(alpha: 0.65)
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final subtleFill = isDark
        ? AppTokens.midnightInputFill
        : Theme.of(context).colorScheme.surfaceContainerHigh;

    Widget bar({
      required double height,
      double? width,
      double radius = AppTokens.radiusSm,
      Color? color,
    }) => Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: color ?? fill,
      ),
    );

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 168,
            color: subtleFill,
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: 32,
              color: AppTokens.secondaryTextColor(
                context,
              ).withValues(alpha: 0.45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceMd,
              AppTokens.spaceMd,
              AppTokens.spaceMd,
              AppTokens.spaceSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                bar(height: 20),
                const SizedBox(height: 8),
                bar(height: 12, width: 140),
                const SizedBox(height: 10),
                bar(height: 14),
                const SizedBox(height: 6),
                bar(height: 14, width: 220),
                const SizedBox(height: 12),
                Row(
                  spacing: 6,
                  children: [
                    bar(height: 24, width: 88, radius: 999),
                    bar(height: 24, width: 72, radius: 999),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.spaceMd,
              0,
              AppTokens.spaceMd,
              AppTokens.spaceSm + 4,
            ),
            child: Column(
              children: [
                const Divider(height: AppTokens.spaceMd),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    bar(height: 14, width: 42),
                    bar(height: 14, width: 110),
                    bar(height: 14, width: 54),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
