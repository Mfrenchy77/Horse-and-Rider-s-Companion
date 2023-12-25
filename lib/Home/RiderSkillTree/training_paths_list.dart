import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';

Widget trainingPathsList() {
  return BlocBuilder<HomeCubit, HomeState>(
    buildWhen: (previous, current) {
      return previous.trainingPaths != current.trainingPaths;
    },
    builder: (context, state) {
      final homeCubit = context.read<HomeCubit>();
      return ListView.builder(
        itemCount: state.trainingPaths.length,
        itemBuilder: (context, index) {
          final trainingPath = state.trainingPaths[index];
          return Card(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(trainingPath?.createdBy ?? ''),
                ListTile(
                  onTap: () {
                    homeCubit.trainingPathSelected(trainingPath: trainingPath);
                  },
                  title: Text(trainingPath?.name ?? ''),
                  subtitle: Text(trainingPath?.description ?? ''),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
