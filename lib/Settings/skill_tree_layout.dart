import 'package:flutter/widgets.dart';

enum SkillTreeLayout {
  library('Skill library'),
  expandInPlace('Expand in place'),
  progressBoard('Progress board');

  const SkillTreeLayout(this.label);

  final String label;
}

class SkillTreeLayoutScope extends InheritedWidget {
  const SkillTreeLayoutScope({
    super.key,
    required this.layout,
    required super.child,
  });

  final SkillTreeLayout layout;

  static SkillTreeLayout of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<SkillTreeLayoutScope>()
          ?.layout ??
      SkillTreeLayout.library;

  @override
  bool updateShouldNotify(SkillTreeLayoutScope oldWidget) =>
      layout != oldWidget.layout;
}
