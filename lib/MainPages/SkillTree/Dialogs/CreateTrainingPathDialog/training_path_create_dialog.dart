import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/Cubit/create_training_path_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';
import 'package:searchfield/searchfield.dart';

///   This is the Dialog that is used to create a new TriainingPath
/// or edit an existing TrainingPath
class CreateTrainingPathDialog extends StatelessWidget {
  const CreateTrainingPathDialog({
    super.key,
    required this.usersProfile,
    required this.trainingPath,
    required this.isEdit,
    required this.allSkills,
    required this.isForRider,
  });

  final TrainingPath? trainingPath;
  final bool isEdit;
  final List<Skill?> allSkills;
  final bool isForRider;
  final RiderProfile usersProfile;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CreateTrainingPathCubit(
        allSkills: allSkills,
        isForRider: isForRider,
        trainingPath: trainingPath,
        usersProfile: usersProfile,
        trainingPathRepository: context.read<SkillTreeRepository>(),
      ),
      child: BlocBuilder<CreateTrainingPathCubit, CreateTrainingPathState>(
        builder: (context, state) {
          final trainingPathcubit = context.read<CreateTrainingPathCubit>();
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Scaffold(
              appBar: AppBar(
                actions: [
                  _search(),
                  Visibility(
                    visible: !state.isSearch,
                    child: IconButton(
                      onPressed: trainingPathcubit.isSearch,
                      icon: const Icon(Icons.search),
                    ),
                  ),
                ],
                leading: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                title: Text(
                  isEdit
                      ? 'Edit ${state.trainingPath?.name} '
                      : 'Create New Training Path '
                          'for ${state.isForRider ? 'Horse' : 'Rider'}',
                ),
              ),
              body: Padding(
                padding: const EdgeInsets.all(8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Form(
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            MaxWidthBox(
                              maxWidth: 900,
                              child: Column(
                                children: [
                                  ///   Name
                                  TextFormField(
                                    textCapitalization:
                                        TextCapitalization.words,
                                    initialValue:
                                        isEdit ? state.trainingPath?.name : '',
                                    decoration: const InputDecoration(
                                      labelText: 'Name',
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (value) => trainingPathcubit
                                        .trainingPathNameChanged(name: value),
                                  ),

                                  ///   Description
                                  gap(),
                                  TextFormField(
                                    minLines: 1,
                                    maxLines: 10,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    initialValue: isEdit
                                        ? state.trainingPath?.description
                                        : '',
                                    decoration: const InputDecoration(
                                      labelText: 'Description',
                                      border: UnderlineInputBorder(),
                                    ),
                                    onChanged: (value) => trainingPathcubit
                                        .trainingPathDescriptionChanged(
                                      description: value,
                                    ),
                                  ),
                                  gap(),
                                  SegmentedButton<bool>(
                                    segments: const [
                                      ButtonSegment(
                                        value: false,
                                        icon:
                                            Icon(HorseAndRiderIcons.horseIcon),
                                        label: Text('Horse'),
                                        tooltip: 'Training Path is for a Horse',
                                      ),
                                      ButtonSegment(
                                        value: true,
                                        icon: Icon(Icons.person),
                                        label: Text('Rider'),
                                        tooltip: 'Training Path is for a Rider',
                                      ),
                                    ],
                                    selected: <bool>{state.isForRider},
                                    onSelectionChanged: (p0) =>
                                        trainingPathcubit.isForHorse(),
                                  ),
                                  //checkbox for isForHorse
                                  // CheckboxListTile(
                                  //   title: Text(
                                  //     state.isForHorse
                                  //         ? 'Remove this check to mak
                                  //e this Training '
                                  //             'Path for a Rider'
                                  //         : 'Check this to make this
                                  // Training Path for '
                                  //             'a Horse',
                                  //   ),
                                  //   value: state.isForHorse,
                                  //   onChanged: (value) =>
                                  //       trainingPathcubit.isForHorse(),
                                  // ),
                                ],
                              ),
                            ),
                            gap(),
                            const Divider(),
                            gap(),
                            Text(
                              state.selectedSkills.isEmpty
                                  ? 'Search and add Skill for '
                                      'your training path'
                                  : 'Drag and Drop Skills to the desired '
                                      'level.\nDrop on top of another skill'
                                      ' to make it a child of that skill.\n'
                                      'Drop on the root to make it a root'
                                      ' skill.',
                            ),
                            gap(),
                            _selectedSkills(),
                            gap(),
                            _trainingPath(),
                            gap(),
                            MaxWidthBox(
                              maxWidth: 900,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  //Delete Button
                                  Visibility(
                                    visible: state.trainingPath?.createdBy ==
                                        usersProfile.name,
                                    child: IconButton(
                                      onPressed: () {
                                        trainingPathcubit.deleteTrainingPath();
                                        Navigator.pop(context);
                                      },
                                      icon: const Icon(Icons.delete),
                                    ),
                                  ),

                                  //Cancel Button
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  gap(),

                                  //Submit Button

                                  FilledButton(
                                    onPressed: state.skillNodes.isEmpty
                                        ? null
                                        : () {
                                            trainingPathcubit
                                                .createOrEditTrainingPath();
                                            Navigator.pop(context);
                                          },
                                    child: state.status == FormStatus.submitting
                                        ? const CircularProgressIndicator()
                                        : Text(
                                            isEdit ? 'Edit' : 'Submit',
                                            textAlign: TextAlign.center,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A Segmented Button that shows if the training path is for a Horse or a Rider
Widget _isForHorseOrRider({
  required CreateTrainingPathState state,
  required CreateTrainingPathCubit trainingPathcubit,
}) {
  return SegmentedButton<bool>(
    segments: [
      ButtonSegment(
        value: true,
        enabled: state.isForRider,
        icon: const Icon(HorseAndRiderIcons.horseIcon),
        label: const Text('Horse'),
        tooltip: 'Training Path is for a Horse',
      ),
      ButtonSegment(
        value: false,
        enabled: !state.isForRider,
        icon: const Icon(Icons.person),
        label: const Text('Rider'),
        tooltip: 'Training Path is for a Rider',
      ),
    ],
    selected: <bool>{state.isForRider},
    onSelectionChanged: (p0) => trainingPathcubit.isForHorse(),
  );
}

Widget _search() {
  return BlocBuilder<CreateTrainingPathCubit, CreateTrainingPathState>(
    builder: (context, state) {
      final trainingPathcubit = context.read<CreateTrainingPathCubit>();
      final focus = FocusNode();
      return Visibility(
        visible: state.isSearch,
        child: Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 2, 10, 2),
            child: SearchField<String>(
              autofocus: true,
              focusNode: focus,
              onSuggestionTap: (value) {
                debugPrint('Value: $value');
                focus.unfocus();
                trainingPathcubit.skillSelected(
                  skillName: value.searchKey,
                );
              },
              searchInputDecoration: InputDecoration(
                filled: true,
                iconColor: HorseAndRidersTheme().getTheme().iconTheme.color,
                fillColor:
                    HorseAndRidersTheme().getTheme().scaffoldBackgroundColor,
                suffixIcon: IconButton(
                  onPressed: trainingPathcubit.isSearch,
                  icon: const Icon(Icons.clear),
                ),
                hintText: 'Add Skills to Training Path',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              suggestionState:
                  state.isSearch ? Suggestion.expand : Suggestion.hidden,
              inputType: TextInputType.text,
              hint: 'Add Skills to Training Path',
              onSearchTextChanged: (query) {
                trainingPathcubit.searchQueryChanged(query: query);
                return state.searchList
                    ?.map(
                      (e) => SearchFieldListItem<String>(
                        e ?? '',
                        child: Text(e ?? ''),
                      ),
                    )
                    .toList();
              },
              suggestions: state.searchList
                      ?.map(
                        (e) => SearchFieldListItem<String>(
                          e!,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Text(e),
                          ),
                        ),
                      )
                      .toList() ??
                  [],
            ),
          ),
        ),
      );
    },
  );
}

///   This is the Widget that displays the selected skills
/// in a Chip format
Widget _selectedSkills() {
  return BlocBuilder<CreateTrainingPathCubit, CreateTrainingPathState>(
    builder: (context, state) {
      final trainingPathcubit = context.read<CreateTrainingPathCubit>();
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        children: state.selectedSkills
            .map(
              (e) => Draggable<Skill>(
                data: e,
                feedback: Material(
                  child: _skillChip(
                    trainingPathcubit: trainingPathcubit,
                    skill: e,
                    isDragging: true,
                  ),
                ),
                childWhenDragging: _skillChip(
                  skill: e,
                  isGhost: true,
                  trainingPathcubit: trainingPathcubit,
                ),
                child: _skillChip(
                  skill: e,
                  trainingPathcubit: trainingPathcubit,
                ),
              ),
            )
            .toList(),
      );
    },
  );
}

Widget _trainingPath() {
  return BlocBuilder<CreateTrainingPathCubit, CreateTrainingPathState>(
    builder: (context, state) {
      return Column(
        children: [
          const Text('Drag Skills to organize the Training Path'),
          _buildSkillHierarchyView(
            state: state,
            nodes: state.skillNodes,
            trainingPathCubit: context.read<CreateTrainingPathCubit>(),
          ),
        ],
      );
    },
  );
}

Widget _buildSkillHierarchyView({
  required List<SkillNode?> nodes,
  required CreateTrainingPathCubit trainingPathCubit,
  required CreateTrainingPathState state,
}) {
  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        Wrap(
          children: nodes
              .where((element) => element!.parentId?.isEmpty ?? false)
              .map(
                (e) => _skillNodeCard(
                  state: state,
                  trainingPathcubit: trainingPathCubit,
                  skillNode: e,
                ),
              )
              .toList(),
        ),
        gap(),
        Visibility(
          visible: state.selectedSkills.isNotEmpty,
          child: DragTarget<Skill>(
            onMove: (details) {
              debugPrint('Move: ${details.data.skillName}');
            },
            onWillAcceptWithDetails: (details) {
              debugPrint('Will Accept: ${details.data.skillName}');
              // change the color or the border of the card
              //and vibrate
              return true;
            },
            builder: (context, candidateData, rejectedData) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Drop Root Skills Here',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
            onAcceptWithDetails: (data) {
              trainingPathCubit.skillNodeSelected(
                skillName: data.data.skillName,
              );
            },
          ),
        ),
      ],
    ),
  );
}

Widget _skillNodeCard({
  required SkillNode? skillNode,
  required CreateTrainingPathCubit trainingPathcubit,
  required CreateTrainingPathState state,
}) {
  // Check if the current node has children
  final hasChildren =
      state.skillNodes.any((element) => element?.parentId == skillNode?.id);
  // Check if the current node is a child
  // final isChild = skillNode?.parentId != null;

  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // If it is a child node, show a divider on top
        // if (isChild) const Divider(color: Colors.black, thickness: 2),

        DragTarget<Skill>(
          onAcceptWithDetails: (data) =>
              trainingPathcubit.createOrDeleteChildSkillNode(
            parentNode: skillNode,
            skillName: data.data.skillName,
          ),
          builder: (context, candidateData, rejectedData) {
            return Chip(
              label: Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
                child: Text(skillNode?.name ?? ''),
              ),
              onDeleted: () => trainingPathcubit.skillNodeSelected(
                skillName: skillNode!.name,
              ),
            );
          },
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
          children: trainingPathcubit
              .childrenOfSkillNode(skillNode: skillNode)
              .map(
                (e) => Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 2,
                          width: 99,
                          color: e?.position == 0
                              ? Colors.transparent
                              : HorseAndRidersTheme().getTheme().brightness ==
                                      Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                        ),
                        Container(
                          height: 2,
                          width: 2,
                          color: HorseAndRidersTheme().getTheme().brightness ==
                                  Brightness.light
                              ? Colors.black
                              : Colors.white,
                        ),
                        Container(
                          width: 99,
                          height: 2,
                          color: e?.position ==
                                  trainingPathcubit
                                          .childrenOfSkillNode(
                                            skillNode: skillNode,
                                          )
                                          .length -
                                      1
                              ? Colors.transparent
                              : HorseAndRidersTheme().getTheme().brightness ==
                                      Brightness.light
                                  ? Colors.black
                                  : Colors.white,
                        ),
                      ],
                    ),
                    Container(
                      height: 10,
                      color: HorseAndRidersTheme().getTheme().brightness ==
                              Brightness.light
                          ? Colors.black
                          : Colors.white,
                      width: 2,
                    ),
                    _skillNodeCard(
                      state: state,
                      trainingPathcubit: trainingPathcubit,
                      skillNode: e,
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ],
    ),
  );
}

Widget _skillChip({
  required Skill? skill,
  bool isDragging = false,
  bool isGhost = false,
  required CreateTrainingPathCubit trainingPathcubit,
}) {
  return Opacity(
    opacity: isGhost ? 0.5 : 1,
    child: Chip(
      avatar: isDragging ? const Icon(Icons.touch_app) : null,
      label: Text(skill?.skillName ?? ''),
      backgroundColor: isDragging ? Colors.blue : Colors.grey[300],
      onDeleted: () {
        trainingPathcubit.skillSelected(skillName: skill!.skillName);
      },
    ),
  );
}
