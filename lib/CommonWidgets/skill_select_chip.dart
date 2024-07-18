import 'package:database_repository/database_repository.dart';
import 'package:flutter/material.dart';

class SkillSelectChip extends StatefulWidget {
  const SkillSelectChip({
    super.key,
    required this.leadingIcon,
    required this.trailingIcon,
    required this.textLabel,
    required this.onTap,
    required this.skill,
    this.isSelected = false,
    this.padding,
  });
  final Skill? skill;
  final Widget leadingIcon;
  final Widget trailingIcon;
  final String textLabel;
  final void Function(void) onTap;
  final bool isSelected;
  final double? padding;

  @override
  _SkillSelectChipState createState() => _SkillSelectChipState();
}

class _SkillSelectChipState extends State<SkillSelectChip> {
  late bool _isSelected;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.isSelected;
  }

  void _handleTap() {
    setState(() {
      _isSelected = !_isSelected;
    });
    widget.onTap(_isSelected);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skill == null) {
      return const SizedBox();
    } else {
      return InkWell(
        onTap: _handleTap,
        child: Tooltip(
          message: 'Category: ${widget.skill?.category.name}\n'
              'Difficulty: ${widget.skill?.difficulty.name}\n'
              'For a ${widget.skill!.rider ? 'Rider' : 'Horse'}',
          child: Card(
            elevation: _isSelected ? 4 : 0,
            color: _isSelected ? Colors.blue : Colors.transparent,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: widget.leadingIcon,
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: Builder(
                        builder: (context) {
                          return Text(
                            widget.textLabel,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: widget.trailingIcon,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
