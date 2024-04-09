import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_level_progress_bar.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_resources_list.dart';

class SkillLevelView extends StatelessWidget {
  const SkillLevelView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        return state.skill == null
            ? const Center(
                child: Text('No Skill Selected'),
              )
            : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 50,
                        ),
                        Visibility(
                          visible: state.isGuest,
                          child: const Text(
                            'This is where you will be able to track your '
                            'progress for this skill. There will be '
                            'information for each skill that explains '
                            'what is expected for "Learning" and "Proficient"',
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Text(
                          state.skill?.skillName ?? '',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        gap(),
                        Text(
                          cubit.getLevelProgressDescription(),
                          textAlign: TextAlign.center,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: Divider(),
                        ),
                        smallGap(),
                        Text(state.skill?.description ?? ''),
                        smallGap(),
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: Divider(),
                        ),
                        const Text(
                          'Resources',
                          style: TextStyle(fontSize: 20),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 20, right: 20),
                          child: Divider(),
                        ),
                        smallGap(),
                        const SkillResouresList(
                          key: Key('skillResourcesList'),
                        ),
                        smallGap(),
                        const SizedBox(
                          height: 50,
                        ),
                      ],
                    ),
                  ),

                  // ProgressBar at the top

                  // hide the progress bar if the
                  Visibility(
                    visible: state.skill != null,
                    child: const Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SkillLevelProgressBar(
                        key: Key('skillLevelProgressBar'),
                      ),
                    ),
                  ),
                ],
              );
      },
    );
  }
}
