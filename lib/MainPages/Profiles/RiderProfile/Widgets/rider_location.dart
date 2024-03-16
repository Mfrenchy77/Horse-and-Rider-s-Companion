import 'package:flutter/material.dart';

class RiderLocation extends StatelessWidget {
  const RiderLocation({super.key, required this.locationName});
  final String? locationName;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        locationName ?? 'Location not available',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
