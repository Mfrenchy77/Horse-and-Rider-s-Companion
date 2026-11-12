import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/app.dart';
import 'package:horseandriderscompanion/MainPages/Resources/Widgets/resource_item.dart';

class SkillResouresList extends StatelessWidget {
  const SkillResouresList({super.key, required this.skillId});

  final String skillId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) =>
          previous.hasResourceCatalogue != current.hasResourceCatalogue ||
          previous.resources != current.resources,
      builder: (context, state) {
        if (state.hasResourceCatalogue) {
          return _resourceItems(
            state.resources.where(
              (resource) => resource.skillTreeIds.contains(skillId),
            ),
          );
        }
        return _SkillResourceQuery(key: ValueKey(skillId), skillId: skillId);
      },
    );
  }
}

class _SkillResourceQuery extends StatefulWidget {
  const _SkillResourceQuery({required super.key, required this.skillId});

  final String skillId;

  @override
  State<_SkillResourceQuery> createState() => _SkillResourceQueryState();
}

class _SkillResourceQueryState extends State<_SkillResourceQuery> {
  late final Stream<List<Resource>> _resources = context
      .read<ResourcesRepository>()
      .getResourcesForSkill(skillId: widget.skillId);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Resource>>(
      stream: _resources,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Unable to load resources');
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  semanticsLabel: 'Loading skill resources',
                ),
              ),
            ),
          );
        }

        return _resourceItems(snapshot.data ?? const <Resource>[]);
      },
    );
  }
}

Widget _resourceItems(Iterable<Resource> resources) {
  if (resources.isEmpty) return const Text('No Resources Found');
  return Wrap(
    alignment: WrapAlignment.center,
    runSpacing: 4,
    children: [
      for (final resource in resources)
        ResourcesItem(
          resource: resource,
          isResourceList: false,
          fromSkillTree: true,
        ),
    ],
  );
}
