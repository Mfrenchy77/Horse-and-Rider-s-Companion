import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/loading_page.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/HorseProfile/horse_profile.dart';

class HorseProfilePage extends StatefulWidget {
  const HorseProfilePage({super.key, required this.horseId});

  static const pathParams = 'horseId';
  static const name = 'HorseProfilePage';
  static const path = 'Horse_Profile/:horseId';

  final String horseId;

  @override
  State<HorseProfilePage> createState() => _HorseProfilePageState();
}

class _HorseProfilePageState extends State<HorseProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<AppCubit>().getHorseProfile(id: widget.horseId);
  }

  @override
  void didUpdateWidget(covariant HorseProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.horseId != widget.horseId) {
      context.read<AppCubit>().getHorseProfile(id: widget.horseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.horseProfile != current.horseProfile,
      builder: (context, state) {
        return state.horseProfile == null ||
                state.horseProfile?.id != widget.horseId
            ? const LoadingPage()
            : HorseProfileView(
                horseProfile: state.horseProfile!,
                key: const Key('horseProfileView'),
              );
      },
    );
  }
}
