import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_bloc.dart';
import 'package:horseandriderscompanion/Home/Home/View/home_view.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const routeName = '/riderHome';

  static Page<void> page() => const MaterialPage<void>(child: HomePage());

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HomePage());
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as HomePageArguments?;
    final viewingProfile = args?.viewingProfile;
    final user = context.select((AppBloc bloc) => bloc.state.user);
    debugPrint('Viewing Profile: ${viewingProfile?.name}');
    return Scaffold(
      body: BlocProvider(
        create: (context) => HomeCubit(
          viewingProfile: viewingProfile,
          user: user,
          skillTreeRepository: context.read<SkillTreeRepository>(),
          messagesRepository: context.read<MessagesRepository>(),
          horseProfileRepository: context.read<HorseProfileRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
          resourcesRepository: context.read<ResourcesRepository>(),
        ),
        child: HomeView(
          viewingProfile: viewingProfile,
          user: user,
          buildContext: context,
        ),
      ),
    );
  }
}

class HomePageArguments {
  HomePageArguments({required this.viewingProfile});

  final RiderProfile? viewingProfile;
}
