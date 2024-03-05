import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:url_launcher/url_launcher.dart';

class RiderWebsiteLink extends StatelessWidget {
  const RiderWebsiteLink({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final riderProfile = state.viewingProfile ?? state.usersProfile;
        return Visibility(
          visible: riderProfile?.homeUrl != null,
          child: InkWell(
            onTap: () => launchUrl(Uri.parse(riderProfile?.homeUrl ?? '')),
            child: const Text(
              'Website Link',
              style: TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      },
    );
  }
}
