// // ignore_for_file: cast_nullable_to_non_nullable

// import 'package:authentication_repository/authentication_repository.dart';
// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/Home/Home/bloc/home_cubit.dart';
// import 'package:horseandriderscompanion/Home/RiderProfile/Views/profile_view.dart';

// class RiderProfileViewerPage extends StatelessWidget {
//   const RiderProfileViewerPage({
//     super.key,
//   });
//   static const String routeName = '/riderProfileViewer';
//   @override
//   Widget build(BuildContext context) {
//     final args =
//         ModalRoute.of(context)!.settings.arguments as RiderProfileViewerArgs;
//     final state = args.state;
//     final riderProfile = args.riderProfile;
//     final usersProfile = args.usersProfile;
//     final user = args.user;

//     return BlocProvider(
//       create: (context) => HomeCubit(
//         user: user,
//         messagesRepository: context.read<MessagesRepository>(),
//         skillTreeRepository: context.read<SkillTreeRepository>(),
//         horseProfileRepository: context.read<HorseProfileRepository>(),
//         riderProfileRepository: context.read<RiderProfileRepository>(),
//         resourcesRepository: context.read<ResourcesRepository>(),
//         // catagorryRepository: context.read<CatagorryRepository>(),
//         // skillsRepository: context.read<SkillsRepository>(),
//         // levelsRepository: context.read<LevelsRepository>(),
//       ),
//       child: ProfileView(
//         state: state,
//         usersProfile: usersProfile,
//         buildContext: context,
//         riderProfile: riderProfile,
//         user: user,
//       ),
//     );
//   }
// }

// class RiderProfileViewerArgs {
//   RiderProfileViewerArgs({
//     required this.riderProfile,
//     required this.usersProfile,
//     required this.state,
//     required this.user,
//   });
//   final RiderProfile riderProfile;
//   final RiderProfile usersProfile;
//   final HomeState state;
//   final User user;
// }
