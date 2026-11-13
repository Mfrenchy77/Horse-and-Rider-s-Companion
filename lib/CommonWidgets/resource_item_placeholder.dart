import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:shimmer/shimmer.dart';

/// Item placeholder for resources, with a shimmer effect.
class ResourceItemPlaceholder extends StatelessWidget {
  const ResourceItemPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTokens.midnightCardTop : Colors.grey.shade300;
    final highlightColor = isDark
        ? AppTokens.midnightButtonFill
        : Colors.grey.shade100;
    final boxColor = isDark ? AppTokens.midnightCardTop : Colors.grey;

    Widget shimmerBox({double? height, double radius = 10}) =>
        Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: boxColor,
            ),
          ),
        );

    return AppSurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          shimmerBox(height: 168, radius: 0),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                shimmerBox(height: 22),
                const SizedBox(height: 10),
                shimmerBox(height: 14),
                const SizedBox(height: 8),
                shimmerBox(height: 48),
                const SizedBox(height: 14),
                shimmerBox(height: 28),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
