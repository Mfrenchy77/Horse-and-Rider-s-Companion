import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Widgets/skill_node_card.dart';

class TrainingPathView extends StatelessWidget {
  const TrainingPathView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      builder: (context, state) {
        final scrollController = ScrollController();
        debugPrint('Training Path View: ${state.trainingPath?.name}');
        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            children: [
              Text(state.trainingPath?.name ?? 'Select a Training Path'),
              gap(),
              Text(state.trainingPath?.description ?? ''),
              smallGap(),
              SizedBox(
                width: MediaQuery.of(context).size.width * .08,
                child: const Divider(color: Colors.black, thickness: 2),
              ),
              Scrollbar(
                trackVisibility: true,
                thickness: 6,
                thumbVisibility: true,
                controller: scrollController,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      children: state.trainingPath?.skillNodes
                              .where(
                                (element) =>
                                    element!.parentId?.isEmpty ?? false,
                              )
                              .map(
                                (e) => SkillNodeCard(
                                  skillNode: e,
                                ),
                              )
                              .toList() ??
                          [const Text('')],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
