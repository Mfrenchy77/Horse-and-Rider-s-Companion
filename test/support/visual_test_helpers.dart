import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

bool _portableFontsLoaded = false;

String? _resolveFlutterSdkRoot() {
  final fromEnv = Platform.environment['FLUTTER_ROOT']?.trim();
  if (fromEnv != null &&
      fromEnv.isNotEmpty &&
      Directory(fromEnv).existsSync()) {
    return fromEnv;
  }
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final materialFonts = Directory(
      '${dir.path}/bin/cache/artifacts/material_fonts',
    );
    if (materialFonts.existsSync()) {
      return dir.path;
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  return null;
}

/// Registers Flutter SDK bundled Roboto + MaterialIcons and project custom
/// icon fonts so tests never depend on Rocky-only `/usr/share/fonts/...` or a
/// pre-built `build/web` directory on Linux/macOS/CI runners.
Future<void> loadPortableTestFonts({bool force = false}) async {
  if (_portableFontsLoaded && !force) return;

  Future<bool> register(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var loadedAny = false;
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = await file.readAsBytes();
        loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
        loadedAny = true;
      }
    }
    if (loadedAny) {
      await loader.load();
    }
    return loadedAny;
  }

  final sdkRoot = _resolveFlutterSdkRoot();
  final sdkFonts = sdkRoot == null
      ? null
      : '$sdkRoot/bin/cache/artifacts/material_fonts';

  final robotoLoaded = await register('Roboto', [
    if (sdkFonts != null) ...[
      '$sdkFonts/Roboto-Regular.ttf',
      '$sdkFonts/Roboto-Medium.ttf',
      '$sdkFonts/Roboto-Bold.ttf',
      '$sdkFonts/Roboto-Light.ttf',
      '$sdkFonts/Roboto-Italic.ttf',
    ],
    '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans.ttf',
    '/usr/share/fonts/dejavu-sans-fonts/DejaVuSans-Bold.ttf',
  ]);
  if (!robotoLoaded) {
    await register('Roboto', const [
      '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
      '/usr/share/fonts/liberation-sans/LiberationSans-Regular.ttf',
    ]);
  }

  final georgiaLoaded = await register('Georgia', const [
    '/usr/share/fonts/truetype/liberation/LiberationSerif-Regular.ttf',
    '/usr/share/fonts/truetype/liberation/LiberationSerif-Bold.ttf',
    '/usr/share/fonts/liberation-serif/LiberationSerif-Regular.ttf',
    '/usr/share/fonts/liberation-serif/LiberationSerif-Bold.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSerif.ttf',
    '/usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf',
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif.ttf',
    '/usr/share/fonts/dejavu-serif-fonts/DejaVuSerif-Bold.ttf',
  ]);
  if (!georgiaLoaded && sdkFonts != null) {
    await register('Georgia', [
      '$sdkFonts/Roboto-Regular.ttf',
      '$sdkFonts/Roboto-Bold.ttf',
    ]);
  }

  await register('MaterialIcons', [
    if (sdkFonts != null) '$sdkFonts/MaterialIcons-Regular.otf',
    'build/web/assets/fonts/MaterialIcons-Regular.otf',
  ]);
  await register('HorseAndRiderIcons', const ['fonts/HorseAndRiderIcons.ttf']);

  _portableFontsLoaded = true;
}

/// Optional directory for visual test PNG artifacts.
///
/// Always prefers `VISUAL_TEST_OUTPUT_DIR`; otherwise returns `null` unless
/// [fallbackToTempDir] is true (using `Directory.systemTemp` so tests never
/// write to developer home paths or fail on CI permissions).
String? resolveVisualTestOutputDir({bool fallbackToTempDir = false}) {
  final configured = Platform.environment['VISUAL_TEST_OUTPUT_DIR']?.trim();
  if (configured != null && configured.isNotEmpty) {
    return configured;
  }
  if (fallbackToTempDir) {
    return '${Directory.systemTemp.path}/hrc_visual_test_artifacts';
  }
  return null;
}

/// Renders and verifies PNG encoding of [boundaryFinder] in memory, and writes
/// the file only when `VISUAL_TEST_OUTPUT_DIR` is configured (or when
/// [fallbackToTempDir] is true).
Future<void> captureBoundaryArtifact(
  WidgetTester tester,
  Finder boundaryFinder,
  String filename, {
  double pixelRatio = 1.0,
  bool fallbackToTempDir = false,
}) async {
  await tester.runAsync(() async {
    if (boundaryFinder.evaluate().isEmpty) return;
    final boundary =
        tester.renderObject(boundaryFinder) as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    expect(byteData, isNotNull);
    expect(byteData!.lengthInBytes, greaterThan(0));

    final outDir = resolveVisualTestOutputDir(
      fallbackToTempDir: fallbackToTempDir,
    );
    if (outDir == null) return;
    final dir = Directory(outDir);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    await File('$outDir/$filename').writeAsBytes(byteData.buffer.asUint8List());
  });
}
