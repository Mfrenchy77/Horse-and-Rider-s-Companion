import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

/// {@template horse_height}
/// HorseHeight widget displays the height of the horse
/// {@endtemplate}
class HorseHeight extends StatelessWidget {
  /// {@macro horse_height}
  /// Displays the height of the horse as a label and the height
  /// {@macro key}
  const HorseHeight({super.key});

  @override
  Widget build(BuildContext context) {
    final isHeightInHands = SharedPrefs().isHeightInHands;
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Height: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                isHeightInHands
                    ? '${cmToHands(state.horseProfile?.height ?? 0)}.'
                        '${cmToHandsRemainder(state.horseProfile?.height ?? 0)}'
                    : '${state.horseProfile?.height}',
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
