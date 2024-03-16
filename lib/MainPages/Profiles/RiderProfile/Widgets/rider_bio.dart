import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

class RiderBio extends StatelessWidget {
  const RiderBio({super.key, required this.bio});
  final String? bio;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: MaxWidthBox(
        maxWidth: MediaQuery.of(context).size.width * 0.8,
        child: Text(
          bio ?? 'Bio not available',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
