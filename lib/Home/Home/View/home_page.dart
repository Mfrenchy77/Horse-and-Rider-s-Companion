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
    final horseId = args?.horseId;
    final viewingProfile = args?.viewingProfile;
    final user = context.select((AppBloc bloc) => bloc.state.user);
    debugPrint('Viewing Profile: ${viewingProfile?.name}');
    return Scaffold(
      body: BlocProvider(
        create: (context) => HomeCubit(
          user: user,
          horseId: horseId,
          viewingProfile: viewingProfile,
          messagesRepository: context.read<MessagesRepository>(),
          skillTreeRepository: context.read<SkillTreeRepository>(),
          resourcesRepository: context.read<ResourcesRepository>(),
          horseProfileRepository: context.read<HorseProfileRepository>(),
          riderProfileRepository: context.read<RiderProfileRepository>(),
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

/// Arguments holder class for [HomePage].
class HomePageArguments {
  HomePageArguments({required this.viewingProfile, required this.horseId});
  final String? horseId;
  final RiderProfile? viewingProfile;
}
