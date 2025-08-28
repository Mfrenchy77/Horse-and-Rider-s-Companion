import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/MainPages/Messages/Widgets/accept_request_button.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
import 'package:horseandriderscompanion/Utilities/util_methods.dart';

/// A single message in a conversation
class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });
  final Message message;
  final bool isCurrentUser;
  @override
  Widget build(BuildContext context) {
    final isDark = SharedPrefs().isDarkMode;
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
                            color:
                                isCurrentUser ? Colors.white : Colors.black87,
                          ),
                    ),
                    Visibility(
                      visible: context
                          .read<AppCubit>()
                          .isRequestVisible(message: message),
                      child: AcceptRequestButton(
                        message: message,
                        key: const Key('AcceptRequestButton'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Text(
              !isCurrentUser ? message.sender ?? 'Unknown' : 'You',
              textAlign: isCurrentUser ? TextAlign.end : TextAlign.start,
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              calculateTimeDifferenceBetween(
                referenceDate: message.date,
              ),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
