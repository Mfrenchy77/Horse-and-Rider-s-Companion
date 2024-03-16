import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:responsive_framework/responsive_framework.dart';

class GuestWelcomeText extends StatelessWidget {
  const GuestWelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return const SingleChildScrollView(
          child: Center(
            child: MaxWidthBox(
              maxWidth: 1000,
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  textAlign: TextAlign.center,
                  "Welcome to Horse & Rider's Companion, the definitive"
                  ' platform for riders and horse owners dedicated to '
                  'enhancing their equestrian skills and knowledge.'
                  ' \n\nAs a guest, you have the opportunity to explore an'
                  ' array of features designed to support your riding '
                  'journey. Delve into our comprehensive skill tree to '
                  'gain insights into various aspects of horse riding '
                  'and care. Browse through a curated selection of'
                  ' articles and videos, meticulously linked to specific'
                  ' skills, providing you with valuable resources for focused'
                  " learning.\n\n Discover our unique 'Training Paths', "
                  'crafted by experienced trainers and instructors, to '
                  'guide you through structured learning experiences. '
                  "Although you're currently exploring as a guest, a full "
                  'membership offers personalized tracking of your progress, '
                  'the ability to assign instructors for skill validation,'
                  ' and a more connected equestrian community experience.'
                  ' We invite you to join us and fully immerse yourself in'
                  ' the world of '
                  "Horse & Rider's Companion, where your passion for horse "
                  'riding and care is our utmost priority.',
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
