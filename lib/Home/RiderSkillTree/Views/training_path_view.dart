import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/Home/Home/cubit/home_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';

Widget trainingPathView() {
  return BlocBuilder<HomeCubit, HomeState>(
    builder: (context, state) {
      final homeCubit = context.read<HomeCubit>();
      final scrollController = ScrollController();

      return Scrollbar(
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
                      .where((element) => element!.parentId?.isEmpty ?? false)
                      .map(
                        (e) => _skillNodeCard(
                          context: context,
                          state: state,
                          homeCubit: homeCubit,
                          skillNode: e,
                        ),
                      )
                      .toList() ??
                  [const Text('No Skill Found')],
            ),
          ),
        ),
      );
    },
  );
}

Widget _skillNodeCard({
  required SkillNode? skillNode,
  required HomeCubit homeCubit,
  required HomeState state,
  required BuildContext context,
}) {
  if (skillNode != null) {
    // Check if the current node has children
    final hasChildren = state.trainingPath?.skillNodes
            .any((element) => element?.parentId == skillNode.id) ??
        false;
    // Check if the current node is a child
    final isChild = skillNode.parentId != null;
    final isSplitScreen = MediaQuery.of(context).size.width > 800;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // If it is a child node, show a divider on top
        // if (isChild) const Divider(color: Colors.black, thickness: 2),

        InkWell(
          onTap: () {
            homeCubit.skillSelected(
              isFromTrainingPath: true,
              isSplitScreen: isSplitScreen,
              skill: state.allSkills?.firstWhere(
                (element) => element?.skillName == skillNode.name,
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(skillNode.name),
            ),
          ),
        ),

        // If it has children, show a vertical divider below
        if (hasChildren)
          Container(
            height: 10,
            width: 2,
            color:
                HorseAndRidersTheme().getTheme().brightness == Brightness.light
                    ? Colors.black
                    : Colors.white,
          ),

        Wrap(
          children:
              homeCubit.childrenNodes(skillNode: skillNode).asMap().entries.map(
            (entry) {
              final index = entry.key;
              final e = entry.value;
              final totalChildren =
                  homeCubit.childrenNodes(skillNode: skillNode).length;

              return Column(
                children: [
                  _buildHorizontalDividerLine(index, totalChildren),
                  // Row(
                  //   mainAxisSize: MainAxisSize.min,
                  //   children: [
                  //     Container(
                  //       height: 2,
                  //       width: 99,
                  //       color: e.position == 0
                  //           ? Colors.transparent
                  //           : HorseAndRidersTheme().getTheme().brightness ==
                  //                   Brightness.light
                  //               ? Colors.black
                  //               : Colors.white,
                  //     ),
                  //     Container(
                  //       height: 2,
                  //       width: 2,
                  //       color: HorseAndRidersTheme().getTheme().brightness ==
                  //               Brightness.light
                  //           ? Colors.black
                  //           : Colors.white,
                  //     ),
                  //     Container(
                  //       width: 99,
                  //       height: 2,
                  //       color: e.position ==
                  //               homeCubit
                  //                       .childrenNodes(
                  //                         skillNode: skillNode,
                  //                       )
                  //                       .length -
                  //                   1
                  //           ? Colors.transparent
                  //           : HorseAndRidersTheme().getTheme().brightness ==
                  //                   Brightness.light
                  //               ? Colors.black
                  //               : Colors.white,
                  //     ),
                  //   ],
                  // ),
                  Container(
                    height: 10,
                    color: HorseAndRidersTheme().getTheme().brightness ==
                            Brightness.light
                        ? Colors.black
                        : Colors.white,
                    width: 2,
                  ),
                  _skillNodeCard(
                    context: context,
                    state: state,
                    homeCubit: homeCubit,
                    skillNode: e,
                  ),
                ],
              );
            },
          ).toList(),
        ),
      ],
    );
  } else {
    return const Text('No Skill Found');
  }
}

Widget _buildHorizontalDividerLine(int index, int totalChildren) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Expanded(
        flex: index == 0 ? 0 : 1,
        child: const Divider(
          color: Colors.black,
          thickness: 2,
        ),
      ),
      Container(
        height: 10,
        width: 2,
        color: Colors.black,
      ),
      Expanded(
        flex: index == totalChildren - 1 ? 0 : 1,
        child: const Divider(
          color: Colors.black,
          thickness: 2,
        ),
      ),
    ],
  );
}
