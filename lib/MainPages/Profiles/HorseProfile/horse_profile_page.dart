import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';

class HorseProfilePage extends StatelessWidget {
  const HorseProfilePage({super.key, required this.horseId});

  static const pathParams = 'horseId';
  static const name = 'HorseProfilePage';
  static const path = 'Horse_Profile/:horseId';

  final String horseId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>()..getHorseProfile(id: horseId);

        return state.horseProfile == null || state.horseProfile?.id != horseId
            ? const LoadingPage()
            : PopScope(
                onPopInvokedWithResult: (didPop, result) {
                  debugPrint(
                    'Horse Profile Page Pop Invoked: $didPop result: $result',
                  );
                  cubit.resetFromHorseProfile();
                },
                child: HorseProfileView(
                  horseProfile: state.horseProfile!,
                  key: const Key('horseProfileView'),
                ),
              );
      },
    );
  }
}
