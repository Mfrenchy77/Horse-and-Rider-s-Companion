// ignore_for_file: non_constant_identifier_names

import 'package:intl/intl.dart';
// ignore: library_prefixes
import 'package:timeago/timeago.dart' as timeAgo;

String calculateTimeDifferenceBetween({required DateTime referenceDate}) {
  final now = DateTime.now();
  final difference = now.difference(referenceDate);
  return timeAgo.format(
    now.subtract(difference),
    allowFromNow: true,
    locale: 'en_short',
  );

  // final seconds = now.difference(referenceDate).inSeconds;
  // if (seconds < 60) {
  //   return '$seconds second';
  // } else if (seconds >= 60 && seconds < 3600) {
  //   return '${now.difference(referenceDate).inMinutes.abs()} minutes ago';
  // } else if (seconds >= 3600 && seconds < 86400) {
  //   return '${now.difference(referenceDate).inHours} hours ago';
  // } else {
  //   return '${now.difference(referenceDate).inDays} days ago';
  // }
}

extension HHmm on Duration {
  String formatHHmm() {
    //1:34:00.000000
    final str = toString();

    final texts = str.split(':');
    final textHour = texts[0].padLeft(2, '0');
    final textMinute = texts[1].padLeft(2, '0');

    return '${textHour}h ${textMinute}m';
  }
}

extension FormatNumber on int {
  String formatDecimalThousand() {
    //1403 -> 1,403
    final f = NumberFormat.decimalPattern('en_US');
    return f.format(this);
  }
}

extension FormatDate on int {
  String MMM_dd_yyyy() {
    return DateFormat('MMM dd, yyyy')
        .format(DateTime.fromMillisecondsSinceEpoch(this * 1000));
  }
}
