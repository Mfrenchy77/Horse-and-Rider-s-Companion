import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

/// {@template horse_nickname}
/// HorseNickName widget displays the nickname of the horse
/// {@endtemplate}
class HorseNickName extends StatelessWidget {
  /// {@macro horse_nickname}
  /// Displays the nickname of the horse as a label and the nickname
  /// {@macro key}
  const HorseNickName({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('NickName: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                '${state.horseProfile?.nickname}',
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
