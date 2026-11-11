import 'package:flutter/material.dart';

class ProfileLayout extends StatelessWidget {
  const ProfileLayout({
    super.key,
    required this.identity,
    required this.skills,
    required this.wideKey,
    required this.compactKey,
  });

  static const double largeBreakpoint = 1024;

  final Widget identity;
  final Widget skills;
  final Key wideKey;
  final Key compactKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: constraints.maxWidth >= largeBreakpoint
              ? Row(
                  key: wideKey,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: identity),
                    const SizedBox(width: 20),
                    Expanded(flex: 6, child: skills),
                  ],
                )
              : Column(
                  key: compactKey,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [identity, const SizedBox(height: 16), skills],
                ),
        ),
      ),
    ),
  );
}
