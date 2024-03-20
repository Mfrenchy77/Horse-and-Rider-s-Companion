import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/RiderProfile/rider_profile_view.dart';

class ViewingProfilePage extends StatelessWidget {
  const ViewingProfilePage({super.key, required this.id});

  static const pathParams = 'id';
  static const path = 'Viewing/:id';
  static const name = 'ViewingProfilePage';

  final String id;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        if (state.viewingProfile == null || state.viewingProfile?.email != id) {
          cubit.getProfileToBeViewed(email: id);
        }
        return state.viewingProfile == null
            ? const LoadingPage()
            : PopScope(
                onPopInvoked: (didPop) {
                  debugPrint('Viewing Profile Page Pop Invoked: $didPop');
                  cubit.resetFromViewingProfile();
                },
                child: RiderProfileView(
                  profile: state.viewingProfile!,
                  key: const Key('ViewingProfileView'),
                ),
              );
      },
    );
  }
}
