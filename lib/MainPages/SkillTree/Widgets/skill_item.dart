import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

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
          color: widget.levelState == LevelState.PROFICIENT
              ? widget.verified ?? false
                  ? Colors.yellow
                  : Colors.blue
              : Colors.transparent,
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 8,
                    top: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Text(
                    widget.name ?? '',
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
