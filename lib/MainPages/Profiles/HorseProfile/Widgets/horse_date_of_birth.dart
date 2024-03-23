import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:intl/intl.dart';

class HorseDateOfBirth extends StatelessWidget {
  const HorseDateOfBirth({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        return Row(
          children: [
            const Expanded(
              flex: 5,
              child: Text('Date of Birth: '),
            ),
            Expanded(
              flex: 5,
              child: Text(
                DateFormat('MMMM d yyyy').format(
                  state.horseProfile?.dateOfBirth ?? DateTime.now(),
                ),
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
