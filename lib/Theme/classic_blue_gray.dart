import 'package:flutter/material.dart';

abstract final class ClassicBlueGray {
  static const chromeStart = Color(0xFF5B7684);
  static const chromeEnd = Color(0xFF405B69);
  static const canvas = Color(0xFFD5E4EC);
  static const surface = Color(0xFFE2EDF3);
  static const surfaceLow = Color(0xFFE3EDF2);
  static const surfaceHigh = Color(0xFFD6E3EA);
  static const surfaceHighest = Color(0xFFC3D6E1);
  static const ink = Color(0xFF203B42);
  static const muted = Color(0xFF486368);
  static const outline = Color(0xFFB5C6CD);
  static const coral = Color(0xFFA64636);
  static const selected = Color(0xFFF4D9D2);
  static const selectedInk = Color(0xFF7A3025);
  static const gold = Color(0xFFEAD3A1);
  static const goldInk = Color(0xFF624813);

  static const appBar = LinearGradient(colors: [chromeStart, chromeEnd]);
  static const rail = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [chromeStart, chromeEnd],
  );
  static const background = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [canvas, Color(0xFFC2D6E2), Color(0xFFB5CBD9)],
    stops: [0, .56, 1],
  );
  static const card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceHigh, surfaceHighest],
    stops: [0, .48, 1],
  );
}
