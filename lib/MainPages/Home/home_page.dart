// import 'package:database_repository/database_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
// import 'package:horseandriderscompanion/MainPages/Home/cubit/home_cubit.dart';
// import 'package:horseandriderscompanion/MainPages/Home/home_view.dart';

// class HomePage extends StatelessWidget {
//   const HomePage({super.key});

//   static const routeName = '/home';

//   static Page<void> page() => const MaterialPage<void>(child: HomePage());

//   static Route<void> route() {
//     return MaterialPageRoute<void>(builder: (_) => const HomePage());
//   }

//   @override
//   Widget build(BuildContext context) {
//     final args =
//         ModalRoute.of(context)!.settings.arguments as HomePageArguments?;

//     final horseId = args?.horseId;
//     final usersProfile = args?.usersProfile;
//     final viewingProfile = args?.viewingProfile;
//     final user = context.select((AppBloc bloc) => bloc.state.user);

//     return BlocProvider(
//       create: (context) => HomeCubit(
//         user: user,
//         horseId: horseId,
//         usersProfile: usersProfile,
//         viewingProfile: viewingProfile,
//         messagesRepository: MessagesRepository(),
//         resourcesRepository: ResourcesRepository(),
//         skillTreeRepository: SkillTreeRepository(),
//         horseProfileRepository: HorseProfileRepository(),
//         riderProfileRepository: RiderProfileRepository(),
//       ),
//       child: const HomeView(
//         key: Key('HomeView'),
//       ),
//     );
//   }
// }

// /// Arguments holder class for [HomePage].
// class HomePageArguments {
//   HomePageArguments({
//     required this.horseId,
//     required this.usersProfile,
//     required this.viewingProfile,
//   });
//   final String? horseId;
//   final RiderProfile? usersProfile;
//   final RiderProfile? viewingProfile;
// }
