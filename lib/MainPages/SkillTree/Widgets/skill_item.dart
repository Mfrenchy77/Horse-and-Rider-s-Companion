import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';
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
    return InkWell(
      onTap: widget.onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
            ),
          ],
          borderRadius: BorderRadius.circular(20),
          gradient: widget.levelState == LevelState.LEARNING
              ? LinearGradient(
                  stops: const [0.5, 0.5],
                  colors: [
                    if (widget.verified ?? false)
                      Colors.yellow
                    else
                      Colors.blue,
                    Colors.transparent,
                  ],
                )
              : null,
          color: widget.levelState == LevelState.PROFICIENT
              ? (widget.verified ?? false ? Colors.yellow : Colors.blue)
              : (widget.levelState == LevelState.LEARNING
                  ? Colors.transparent
                  : Colors.transparent),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child:
                      _icon(widget.skill!.category, widget.skill!.difficulty),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                      top: 8,
                      left: 16,
                      right: 16,
                    ),
                    child: Text(
                      widget.name ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  ),
                ),
                Visibility(
                  visible: widget.isEditState && !widget.isGuest,
                  child: PopupMenuButton<String>(
                    iconSize: 18,
                    itemBuilder: (context) {
                      return [
                        PopupMenuItem(
                          onTap: widget.onEdit,
                          child: const Text('Edit'),
                        ),
                      ];
                    },
                  ),
                ),
              ],
            ),
            Visibility(
              visible: _isExpanded,
              child: Text(
                widget.skill?.rider ?? false ? 'Rider' : 'Horse',
              ),
            ),
            Visibility(
              visible: _isExpanded,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text('${widget.skill?.category.name} -'
                    ' ${widget.skill?.difficulty.name}'),
              ),
            ),
          ],
        ),
      ),
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
            color: Colors.black.withOpacity(0.5),
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
            color: Colors.black.withOpacity(0.5),
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
            color: Colors.black.withOpacity(0.5),
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
