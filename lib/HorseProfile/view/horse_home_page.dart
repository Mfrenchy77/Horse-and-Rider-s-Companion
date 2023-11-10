import 'package:authentication_repository/authentication_repository.dart';
import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/HorseProfile/cubit/horse_profile_cubit.dart';
import 'package:horseandriderscompanion/HorseProfile/view/horse_home_view.dart';

class HorseHomePage extends StatelessWidget {
  const HorseHomePage({
    super.key,
  });

  static const routeName = '/horseHome';
  static Page<void> page() => const MaterialPage<void>(child: HorseHomePage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const HorseHomePage());
  }

  /// we want to chage this so users that are null or not logged in
  ///  can view horse pages but not edit them
  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as HorseHomePageArgs?;
    final user = args?.user;
    final usersProfile = args?.usersProfile;
    final horseProfileId = args!.horseProfileId!;
    final isOwned = usersProfile?.ownedHorses
            ?.any((element) => element.id == horseProfileId) ??
        false;

    return Scaffold(
      body: BlocProvider(
        create: (context) => HorseHomeCubit(
          messagesRepository: context.read<MessagesRepository>(),
          skillTreeRepository: context.read<SkillTreeRepository>(),
          isOwned: isOwned,
          riderProfileRepository: context.read<RiderProfileRepository>(),
          usersProfile: usersProfile,
          horseId: horseProfileId,
          horseProfileRepository: context.read<HorseProfileRepository>(),
        ),
        child: HorseHomeView(
          usersProfile: usersProfile,
        ),
      ),
    );
  }
}

class HorseHomePageArgs {
  const HorseHomePageArgs({
    required this.horseProfileId,
    required this.usersProfile,
    required this.user,
  });

  final User? user;
  final RiderProfile? usersProfile;
  final String? horseProfileId;
}
