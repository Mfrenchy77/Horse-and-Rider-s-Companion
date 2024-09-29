import 'package:flutter/material.dart';

Widget onboardingDialog({
  required Widget title,
  required String description,
  required VoidCallback onNext,
  required VoidCallback skipOnboarding,
}) {
  return Dialog(
    backgroundColor: Colors.transparent,
    child: Container(
      padding: const EdgeInsets.all(24),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          title,
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
              ElevatedButton(
                onPressed: onNext,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
