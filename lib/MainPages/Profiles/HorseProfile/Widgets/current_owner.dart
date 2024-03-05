import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// {@template current_owner}
/// CurrentOwner widget displays the name of the current owner
/// {@endtemplate}
class CurrentOwner extends StatelessWidget {
  /// {@macro current_owner}
  ///
  /// Displays the name of the current owner as a label and the owner name
  ///
  /// {@macro key}
  const CurrentOwner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return InkWell(
          onTap: () => context.read<AppCubit>().gotoProfilePage(
                context: context,
                toBeViewedEmail: state.horseProfile?.currentOwnerId ?? '',
              ),
          child: Text(
            state.horseProfile?.currentOwnerName ?? '',
            textAlign: TextAlign.start,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.blue,
              decoration: TextDecoration.underline,
            ),
          ),
        );
      },
    );
  }
}
