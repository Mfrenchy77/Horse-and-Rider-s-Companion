// // ignore_for_file: cast_nullable_to_non_nullable, lines_longer_than_80_chars

// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/CommonWidgets/profile_photo.dart';
// import 'package:horseandriderscompanion/MainPages/Messages/Dialogs/mesage_contact_search_dialog.dart';
// import 'package:horseandriderscompanion/MainPages/Messages/cubit/messages_cubit.dart';
// import 'package:horseandriderscompanion/Utilities/SharedPreferences/shared_prefs.dart';
// import 'package:horseandriderscompanion/Utilities/util_methodsd.dart';

// class MessagesListView extends StatelessWidget {
//   const MessagesListView({
//     super.key,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final cubit = context.read<MessagesCubit>();
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Messages: - ${cubit.sortedMessagesText()}',
//           ),
//           groupsList(
//             context: context,
//             state: state,
//             riderProfile: userProfile,
//           ),
//         ],
//       ),
//     );
//   }
// }

// Widget groupsList({
//   required BuildContext context,
//   required MessagesState state,
//   required RiderProfile riderProfile,
// }) {
//   debugPrint('List Size: ${state.groups.length}');
//   return ListView.builder(
//     shrinkWrap: true,
//     itemCount: state.groups.length,
//     itemBuilder: (context, index) {
//       final group = state.groups[index];
//       return _groupItem(
//         context: context,
//         group: group,
//         state: state,
//         userProfile: riderProfile,
//       );
//     // },
//   );
// }

// Widget _groupItem({
//   required BuildContext context,
//   required Group? group,
//   required MessagesState state,
//   required RiderProfile userProfile,
// }) {
//   final isDark = SharedPrefs().isDarkMode;
//   final parties = group?.parties?..remove(userProfile.name);
//   final partiesList = parties?.join(', ');
//   debugPrint('Parties: $partiesList');
//   final textColor = group?.messageState == MessageState.UNREAD
//       ? isDark
//           ? Colors.white
//           : Colors.black
//       : isDark
//           ? Colors.grey.shade400
//           : Colors.grey.shade600;
//   return group != null
//       ? ListTile(
//           onTap: () => context.read<MessagesCubit>().openOrNewMessage(group),
//           trailing: Text(
//             calculateTimeDifferenceBetween(
//               referenceDate: group.lastEditDate,
//             ),
//             style: TextStyle(color: textColor),
//           ),
//           leading: ProfilePhoto(
//             size: 40,
//             profilePicUrl: group.recentMessage?.senderProfilePicUrl,
//           ),
//           title: Text(
//             partiesList ?? 'Unknown',
//             style: TextStyle(
//               color: textColor,
//             ),
//           ),
//           subtitle: Text(
//             group.recentMessage?.sender == userProfile.name
//                 ? 'You: ${group.recentMessage?.message}'
//                 : group.recentMessage?.message ?? '',
//             style: TextStyle(color: textColor, fontSize: 12),
//           ),
//         )
//       : const Text('No Messages');
// }
