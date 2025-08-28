import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';
import 'package:numberpicker/numberpicker.dart';

class HandsPickerDialog extends StatelessWidget {
  const HandsPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddHorseDialogCubit, AddHorseDialogState>(
      builder: (context, state) {
        final cubit = context.read<AddHorseDialogCubit>();
        const minHeight = 30;
        const maxHeight = 250;
        const minHandHeight = 3;
        const maxHandHeight = 19;
        const minInchesHeight = 0;
        const maxInchesHeight = 3;
        return IntrinsicHeight(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FilledButton.tonal(
                onPressed: state.height == minHeight ||
                        state.height == 35 ||
                        state.height < 35
                    ? null
                    : cubit.decrementHeightByInch,
                child: const Icon(Icons.arrow_drop_up),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //Hands
                  Card(
                    elevation: 8,
                    color: HorseAndRidersTheme()
                        .getTheme()
                        .scaffoldBackgroundColor,
                    child: NumberPicker(
                      minValue: minHandHeight,
                      maxValue: maxHandHeight,
                      value: cmToHandsAndInches(state.height).toInt(),
                      onChanged: cubit.updateHeightInHands,
                    ),
                  ),
                  VerticalDivider(
                    color: HorseAndRidersTheme().getTheme().dividerColor,
                    endIndent: 20,
                    indent: 20,
                  ),
                  //Inch
                  Card(
                    elevation: 8,
                    color: HorseAndRidersTheme()
                        .getTheme()
                        .scaffoldBackgroundColor,
                    child: NumberPicker(
                      minValue: minInchesHeight,
                      maxValue: maxInchesHeight,
                      value: cmToHandsRemainder(state.height),
                      onChanged: cubit.updateHeightInInches,
                    ),
                  ),
                ],
              ),
              FilledButton.tonal(
                onPressed: state.height == maxHeight ||
                        state.height == 200 ||
                        state.height > 200
                    ? null
                    : cubit.incrementHeightByInch,
                child: const Icon(Icons.arrow_drop_down),
              ),
            ],
          ),
        );
      },
    );
  }
}
