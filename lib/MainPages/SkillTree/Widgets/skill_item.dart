import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:horseandriderscompanion/App/Cubit/app_cubit.dart';
import 'package:horseandriderscompanion/horse_and_rider_icons.dart';

class SkillItem extends StatefulWidget {
  const SkillItem({
    super.key,
    required this.name,
    required this.skill,
    required this.onTap,
    required this.onEdit,
    required this.isGuest,
    required this.verified,
    required this.levelState,
    required this.isEditState,
  });

  final bool isGuest;
  final Skill? skill;
  final String? name;
  final bool? verified;
  final bool isEditState;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final LevelState levelState;

  @override
  State<SkillItem> createState() => _SkillItemState();
}

class _SkillItemState extends State<SkillItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppState>(
      buildWhen: (previous, current) => previous.skill != current.skill,
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final isSelected = state.skill?.id == widget.skill?.id;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        final gradient = cubit.levelGradient(skill: widget.skill!);
        final bgColor = cubit.levelColor(
          skill: widget.skill!,
          levelState: LevelState.PROFICIENT,
        );

        // Calculate glow color based on theme brightness
        final glowColor = isSelected
            ? (Theme.of(context).brightness == Brightness.dark
                ? colorScheme.primary.withValues(alpha: 0.5)
                : colorScheme.primary.withValues(alpha: 0.7))
            : Colors.transparent;

        final borderRadius = BorderRadius.circular(35);
        final neutralFillColor = theme.brightness == Brightness.dark
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surface;
        final effectiveFillColor =
            bgColor == Colors.transparent ? neutralFillColor : bgColor;

        return IntrinsicWidth(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: glowColor,
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ]
                  : [],
            ),
            child: Material(
              type: MaterialType.transparency,
              borderRadius: borderRadius,
              child: InkWell(
                borderRadius: borderRadius,
                onTap: widget.onTap,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    color: gradient == null
                        ? effectiveFillColor
                        : neutralFillColor,
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : colorScheme.outlineVariant,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: _buildGradientOverlay(
                    gradient: gradient,
                    borderRadius: borderRadius,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _icon(
                                widget.skill!.category,
                                widget.skill!.difficulty,
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  widget.name ?? '',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    setState(() => _isExpanded = !_isExpanded),
                                icon: Icon(
                                  _isExpanded
                                      ? Icons.arrow_drop_up
                                      : Icons.arrow_drop_down,
                                ),
                              ),
                              if (widget.isEditState && !widget.isGuest)
                                PopupMenuButton<String>(
                                  iconSize: 18,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      onTap: widget.onEdit,
                                      child: const Text('Edit'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          if (_isExpanded) ...[
                            const Divider(),
                            Text(
                              widget.skill?.rider ?? false ? 'Rider' : 'Horse',
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                '${widget.skill?.category.name} '
                                '- ${widget.skill?.difficulty.name}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildGradientOverlay({
    required Gradient? gradient,
    required BorderRadius borderRadius,
    required Widget child,
  }) {
    if (gradient == null) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: gradient,
      ),
      child: child,
    );
  }
}

Widget _icon(SkillCategory category, DifficultyState difficulty) {
  switch (category) {
    case SkillCategory.Mounted:
      return Icon(
        HorseAndRiderIcons.riding,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
          ),
        ],
      );
    case SkillCategory.In_Hand:
      return Icon(
        HorseAndRiderIcons.inhand,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
          ),
        ],
      );
    case SkillCategory.Husbandry:
      return Icon(
        HorseAndRiderIcons.husbandry,
        color: _color(difficulty),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: .5),
            offset: const Offset(1, 1),
          ),
        ],
      );
    case SkillCategory.Other:
      return const Placeholder();
  }
}

Color _color(DifficultyState difficulty) {
  switch (difficulty) {
    case DifficultyState.Introductory:
      return Colors.lightGreen;
    case DifficultyState.Intermediate:
      return Colors.yellow;
    case DifficultyState.Advanced:
      return Colors.red;
    case DifficultyState.All:
      return Colors.transparent;
  }
}
