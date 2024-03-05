import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// {@template horse_age}
/// HorseAge widget displays the age of the horse
/// {@endtemplate}
class HorseAge extends StatelessWidget {
  /// {@macro horse_age}
  /// Displays the age of the horse as a label and the age
  /// {@macro key}
  const HorseAge({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final today = DateTime.now().year;
        final dob = state.horseProfile?.dateOfBirth?.year ?? today;
        final age = today - dob;
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Age: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                '$age',
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
