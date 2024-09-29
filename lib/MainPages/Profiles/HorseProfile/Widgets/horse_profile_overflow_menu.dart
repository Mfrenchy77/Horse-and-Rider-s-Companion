import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/AddHorseDialog/add_horse_dialog.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/transfer_horse_dialog.dart';

class HorseProfileOverFlowMenu extends StatelessWidget {
  const HorseProfileOverFlowMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return Visibility(
          visible: cubit.isOwner(),
          child: PopupMenuButton<String>(
            itemBuilder: (BuildContext menuContext) => <PopupMenuEntry<String>>[
              const PopupMenuItem(value: 'Edit', child: Text('Edit')),
              const PopupMenuItem(value: 'Delete', child: Text('Delete')),
              const PopupMenuItem(value: 'Transfer', child: Text('Transfer')),
            ],
            onSelected: (value) {
              switch (value) {
                case 'Edit':
                  showDialog<AddHorseDialog>(
                    context: context,
                    builder: (context) => AddHorseDialog(
                      horseProfile: state.horseProfile,
                      userProfile: state.usersProfile!,
                      editProfile: true,
                    ),
                  );
                  break;
                case 'Transfer':
                  if (state.horseProfile != null) {
                    showDialog<AlertDialog>(
                      context: context,
                      builder: (context) => TransferHorseDialog(
                        horseProfile: state.horseProfile!,
                        userProfile: state.usersProfile!,
                      ),
                    );
                  } else {
                    cubit.createError('Horse profile not found');
                  }
                  break;
                case 'Delete':
                  cubit.deleteHorseProfileFromUser();
                  break;
              }
            },
          ),
        );
      },
    );
  }
}
