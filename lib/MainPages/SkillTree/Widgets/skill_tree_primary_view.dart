// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/App/app.dart';
// import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';
// import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/training_path_view.dart';

// class SkillTreePrimaryView extends StatelessWidget {
//   const SkillTreePrimaryView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppCubit, AppState>(
//       buildWhen: (previous, current) =>
//           previous.skillTreeNavigation != current.skillTreeNavigation,
//       builder: (context, state) {
//         final cubit = context.read<AppCubit>();
//         switch (state.skillTreeNavigation) {
//           case SkillTreeNavigation.TrainingPath:
//             return TrainingPathView(
//               trainingPathId: cubit.getSelectedTrainingPathId(),
//               key: const Key('TrainingPathView'),
//             );
//           case SkillTreeNavigation.SkillLevel:
//             return const SkillLevelView(
//               // skillId: cubit.getSelectedSkillId(),
//               key: Key('SkillLevelView'),
//             );
//           case SkillTreeNavigation.TrainingPathList:
//             return TrainingPathView(
//               trainingPathId: cubit.getSelectedTrainingPathId(),
//               key: const Key('TrainingPathView'),
//             );
//           case SkillTreeNavigation.SkillList:
//             return const SkillLevelView(
//               //skillId: cubit.getSelectedSkillId(),
//               key: Key('SkillLevelView'),
//             );
//         }
//       },
//     );
//   }
// }
