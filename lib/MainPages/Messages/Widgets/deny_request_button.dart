import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';

class DenyRequestButton extends StatelessWidget {
  const DenyRequestButton({
    super.key,
    required this.message,
    this.onBeforeDeny,
  });
  final Message message;
  final VoidCallback? onBeforeDeny;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isAccepted = message.requestItem?.isSelected ?? false;

        return OutlinedButton(
          key: const Key('DenyRequestButton'),
          onPressed: isAccepted
              ? null
              : () {
                  onBeforeDeny?.call();
                  cubit.denyRequest(message: message, context: context);
                },
          child: const Text('Deny Request'),
        );
      },
    );
  }
}
