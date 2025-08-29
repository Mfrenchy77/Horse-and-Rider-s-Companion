import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';
import 'package:horseandriderscompanion/CommonWidgets/max_width_box.dart';
import 'package:horseandriderscompanion/MainPages/SkillTree/Dialogs/CreateTrainingPathDialog/Cubit/create_training_path_cubit.dart';
import 'package:horseandriderscompanion/Theme/theme.dart';
import 'package:horseandriderscompanion/Utilities/Constants/string_constants.dart';
import 'package:horseandriderscompanion/Utilities/navigation_utils.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class CreateTrainingPathDialog extends StatelessWidget {
  const CreateTrainingPathDialog({
    super.key,
    required this.isEdit,
    required this.allSkills,
    required this.isForRider,
    required this.usersProfile,
    required this.trainingPath,
  });

  final bool isEdit;
  final bool isForRider;
  final List<Skill> allSkills;
  final RiderProfile usersProfile;
  final TrainingPath? trainingPath;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CreateTrainingPathCubit(
        trainingPathRepository: context.read<SkillTreeRepository>(),
        allSkills: allSkills,
        editing: trainingPath,
        isForRider: isForRider,
        user: usersProfile,
      ),
      child: BlocListener<CreateTrainingPathCubit, CreateTrainingPathState>(
        listener: (context, state) {
          final cubit = context.read<CreateTrainingPathCubit>();
          if (state.status == FormStatus.success) {
            safePop(context);
          }
          if (state.status == FormStatus.failure) {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${state.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.red,
                  ),
                ).closed.then((_) => cubit.resetError());
            });
          }
        },
        child: BlocBuilder<CreateTrainingPathCubit, CreateTrainingPathState>(
          builder: (context, state) {
            final cubit = context.read<CreateTrainingPathCubit>();

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Scaffold(
                appBar: AppBar(
                  actions: [
                    if (state.isSearch) _buildSearch(context),
                    if (!state.isSearch)
                      IconButton(
                        onPressed: cubit.isSearch,
                        icon: const Icon(Icons.search),
                      ),
                  ],
                  leading: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  title: Text(
                    isEdit
                        ? 'Edit ${state.trainingPath?.name}'
                        : 'Create New Training Path for '
                            '${state.isForRider ? 'Rider' : 'Horse'}',
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
                              // ───────── Name / Description / Type ─────────
                              MaxWidthBox(
                                maxWidth: 900,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      textCapitalization:
                                          TextCapitalization.words,
                                      initialValue: isEdit
                                          ? state.trainingPath?.name
                                          : '',
                                      decoration: const InputDecoration(
                                        labelText: 'Name',
                                        border: UnderlineInputBorder(),
                                      ),
                                      onChanged: (v) => cubit
                                          .trainingPathNameChanged(name: v),
                                    ),
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
                                      onChanged: (v) =>
                                          cubit.trainingPathDescriptionChanged(
                                        description: v,
                                      ),
                                    ),
                                    gap(),
                                    SegmentedButton<bool>(
                                      segments: const [
                                        ButtonSegment(
                                          value: false,
                                          icon: Icon(
                                            HorseAndRiderIcons.horseIcon,
                                          ),
                                          label: Text('Horse'),
                                          tooltip:
                                              'Training Path is for a Horse',
                                        ),
                                        ButtonSegment(
                                          value: true,
                                          icon: Icon(Icons.person),
                                          label: Text('Rider'),
                                          tooltip:
                                              'Training Path is for a Rider',
                                        ),
                                      ],
                                      selected: <bool>{state.isForRider},
                                      onSelectionChanged: (_) =>
                                          cubit.isForHorse(),
                                    ),
                                  ],
                                ),
                              ),

                              gap(),
                              const Divider(),
                              gap(),

                              // ───────── Pool of Available Skills ─────────
                              Text(
                                state.availableSkills.isEmpty
                                    ? 'All skills added to your path'
                                    : 'Drag & Drop a skill'
                                        ' into the path below:',
                              ),
                              gap(),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: state.availableSkills.map((skill) {
                                  return Draggable<Skill>(
                                    data: skill,
                                    feedback: Material(
                                      child: Chip(label: Text(skill.skillName)),
                                    ),
                                    childWhenDragging: Opacity(
                                      opacity: 0.5,
                                      child: Chip(label: Text(skill.skillName)),
                                    ),
                                    child: Chip(label: Text(skill.skillName)),
                                  );
                                }).toList(),
                              ),

                              gap(),

                              // ───────── Training Path Hierarchy ─────────
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Drop skills to organize your path:',
                                  ),
                                  gap(),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        // root nodes
                                        Wrap(
                                          spacing: 8,
                                          children: state.rootNodes
                                              .map(
                                                (node) => _skillNodeCard(
                                                  node,
                                                  cubit,
                                                  state,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                        gap(),
                                        // drop-to-root target
                                        if (state.availableSkills.isNotEmpty)
                                          DragTarget<Skill>(
                                            onWillAcceptWithDetails: (_) =>
                                                true,
                                            onAcceptWithDetails: (skill) =>
                                                cubit.skillNodeSelected(
                                              skillName: skill.data.skillName,
                                            ),
                                            builder: (ctx, __, ___) => Card(
                                              color: Colors.grey.shade200,
                                              child: const Padding(
                                                padding: EdgeInsets.all(8),
                                                child: Text(
                                                  'Drop Here to Add Root Skill',
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              gap(),

                              // ───────── Buttons ─────────
                              MaxWidthBox(
                                maxWidth: 900,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (state.trainingPath?.createdBy ==
                                        usersProfile.name)
                                      IconButton(
                                        onPressed: () {
                                          cubit.deleteTrainingPath();
                                          safePop(context);
                                        },
                                        icon: const Icon(Icons.delete),
                                      ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    gap(),
                                    FilledButton(
                                      onPressed: state.rootNodes.isEmpty
                                          ? null
                                          : cubit.createOrEditTrainingPath,
                                      child: state.status ==
                                              FormStatus.submitting
                                          ? const CircularProgressIndicator()
                                          : Text(isEdit ? 'Edit' : 'Submit'),
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
      ),
    );
  }

  /// Search box in the AppBar actions
  ///  (replaces SearchField with built-in Autocomplete)
  Widget _buildSearch(BuildContext context) {
    final cubit = context.read<CreateTrainingPathCubit>();
    final theme = HorseAndRidersTheme().getTheme();

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Autocomplete<String>(
          // Provide suggestions; when query is empty,
          // show a short list (like Suggestion.expand)
          optionsBuilder: (TextEditingValue text) {
            final q = text.text.trim().toLowerCase();
            final skills = context
                .read<CreateTrainingPathCubit>()
                .state
                .availableSkills
                .map((s) => s.skillName);

            if (q.isEmpty) {
              return skills.take(30);
            }
            return skills.where((name) => name.toLowerCase().contains(q));
          },

          displayStringForOption: (s) => s,

          onSelected: (selected) {
            FocusScope.of(context).unfocus();
            cubit.skillNodeSelected(skillName: selected);
          },

          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            // keep the Cubit search state in sync as the user types
            controller.addListener(() {
              cubit.searchQueryChanged(query: controller.text);
            });

            return TextField(
              controller: controller,
              focusNode: focusNode,
              autofocus: true,
              textInputAction: TextInputAction.search,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                filled: true,
                iconColor: theme.iconTheme.color,
                fillColor: theme.scaffoldBackgroundColor,
                hintText: 'Type to filter available skills',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                suffixIcon: IconButton(
                  onPressed: cubit.isSearch, // closes search mode (toggle)
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear',
                ),
              ),
              onSubmitted: (_) => onFieldSubmitted(),
            );
          },

          // Popup list styling
          optionsViewBuilder: (context, onSelected, options) {
            final textStyle = Theme.of(context).textTheme.bodyMedium;
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: 420, maxHeight: 320),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final opt = options.elementAt(i);
                      return InkWell(
                        onTap: () => onSelected(opt),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Text(opt, style: textStyle),
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Renders a SkillNode chip (root or child), with nesting
  Widget _skillNodeCard(
    SkillNode node,
    CreateTrainingPathCubit cubit,
    CreateTrainingPathState state,
  ) {
    final children = state.childNodes[node.id] ?? [];
    final hasChildren = children.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DragTarget<Skill>(
          onWillAcceptWithDetails: (_) => true,
          onAcceptWithDetails: (skill) => cubit.createOrDeleteChildSkillNode(
            parentNode: node,
            skillName: skill.data.skillName,
          ),
          builder: (ctx, __, ___) => Chip(
            label: Text(node.name),
            onDeleted: () => cubit.removeNode(node),
          ),
        ),
        if (hasChildren)
          Container(
            height: 10,
            width: 2,
            color: HorseAndRidersTheme()
                .getTheme()
                .dividerColor
                .withValues(alpha: 0.5),
          ),
        if (hasChildren)
          ...children.map((child) => _skillNodeCard(child, cubit, state)),
      ],
    );
  }
}
