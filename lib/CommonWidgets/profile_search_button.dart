import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/ProfileSearchDialog/profile_search_dialog.dart';

/// {@template profile_search_button}
/// ProfileSearchButton widget displays the search button
/// {@endtemplate}
///
class ProfileSearchButton extends StatelessWidget {
  /// {@macro profile_search_button}
  /// Displays the search button for searching Rider/Horse profiles
  /// {@macro key}
  const ProfileSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Visibility(
          visible: state.usersProfile != null,
          child: IconButton(
            onPressed: () {
              showDialog<AlertDialog>(
                context: context,
                builder: (dialogContext) => ProfileSearchDialog(
                  homeContext: context,
                  key: const Key('ProfileSearchDialog'),
                ),
              );
            },
            icon: const Icon(Icons.search),
          ),
        );
      },
    );
  }
}
