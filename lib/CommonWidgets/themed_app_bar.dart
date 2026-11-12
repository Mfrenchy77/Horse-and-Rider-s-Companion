import 'package:flutter/material.dart';
import 'package:horseandriderscompanion/Theme/surface_gradients.dart';

class ThemedAppBar extends AppBar {
  ThemedAppBar({
    super.key,
    super.leading,
    super.title,
    super.actions,
    super.bottom,
    super.centerTitle,
    super.automaticallyImplyLeading,
  }) : super(flexibleSpace: const _AppBarGradient());
}

class _AppBarGradient extends StatelessWidget {
  const _AppBarGradient();

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<SurfaceGradients>()?.chrome;
    if (gradient == null) return const SizedBox.shrink();
    return SizedBox.expand(
      child: DecoratedBox(decoration: BoxDecoration(gradient: gradient)),
    );
  }
}
