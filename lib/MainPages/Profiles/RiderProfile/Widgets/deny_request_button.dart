import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class DenyRequestButton extends StatelessWidget {
  const DenyRequestButton({
    super.key,
    this.request,
    this.message,
    this.onBeforeDeny,
  }) : assert(
         request != null || message != null,
         'Either request or message must be provided',
       );

  final ConnectionRequest? request;
  final Message? message;
  final VoidCallback? onBeforeDeny;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    final acceptStatus = context.select((AppCubit c) => c.state.acceptStatus);
    final isAccepted =
        request?.isAccepted ?? (message?.requestItem?.isSelected ?? false);

    return OutlinedButton(
      key: const Key('DenyRequestButton'),
      onPressed: isAccepted || acceptStatus == AcceptStatus.loading
          ? null
          : () {
              onBeforeDeny?.call();
              final req = request;
              if (req != null) {
                cubit.denyConnectionRequest(req);
              } else {
                cubit.denyRequest(message: message!);
              }
            },
      child: const Text('Deny Request'),
    );
  }
}
