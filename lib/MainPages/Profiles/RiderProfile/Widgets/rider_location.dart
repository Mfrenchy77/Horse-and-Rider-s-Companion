import 'package:flutter/material.dart';

class RiderLocation extends StatelessWidget {
  const RiderLocation({super.key, required this.locationName});
  final String? locationName;
  @override
  Widget build(BuildContext context) {
    final displayText = (locationName?.isNotEmpty ?? false)
        ? locationName!
        : 'Location not available';
    return Center(
      child: Text(
        displayText,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
