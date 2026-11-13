import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class AcceptRequestButton extends StatelessWidget {
  const AcceptRequestButton({super.key, this.request, this.message})
    : assert(
        request != null || message != null,
        'Either request or message must be provided',
      );

  final ConnectionRequest? request;
  final Message? message;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final acceptStatus = context.select((AppCubit c) => c.state.acceptStatus);
    final isAccepted =
        request?.isAccepted ?? (message?.requestItem?.isSelected ?? false);

    return FilledButton(
      onPressed: isAccepted || acceptStatus == AcceptStatus.loading
          ? null
          : () {
              final req = request;
              if (req != null) {
                cubit.acceptConnectionRequest(req);
              } else {
                cubit.acceptRequest(message: message!);
              }
            },
      child: acceptStatus == AcceptStatus.loading
          ? const CircularProgressIndicator()
          : Text(isAccepted ? 'Accepted' : 'Send connection request'),
    );
  }
}
