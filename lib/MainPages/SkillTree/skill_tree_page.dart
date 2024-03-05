import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Bloc/app_cubit.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/Navigator/navigator_view.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/cubit/skill_tree_cubit.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({super.key});

  static const routeName = '/skillTree';
  static Page<void> page() => const MaterialPage<void>(child: SkillTreePage());
  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const SkillTreePage());
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as SkillTreePageArguments?;
    final isGuest = args?.isGuest;
    final isViewing = args?.isViewing;
    final isForRider = args?.isForRider;
    return BlocProvider(
      create: (context) => SkillTreeCubit(
        isGuest: isGuest ?? false,
        isViewing: isViewing ?? false,
        isForRider: isForRider ?? true,
      ),
      child: const NavigatorView(
        body: fakeSkillTreePage(),
      ),
    );
  }
}

/// Arguments holder class for [SkillTreePage].
class SkillTreePageArguments {
  SkillTreePageArguments({
    required this.isGuest,
    required this.isViewing,
    required this.isForRider,
  });
  final bool isGuest;
  final bool isViewing;
  final bool isForRider;
}

class fakeSkillTreePage extends StatelessWidget {
  const fakeSkillTreePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SkillTreeCubit, SkillTreeState>(
      builder: (context, state) {
        return Center(
          child: Column(
            children: [
              Text(
                'SkillTreePage for ${state.isForRider ? 'Riderider' : 'Horse'}',
              ),
              gap(),
              FilledButton(
                onPressed: () => context.read<AppCubit>().test('Skill Tree'),
                child: const Text('Test'),
              ),
            ],
          ),
        );
      },
    );
  }
}
