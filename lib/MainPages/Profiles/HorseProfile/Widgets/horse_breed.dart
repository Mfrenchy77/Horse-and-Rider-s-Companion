import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

///{@template horse_breed}
/// HorseBreed widget displays the breed of the horse
/// {@endtemplate}
class HorseBreed extends StatelessWidget {
  /// {@macro horse_breed}
  /// Displays the breed of the horse as a label and the breed name
  /// {@macro key}
  const HorseBreed({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Breed: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                '${state.horseProfile?.breed}',
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
