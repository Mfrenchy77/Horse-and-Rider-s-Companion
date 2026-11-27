import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:horseandriderscompanion/MainPages/SkillTreeV2/skill_tree_v2_view.dart';

class SkillTreePage extends StatelessWidget {
  const SkillTreePage({
    super.key,
    this.initialSkillId,
    this.initialLevel,
  });

  final String? initialSkillId;
  final DifficultyState? initialLevel;

  static const path = '/SkillTree';
  static const name = 'SkillTree';
  static const skillPathParam = 'skillId';
  static const legacySkillsListPath = 'Skills';
  static const legacySkillLevelPath = 'Skill::$skillPathParam';

  /// Opens a canonical Skill Tree skill (resolving legacy skill IDs) via
  /// [GoRouter] at `/SkillTree?skillId=<id>`.
  static void openSkill(
    GoRouter router,
    String id, {
    DifficultyState? level,
  }) {
    router.goNamed(
      name,
      queryParameters: {
        skillPathParam: id,
        if (level != null && level != DifficultyState.All) 'level': level.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SkillTreeV2Repository? repository;
    try {
      repository = context.read<SkillTreeV2Repository?>();
    } on ProviderNotFoundException {
      repository = null;
    }
    return SkillTreeV2View(
      key: const Key('skillTreeV2PageView'),
      repository: repository,
      initialSkillId: initialSkillId,
      initialLevel: initialLevel,
    );
  }
}
