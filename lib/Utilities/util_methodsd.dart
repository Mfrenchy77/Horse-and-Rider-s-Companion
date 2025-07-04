// ignore_for_file: non_constant_identifier_names

import 'package:intl/intl.dart';
// ignore: library_prefixes
import 'package:timeago/timeago.dart' as timeAgo;

String calculateTimeDifferenceBetween({required DateTime? referenceDate}) {
  if (referenceDate != null) {
    final now = DateTime.now();
    final difference = now.difference(referenceDate);
    return timeAgo.format(
      now.subtract(difference),
      allowFromNow: true,
      locale: 'en_short',
    );
  } else {
    return '';
  }
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

/// Capitalize the first letter of each word in a string [input]
/// and return the result
String capitalizeWords(String input) {
  // Split the string into words
  final words = input.split(' ');
  // Capitalize the first letter of each word
  final capitalizedWords = words.map((word) {
    if (word.isEmpty) return '';
    // Capitalize the first letter and add the rest of the letters
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  });
  // Join the words back into a single string
  return capitalizedWords.join(' ');
}

/// Convert centimeters into hands and inches as a decimal
int cmToHands(int cm) {
  final inches = cm / 2.54;
  final hands = inches ~/ 4;
  return hands;
}

// Convert centimeters to hands as a whole number and inches as a decimal part.
double cmToHandsAndInches(int cm) {
  final inchesTotal = cm / 2.54;
  final hands = inchesTotal / 4;
  return hands;
}

/// Convert centemeters into hands and return the remainder. should be 0-3
/// as the remainder is the inches
int cmToHandsRemainder(int cm) {
  final inches = cm / 2.54;
  final remainderInches = inches % 4;
  return remainderInches.toInt();
}

int handsAndInchesToCm(int hands, int inches) {
  final totalInches = hands * 4 + inches;
  final cm = totalInches * 2.54;
  return cm.toInt();
}

int handsToCm(int hands) {
  // Conversion formula from hands to cm
  final cm = hands * (4 * 2.54);
  return cm.roundToDouble().toInt();
}
