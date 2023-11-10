// ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
import 'package:horseandriderscompanion/Messages/cubit/messages_cubit.dart';
import 'package:horseandriderscompanion/Messages/view/mesage_contact_search_dialog.dart';
import 'package:horseandriderscompanion/generated/l10n.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:horseandriderscompanion/utils/my_formatter.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GroupsList extends StatelessWidget {
  const GroupsList({
    super.key,
    required this.userProfile,
    required this.state,
    required this.messagesCubit,
  });
  final RiderProfile userProfile;
  final MessagesState state;
  final MessagesCubit messagesCubit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).messages_text),
        actions: [
          ResponsiveVisibility(
            visibleConditions:  [
              Condition.smallerThan(name: TABLET,value: 800),
            ],
            hiddenConditions:  [
              Condition.largerThan(name: TABLET,value: 800),
            ],
            child: PopupMenuButton<String>(
              itemBuilder: (context) => <PopupMenuEntry<String>>[
                const PopupMenuItem(
                    value: 'Sort Messages', child: Text('Sort Messages'),),
              ],
              onSelected: (value) {
                if (value == 'Sort Messages') {
                  messagesCubit.openSortDialog(
                    context: context,
                  );
                }
              },
              //  {
              //   return [
              //     PopupMenuItem<String>(
              //       child: const Text('Sort Messages'),
              //       onTap: () => messagesCubit.openSortDialog(
              //         context: context,
              //       ),
              //     ),
              //   ];
              // },
            ),
          ),
          ResponsiveVisibility(
            visibleConditions:  [
              Condition.largerThan(name: TABLET,value: 800),
            ],
            hiddenConditions:  [
              Condition.smallerThan(name: TABLET,value: 800),
            ],
            child: Row(
              children: [
                MenuItemButton(
                  leadingIcon: const Icon(Icons.sort),
                  child: const Text('Sort Messages'),
                  onPressed: () => messagesCubit.openSortDialog(
                    context: context,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${S.of(context).messages_text}: - ${messagesCubit.sortedMessagesText()}',
            ),
            groupsList(
              context: context,
              state: state,
              riderProfile: userProfile,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.mail),
        onPressed: () {
          showDialog<MesssageContactsSearchDialog>(
            context: context,
            builder: (context) => MesssageContactsSearchDialog(
              user: userProfile,
            ),
          );
        },
      ),
    );
  }
}

Widget groupsList({
  required BuildContext context,
  required MessagesState state,
  required RiderProfile riderProfile,
}) {
  debugPrint('List Size: ${state.groups.length}');
  return ListView.builder(
    shrinkWrap: true,
    itemCount: state.groups.length,
    itemBuilder: (context, index) {
      final group = state.groups[index];
      return _groupItem(
        context: context,
        group: group,
        state: state,
        userProfile: riderProfile,
      );
    },
  );
}

Widget _groupItem({
  required BuildContext context,
  required Group? group,
  required MessagesState state,
  required RiderProfile userProfile,
}) {
  final isDark = SharedPrefs().isDarkMode;
  final parties = group?.parties?..remove(userProfile.name);
  final partiesList = parties?.join(', ');
  debugPrint('Parties: $partiesList');
  final textColor = group?.messageState == MessageState.UNREAD
      ? isDark
          ? Colors.white
          : Colors.black
      : isDark
          ? Colors.grey.shade400
          : Colors.grey.shade600;
  return group != null
      ? ListTile(
          onTap: () => context.read<MessagesCubit>().openOrNewMessage(group),
          trailing: Text(
            calculateTimeDifferenceBetween(
              referenceDate: group.lastEditDate,
            ),
            style: TextStyle(color: textColor),
          ),
          leading: profilePhoto(
            size: 40,
            profilePicUrl: group.recentMessage?.senderProfilePicUrl,
          ),
          title: Text(
            partiesList ?? S.of(context).messages_unknown,
            style: TextStyle(
              color: textColor,
            ),
          ),
          subtitle: Text(
            group.recentMessage?.sender == userProfile.name
                ? '${S.of(context).messages_you_text}: ${group.recentMessage?.message}'
                : group.recentMessage?.message ?? '',
            style: TextStyle(color: textColor, fontSize: 12),
          ),
        )
      : Text(S.of(context).messages_none);
}
