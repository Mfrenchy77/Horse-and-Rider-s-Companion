import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Cubit/add_horse_dialog_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Widgets/centimeter_picker_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/Widgets/hands_picker_dialog.dart';
import 'package:horseandriderscompanion/Settings/settings_view.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methodsd.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class HorseHeightField extends StatelessWidget {
  const HorseHeightField({
    super.key,
    required this.controller,
  });
  final TextEditingController controller;
  @override
  Widget build(BuildContext context) {
    final state = context.read<AddHorseDialogCubit>().state;
    final remainder = cmToHandsRemainder(state.height);
    final isHeightinHands = SharedPrefs().isHeightInHands;
    final height = isHeightinHands ? cmToHands(state.height) : state.height;
    controller.text = '$height.$remainder';
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: "Horse's Height",
        hintText: "Enter Horse's Height",
        icon: Icon(HorseAndRiderIcons.ruler),
      ),
      onTap: () => showDialog<AlertDialog>(
        context: context,
        builder: (dialogContext) {
          return BlocProvider.value(
            value: BlocProvider.of<AddHorseDialogCubit>(context),
            child: AlertDialog(
              title: Text('Select Height in '
                  '${isHeightinHands ? 'Hands' : 'Centimeters'}'),
              content: isHeightinHands
                  ? const HandsPickerDialog()
                  : const CentimeterPickerDialog(),
              actions: [
                //go to settings to switch between hands and centimeters
                TextButton(
                  onPressed: () {
                    dialogContext.pop();
                    context
                      ..pop()
                      ..pushNamed(SettingsView.name);
                  },
                  child: Text(
                    'Switch to ${isHeightinHands ? 'Centimeters' : 'Hands'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
