import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';

/// Button that says "Request to an Instructor" or "Remove Student"
/// depending on the if the user is in the viewingProfile's instructor list
///
class StudentRequestButton extends StatelessWidget {
  const StudentRequestButton({super.key, required this.profile});

  final RiderProfile profile;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        if (state.isGuest ||
            state.viewingProfile == null ||
            profile.email == state.usersProfile!.email ||
            !(state.usersProfile!.isTrainer ?? false)) {
          return const SizedBox.shrink();
        } else {
          final isAlreadyStudent = state.viewingProfile!.instructors
                  ?.any((element) => element.id == state.usersProfile!.email) ??
              false;

          return Tooltip(
            message:
                isAlreadyStudent ? 'Remove from Students' : 'Add to Students',
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              onPressed: () {
                if (isAlreadyStudent) {
                  cubit.removeStudent(studentProfile: state.viewingProfile!);
                } else {
                  cubit.createStudentRequest(
                    studentProfile: state.viewingProfile!,
                  );
                }
              },
              label: Text(
                isAlreadyStudent
                    ? 'Remove Student'
                    : 'Request to add as Student',
              ),
            ),
          );
        }
      },
    );
  }
}
