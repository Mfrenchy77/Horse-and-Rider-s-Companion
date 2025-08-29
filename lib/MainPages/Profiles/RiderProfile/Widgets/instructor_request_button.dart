import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

/// Button that says "Request to be Instructor" or "Remove Instructor"
/// depending on the if the user is in the viewingProfile's student list
/// Also, only visible if the viewingProfile is in instructor
///  and not null(UsersProfile).
class InstructorRequestButton extends StatelessWidget {
  const InstructorRequestButton({super.key, required this.profile});

  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        if (state.isGuest ||
            state.viewingProfile == null ||
            profile.email == state.usersProfile!.email ||
            !(state.viewingProfile!.isTrainer ?? false)) {
          return const SizedBox.shrink();
        }

        final isAlreadyInstructor = state.viewingProfile!.students
                ?.any((element) => element.id == state.usersProfile!.email) ??
            false;

        return Tooltip(
          message: isAlreadyInstructor
              ? 'Remove from Instructors'
              : 'Add to Instructors',
          child: ElevatedButton.icon(
            key: const Key('instructor_request_button'),
            icon: const Icon(Icons.person_add),
            onPressed: () {
              if (isAlreadyInstructor) {
                cubit.removeInstructor(
                  instructorProfile: state.viewingProfile!,
                );
              } else {
                cubit.createInstructorRequest(
                  instructorProfile: state.viewingProfile!,
                );
              }
            },
            label: Text(
              isAlreadyInstructor
                  ? 'Remove Instructor'
                  : 'Request to add as Instructor',
            ),
          ),
        );
      },
    );
  }
}
