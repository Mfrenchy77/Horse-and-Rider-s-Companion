import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// {@template horse_gender}
/// HorseGender widget displays the horse's gender
/// {@endtemplate}
class HorseGender extends StatelessWidget {
  /// {@macro horse_gender}
  /// Displays the gender of the horse as a label and the gender
  /// {@macro key}
  const HorseGender({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Gender: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                '${state.horseProfile?.gender}',
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
