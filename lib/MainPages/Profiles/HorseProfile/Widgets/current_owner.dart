import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/viewing_profile_page.dart';

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
        final cubit = context.read<AppCubit>();
        return InkWell(
          onTap: () {
            state.usersProfile?.email == state.horseProfile?.currentOwnerId
                ? cubit.createMessage('You are the owner of this horse.')
                : context.goNamed(
                    ViewingProfilePage.name,
                    pathParameters: {
                      ViewingProfilePage.pathParams:
                          state.horseProfile?.currentOwnerId ?? '',
                    },
                  );
          },
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
