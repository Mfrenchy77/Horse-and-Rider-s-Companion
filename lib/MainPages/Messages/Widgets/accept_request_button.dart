import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class AcceptRequestButton extends StatelessWidget {
  const AcceptRequestButton({super.key, required this.message});
  final Message message;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isAccepted = message.requestItem?.isSelected ?? false;
        return FilledButton(
          onPressed: isAccepted
              ? null
              : () => cubit
                  .acceptRequest(message: message, context: context),
          child: state.acceptStatus == AcceptStatus.loading
              ? const CircularProgressIndicator()
              : Text(isAccepted ? 'Accepted' : 'Accept Request'),
        );
      },
    );
  }
}
