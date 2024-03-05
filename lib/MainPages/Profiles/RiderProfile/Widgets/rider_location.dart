import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class RiderLocation extends StatelessWidget {
  const RiderLocation({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final riderProfile = state.viewingProfile ?? state.usersProfile;
        return Visibility(
          visible: !state.isGuest,
          child: Center(
            child: Text(
              riderProfile?.locationName == null
                  ? ''
                  : '${riderProfile?.locationName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
