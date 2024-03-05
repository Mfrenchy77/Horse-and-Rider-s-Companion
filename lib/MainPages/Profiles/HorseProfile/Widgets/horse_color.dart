import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// {@template horse_color}
/// HorseColor widget displays the color of the horse
/// {@endtemplate}
class HorseColor extends StatelessWidget {
  /// {@macro horse_color}
  ///
  /// Displays the color of the horse as a label and the color name
  ///
  /// {@macro key}
  const HorseColor({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Color: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                '${state.horseProfile?.color}',
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
