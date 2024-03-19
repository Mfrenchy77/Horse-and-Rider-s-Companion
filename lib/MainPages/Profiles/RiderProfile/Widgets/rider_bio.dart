import 'package:flutter/material.dart';

class RiderBio extends StatelessWidget {
  const RiderBio({super.key, required this.bio});
  final String? bio;
  @override
  Widget build(BuildContext context) {
    return bio != null && bio!.isNotEmpty
        ? Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              bio!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          )
        : const Text(
            'Bio not available',
            style: TextStyle(fontSize: 16),
          );
  }
}
