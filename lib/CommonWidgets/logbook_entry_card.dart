import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/card_gradient.dart';

class LogbookEntryCard extends StatelessWidget {
  const LogbookEntryCard({
    required this.title,
    required this.metadata,
    required this.icon,
    required this.onTap,
    this.preview,
    this.trailing,
    super.key,
  });

  final String title;
  final String metadata;
  final IconData icon;
  final VoidCallback onTap;
  final String? preview;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return GradientCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: colors.onSecondaryContainer),
          ),
        ),
        title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(metadata, style: theme.textTheme.bodySmall),
            if (preview != null)
              Text(preview!, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
