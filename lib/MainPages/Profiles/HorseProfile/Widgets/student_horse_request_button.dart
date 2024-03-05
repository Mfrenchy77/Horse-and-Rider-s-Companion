import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';

class StudentHorseRequestButton extends StatelessWidget {
  const StudentHorseRequestButton({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    return Visibility(
      visible: !cubit.isOwner(),
      child: ElevatedButton(
        onPressed: cubit.requestToBeStudentHorse,
        child: Text(
          cubit.isStudentHorse()
              ? 'Remove Horse as Student'
              : 'Request to be Student Horse',
        ),
      ),
    );
  }
}
