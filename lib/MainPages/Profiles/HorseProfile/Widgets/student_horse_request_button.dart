import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class StudentHorseRequestButton extends StatelessWidget {
  const StudentHorseRequestButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return cubit.isOwner() || state.isGuest
            ? const SizedBox()
            : Tooltip(
                message: cubit.isStudentHorse()
                    ? 'Remove Horse as Student'
                    : 'Request to be Student Horse',
                child: OutlinedButton(
                  onPressed: cubit.requestToBeStudentHorse,
                  child: Text(
                    cubit.isStudentHorse()
                        ? 'Remove Horse as Student'
                        : 'Request to be Student Horse',
                  ),
                ),
              );
      },
    );
  }
}
