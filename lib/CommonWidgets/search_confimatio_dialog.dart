import 'package:flutter/material.dart';

/// Confirmation Dialog when user selects item from the search bar
/// with on tap callback
Widget searchConfirmationDialog({
  required String text,
  required String title,
  required GestureTapCallback cancelTap,
  required GestureTapCallback confirmTap,
}) {
  return AlertDialog(
    title: Text(title),
    content: Text(text),
    actions: [
      TextButton(
        onPressed: () => cancelTap(),
        child: const Text('Cancel'),
      ),
      TextButton(
        onPressed: () => confirmTap(),
        child: const Text('Ok'),
      ),
    ],
  );
}
