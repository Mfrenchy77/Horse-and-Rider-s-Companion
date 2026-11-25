import 'package:flutter/material.dart';

class AdaptiveAppBarAction {
  const AdaptiveAppBarAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.priority = 0,
    this.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final int priority;
  final Key? key;
}

/// Higher priorities stay visible first. Callers filter unauthorized actions.
class AdaptiveAppBarActions extends StatelessWidget {
  const AdaptiveAppBarActions({super.key, required this.actions});

  final List<AdaptiveAppBarAction> actions;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.38).clamp(48.0, 240.0);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: width),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final sorted = [...actions]
            ..sort((a, b) => b.priority.compareTo(a.priority));
          final slots = (constraints.maxWidth / 48).floor();
          final visibleCount = sorted.length <= slots
              ? sorted.length
              : (slots - 1).clamp(0, sorted.length);
          final visible = sorted.take(visibleCount);
          final overflow = sorted.skip(visibleCount).toList();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final action in visible)
                IconButton(
                  key: action.key,
                  tooltip: action.label,
                  onPressed: action.onPressed,
                  icon: Icon(action.icon),
                ),
              if (overflow.isNotEmpty)
                PopupMenuButton<int>(
                  tooltip: 'More actions',
                  onSelected: (index) => overflow[index].onPressed?.call(),
                  itemBuilder: (_) => [
                    for (var i = 0; i < overflow.length; i++)
                      PopupMenuItem(
                        value: i,
                        enabled: overflow[i].onPressed != null,
                        child: ListTile(
                          leading: Icon(overflow[i].icon),
                          title: Text(overflow[i].label),
                        ),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}
