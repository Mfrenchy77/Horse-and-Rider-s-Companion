import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Theme/app_design_system.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

class RatingsBar extends StatelessWidget {
  const RatingsBar({super.key, required this.resource, required this.isNew});
  final Resource resource;
  final bool isNew;
  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final rater = cubit.getUserRatingForResource(resource);
    final isSelected =
        (rater?.isCollapsed ?? false) || (rater?.isSelected ?? false);
    final secondaryColor = AppTokens.secondaryTextColor(context);

    return Row(
      children: [
        Text(
          '${resource.rating ?? 0}',
          maxLines: 1,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isSelected ? AppTokens.accentColor(context) : secondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Submitted by: ${resource.lastEditBy}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: secondaryColor),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          calculateTimeDifferenceBetween(
            referenceDate: resource.lastEditDate ?? DateTime.now(),
          ),
          maxLines: 1,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: secondaryColor),
        ),
      ],
    );
  }
}
