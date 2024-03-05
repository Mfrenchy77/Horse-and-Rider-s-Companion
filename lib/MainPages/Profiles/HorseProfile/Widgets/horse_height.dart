import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

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
                '${state.horseProfile?.height}',
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
