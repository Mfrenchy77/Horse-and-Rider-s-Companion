// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/messages_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/groups_list.dart';
import 'package:horseandriderscompanion/MainPages/Messages/view/messages_view.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
  });

  static const path = 'Messages';
  static const name = 'MessagesPage';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RepositoryProvider(
        create: (context) => context.read<MessagesRepository>(),
        child: BlocProvider(
          create: (context) => MessagesCubit(
            horseProfileRepository: context.read<HorseProfileRepository>(),
            riderProfileRepository: context.read<RiderProfileRepository>(),
            messagesRepository: context.read<MessagesRepository>(),
            riderProfile: context.read<AppCubit>().state.usersProfile!,
          ),
          child: BlocBuilder<MessagesCubit, MessagesState>(
            builder: (context, state) {
              final riderProfile = context.read<AppCubit>().state.usersProfile!;
              return (state.status == MessagesStatus.groups)
                  ? GroupsList(
                      messagesCubit: context.read<MessagesCubit>(),
                      state: state,
                      userProfile: riderProfile,
                    )
                  : MessagesView(
                      riderProfile: riderProfile,
                      context: context,
                      state: state,
                      group: state.group,
                    );
            },
          ),
        ),
      ),
    );
  }
}

class MessageArguments {
  MessageArguments({required this.riderProfile, required this.group});
  final RiderProfile? riderProfile;
  final Group? group;
}
