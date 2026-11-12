import 'package:flutter/material.dart';

@immutable
class SurfaceGradients extends ThemeExtension<SurfaceGradients> {
  const SurfaceGradients({
    required this.background,
    required this.rail,
    required this.surface,
    this.chrome,
  });

  final LinearGradient background;
  final LinearGradient rail;
  final LinearGradient surface;
  final LinearGradient? chrome;

  @override
  SurfaceGradients copyWith({
    LinearGradient? background,
    LinearGradient? rail,
    LinearGradient? surface,
    LinearGradient? chrome,
  }) => SurfaceGradients(
    background: background ?? this.background,
    rail: rail ?? this.rail,
    surface: surface ?? this.surface,
    chrome: chrome ?? this.chrome,
  );

  @override
  SurfaceGradients lerp(SurfaceGradients? other, double t) {
    if (other == null) return this;
    return SurfaceGradients(
      background: LinearGradient.lerp(background, other.background, t)!,
      rail: LinearGradient.lerp(rail, other.rail, t)!,
      surface: LinearGradient.lerp(surface, other.surface, t)!,
      chrome: LinearGradient.lerp(chrome, other.chrome, t),
    );
  }
}
