import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:numberpicker/numberpicker.dart';

class CentimeterPickerDialog extends StatelessWidget {
  const CentimeterPickerDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddHorseDialogCubit, AddHorseDialogState>(
      builder: (context, state) {
        final cubit = context.read<AddHorseDialogCubit>();
        const minHeight = 30;
        const maxHeight = 250;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton.tonal(
              onPressed: state.height == minHeight
                  ? null
                  : cubit.decrementHeightByCentimeter,
              child: const Icon(Icons.arrow_drop_up),
            ),
            Card(
              elevation: 8,
              color: HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
              child: NumberPicker(
                minValue: minHeight,
                maxValue: maxHeight,
                value: state.height,
                onChanged: cubit.horseHeightChanged,
              ),
            ),
            FilledButton.tonal(
              onPressed: state.height == maxHeight
                  ? null
                  : cubit.incrementHeightByCentimeter,
              child: const Icon(Icons.arrow_drop_down),
            ),
          ],
        );
      },
    );
  }
}
