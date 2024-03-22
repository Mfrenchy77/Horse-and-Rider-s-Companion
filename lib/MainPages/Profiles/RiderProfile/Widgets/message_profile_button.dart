import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class MessageProfileButton extends StatelessWidget {
  const MessageProfileButton({super.key, required this.profile});
  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        if (state.isGuest || state.usersProfile?.email == profile.email) {
          return const SizedBox.shrink();
        } else {
          return ElevatedButton.icon(
            onPressed: () {
              debugPrint('Send Message');
            },
            icon: const Icon(Icons.mail),
            label: const Text('Send Message'),
          );
        }
      },
    );
  }
}
