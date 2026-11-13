// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/App/app.dart';
// import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_view.dart';

// class SkillTreePrimaryView extends StatelessWidget {
//   const SkillTreePrimaryView({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<AppCubit, AppState>(
//       buildWhen: (previous, current) =>
//           previous.skillTreeNavigation != current.skillTreeNavigation,
//       builder: (context, state) {
//         switch (state.skillTreeNavigation) {
//           case SkillTreeNavigation.SkillLevel:
//             return const SkillLevelView(
//               // skillId: cubit.getSelectedSkillId(),
//               key: Key('SkillLevelView'),
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
