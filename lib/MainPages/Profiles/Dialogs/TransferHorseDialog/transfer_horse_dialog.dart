import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:form_inputs/form_inputs.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/MainPages/Profiles/Dialogs/TransferHorseDialog/cubit/transfer_horse_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class TransferHorseDialog extends StatelessWidget {
  const TransferHorseDialog({
    super.key,
    required this.userProfile,
    required this.horseProfile,
  });
  final HorseProfile horseProfile;
  final RiderProfile userProfile;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => RiderProfileRepository()),
        RepositoryProvider(create: (context) => MessagesRepository()),
      ],
      child: BlocProvider(
        create: (context) => TransferHorseCubit(
          userProfile: userProfile,
          horseProfile: horseProfile,
          messagesRepository: context.read<MessagesRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
        ),
        child: BlocListener<TransferHorseCubit, TransferHorseState>(
          listener: (context, state) {
            final cubit = context.read<TransferHorseCubit>();
            if (state.status == TransferHorseStatus.success) {
              cubit.clearError();
              Navigator.of(context).pop();
            }
            if (state.status == TransferHorseStatus.error) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ).closed.then((value) {
                    if (!context.mounted) return;
                    cubit.clearError();
                  });
              });
            }
            if (state.isError) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor: Colors.red,
                    ),
                  ).closed.then((value) {
                    if (!context.mounted) return;
                    cubit.clearError();
                  });
              });
            }
            if (state.isMessage) {
              SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text(
                        state.message,
                        style: const TextStyle(color: Colors.white),
                      ),
                      backgroundColor:
                          HorseAndRidersTheme().getTheme().primaryColor,
                    ),
                  ).closed.then((value) {
                    if (!context.mounted) return;
                    cubit.clearError();
                  });
              });
            }
          },
          child: BlocBuilder<TransferHorseCubit, TransferHorseState>(
            builder: (context, state) {
              final cubit = context.read<TransferHorseCubit>();
              return AlertDialog(
                title: Text('Transfer: ${state.horseProfile?.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    gap(),
                    Text(
                      'Enter the email of the user you want'
                      ' to transfer ${state.horseProfile?.name} to:',
                    ),
                    gap(),
                    Form(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: TextFormField(
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return null;
                          }
                          if (!value.contains('@')) {
                            return null;
                          }
                          final emailField = Email.dirty(value);
                          if (!emailField.isValid) {
                            return 'Please enter a valid email address';
                          }
                          return null; // Input is valid
                        },
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onChanged: cubit.emailChanged,
                        decoration: InputDecoration(
                          suffixIcon: state.email.isValid
                              ? const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                )
                              : null,
                          hintText: 'Email',
                        ),
                      ),
                    ),
                    gap(),
                    if (state.status == TransferHorseStatus.searching)
                      const CircularProgressIndicator(),
                    if (state.transferProfile != null)
                      ListTile(
                        leading: ProfilePhoto(
                          size: 50,
                          profilePicUrl: state.transferProfile?.picUrl,
                        ),
                        title: Text(state.transferProfile?.name ?? ''),
                      ),
                    if (state.email.isValid &&
                        state.transferProfile == null &&
                        !state.isTransferable)
                      const Text('No user found with this email.'),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed:
                        state.isTransferable ? cubit.sendTransferRequest : null,
                    child: state.status == TransferHorseStatus.sending
                        ? const CircularProgressIndicator()
                        : const Text('Transfer'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
