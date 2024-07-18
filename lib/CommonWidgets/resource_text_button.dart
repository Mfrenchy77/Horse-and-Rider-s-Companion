import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/CommonWidgets/gap.dart';

/// Widget that displays a resource text with category/difficulty icon and type
///  icon(Horse or Rider)
class ResourceTextButton extends StatelessWidget {
  const ResourceTextButton({
    super.key,
    required this.text,
    required this.onClick,
    required this.tooltip,
    required this.leadingIcon,
    required this.trailingIcon,
  });
  final String text;
  final String tooltip;
  final VoidCallback onClick;
  final Widget leadingIcon;
  final Widget trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onClick,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                leadingIcon,
                smallGap(),
                Flexible(
                  child: Text(
                    text,
                  ),
                ),
                smallGap(),
                trailingIcon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
