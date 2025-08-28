import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

class RatingsBar extends StatelessWidget {
  const RatingsBar({
    super.key,
    required this.resource,
    required this.isNew,
  });
  final Resource resource;
  final bool isNew;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final rater = cubit.getUserRatingForResource(resource);
    final isDark = SharedPrefs().isDarkMode;
    final isSelected =
        (rater?.isCollapsed ?? false) || (rater?.isSelected ?? false);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Visibility(
          visible: isNew,
          child: const SizedBox(
            width: 30,
          ),
        ),
        Text(
          maxLines: 1,
          '${resource.rating ?? 0}',
          style: TextStyle(
            fontSize: 14,
            color: isSelected
                ? HorseAndRidersTheme().getTheme().colorScheme.primary
                : isDark
                    ? Colors.grey
                    : Colors.black54,
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            'Submitted by: ${resource.lastEditBy}',
            maxLines: 1,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade200 : Colors.black54,
            ),
          ),
        ),
        Text(
          maxLines: 1,
          calculateTimeDifferenceBetween(
            referenceDate: resource.lastEditDate ?? DateTime.now(),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey.shade200 : Colors.black54,
          ),
        ),
      ],
    );
  }
}
