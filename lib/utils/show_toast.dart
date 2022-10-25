import 'package:flutter/material.dart';

class ShowToast {
  ShowToast(BuildContext context, String s) {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(SnackBar(content: Text(s)));
  }
}
