// ignore_for_file: cast_nullable_to_non_nullable

import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/HorseProfile/cubit/horse_profile_cubit.dart';
import 'package:horseandriderscompanion/shared_prefs.dart';
import 'package:intl/intl.dart';

class LogView extends StatelessWidget {
  const LogView({
    super.key,
    required this.state,
    required this.horseState,
    required this.isRider,
  });
  final HomeState? state;
  final HorseHomeState? horseState;
  final bool isRider;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isRider ? 'Rider Log' : 'Horse Log'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _logBookList(
                horseProfile: horseState?.horseProfile,
                isRider: isRider,
                context: context,
                profile: state?.viewingProfile ?? state?.usersProfile!,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _logBookList({
  required BuildContext context,
  required RiderProfile? profile,
  required bool isRider,
  required HorseProfile? horseProfile,
}) {
  final notes = isRider ? profile?.notes : horseProfile?.notes;

  if (notes != null || notes!.isNotEmpty) {
    notes.sort((a, b) => a.date?.compareTo(b.date as DateTime) ?? 0);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return _noteItem(note: note);
      },
    );
  } else {
    return const Text('No Entries in the Log');
  }
}

Widget _noteItem({required BaseListItem note}) {
  final isDark = SharedPrefs().isDarkMode;
  debugPrint('Message length: ${note.name?.length}');

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      IntrinsicHeight(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('dd-MM-yyyy').format(note.date ?? DateTime.now()),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            Expanded(
              child: VerticalDivider(
                thickness: 2,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Expanded(
              flex: 7,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  overflow: TextOverflow.visible,
                  note.name ?? '',
                  textAlign: TextAlign.start,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
