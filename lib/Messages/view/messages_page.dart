// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/logo.dart';
import 'package:horseandriderscompanion/Messages/cubit/messages_cubit.dart';
import 'package:horseandriderscompanion/Messages/view/groups_list.dart';
import 'package:horseandriderscompanion/Messages/view/messages_view.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({
    super.key,
  });

  static const routeName = '/messages';
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as MessageArguments?;

    final riderProfile = args?.riderProfile;
    final group = args?.group;
    debugPrint('Rider Profile: ${riderProfile?.name}');
    if (riderProfile != null) {
      if (group != null) {
        /// opens the messages view with the group selected
        context.read<MessagesCubit>().openOrNewMessage(group);
      }
      return Scaffold(
        body: RepositoryProvider(
          create: (context) => context.read<MessagesRepository>(),
          child: BlocProvider(
            create: (context) => MessagesCubit(
              horseProfileRepository: context.read<HorseProfileRepository>(),
              riderProfileRepository: context.read<RiderProfileRepository>(),
              messagesRepository: context.read<MessagesRepository>(),
              riderProfile: riderProfile,
            ),
            child: BlocBuilder<MessagesCubit, MessagesState>(
              builder: (context, state) {
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
    } else {
      return ColoredBox(
        color: HorseAndRidersTheme().getTheme().colorScheme.background,
        child: const Center(
          child: Logo(screenName: 'Error: No Rider Profile'),
        ),
      );
    }
  }
}

class MessageArguments {
  MessageArguments({required this.riderProfile, required this.group});
  final RiderProfile? riderProfile;
  final Group? group;
}
