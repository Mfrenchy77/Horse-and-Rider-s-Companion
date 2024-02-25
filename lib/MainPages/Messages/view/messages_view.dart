// ignore_for_file: cast_nullable_to_non_nullable, non_constant_identifier_names, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/MainPages/Messages/cubit/messages_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methodsd.dart';

Widget MessagesView({
  required BuildContext context,
  required RiderProfile riderProfile,
  required Group? group,
  required MessagesState state,
}) {
  final parties = group?.parties?..remove(riderProfile.name);
  final partiesList = parties?.join(', ') as String;

  return Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: () => context.read<MessagesCubit>().goToGroups(),
        icon: const Icon(Icons.arrow_back),
      ),
      title: Text(
        group != null ? partiesList : 'New Message',
      ),
    ),
    body: Stack(
      children: [
        _messagesList(
          context: context,
          state: state,
          riderProfile: riderProfile,
        ),
        TextBar(state: state),
      ],
    ),
  );
}

Widget _messagesList({
  required BuildContext context,
  required MessagesState state,
  required RiderProfile riderProfile,
}) {
  return state.messages.isNotEmpty
      ? Padding(
          padding: const EdgeInsets.only(bottom: 60),
          child: ListView.builder(
            shrinkWrap: true,
            reverse: true,
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              return _messageItem(
                state: state,
                context: context,
                message: message as Message,
                riderProfile: riderProfile,
              );
            },
          ),
        )
      : const Center(child: Text('No Messages'));
}

Widget _messageItem({
  required MessagesState state,
  required BuildContext context,
  required Message message,
  required RiderProfile riderProfile,
}) {
  final isCurrentUser = message.sender == riderProfile.name;
  var isRequestVisible = false;
  if (message.messageType == MessageType.INSTRUCTOR_REQUEST ||
      message.messageType == MessageType.STUDENT_HORSE_REQUEST ||
      message.messageType == MessageType.STUDENT_REQUEST ||
      message.messageType == MessageType.STUDENT_REQUEST) {
    isRequestVisible =
        context.read<MessagesCubit>().isRequestVisible(message: message);
    debugPrint('isRequestVisible: $isRequestVisible');
  }
  final isDark = SharedPrefs().isDarkMode;
  // if (!isCurrentUser) {
  //   if (message.messageType == MessageType.INSTRUCTOR_REQUEST ||
  //       message.messageType == MessageType.STUDENT_HORSE_REQUEST) {
  //     isRequestVisible = true;
  //   }
  // }


  return Padding(
    // asymmetric padding
    padding: EdgeInsets.fromLTRB(
      isCurrentUser ? 64.0 : 16.0,
      4,
      isCurrentUser ? 16.0 : 64.0,
      4,
    ),
    child: Align(
      // align the child within the container
      alignment: isCurrentUser ? Alignment.bottomRight : Alignment.bottomLeft,
      child: Column(
        crossAxisAlignment:
            isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            // chat bubble decoration
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? HorseAndRidersTheme().getTheme().primaryColor
                  : isDark
                      ? HorseAndRidersTheme().getTheme().colorScheme.secondary
                      : Colors.grey[300],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    message.message ?? '',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: isCurrentUser ? Colors.white : Colors.black87,
                        ),
                  ),
                  Visibility(
                    visible: isRequestVisible,
                    child: _acceptRequestButton(
                      riderProfile: riderProfile,
                      state: state,
                      context: context,
                      message: message,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Text(
            !isCurrentUser ? message.sender as String : 'You',
            textAlign: isCurrentUser ? TextAlign.end : TextAlign.start,
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            calculateTimeDifferenceBetween(
              referenceDate: message.date as DateTime,
            ),
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}

// FIXME(mfrenchy77): having an issue with updating a message with a requestItem
//widget that adds a button to the message to accept request
Widget _acceptRequestButton({
  required RiderProfile riderProfile,
  required BuildContext context,
  required Message message,
  required MessagesState state,
}) {
  final isAccepted = message.requestItem?.isSelected ?? false;
  return ElevatedButton(
    onPressed: isAccepted
        ? null
        : () => context
            .read<MessagesCubit>()
            .acceptRequest(message: message, context: context),
    child: state.acceptStatus == AcceptStatus.loading
        ? const CircularProgressIndicator()
        : Text(isAccepted ? 'Accepted' : 'Accept Request'),
  );
}

class TextBar extends StatefulWidget {
  const TextBar({
    super.key,
    required this.state,
  });
  final MessagesState state;
  @override
  State<TextBar> createState() => TextBarState();
}

class TextBarState extends State<TextBar> {
  TextEditingController textBarController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
    return Stack(
      children: <Widget>[
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 60,
            width: double.infinity,
            color: isDark ? Colors.grey.shade800 : Colors.white,
            child: Row(
              children: <Widget>[
                const SizedBox(
                  width: 15,
                ),
                Expanded(
                  child: TextFormField(
                    controller: textBarController,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (value) {
                      context.read<MessagesCubit>().textChanged(value);
                    },
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        color: HorseAndRidersTheme().getTheme().primaryColor,
                        onPressed: widget.state.text.isEmpty
                            ? null
                            : () {
                                textBarController.clear();
                                context.read<MessagesCubit>().sendMessage();
                              },
                        icon: const Icon(
                          Icons.send,
                        ),
                      ),
                      hintText: 'Write message...',
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white : Colors.black54,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                // const SizedBox(
                //   width: 15,
                // ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
