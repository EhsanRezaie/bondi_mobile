// One-off generator for the app icon source image.
//
// Renders just the splash's rounded square (primary-gradient fill) with the
// white Icons.favorite heart — no background behind it — at 1024x1024.
// Run with: flutter test tool/render_app_icon_test.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dating_app/config/app_theme.dart';

const double _canvas = 1024;

Future<void> _loadIconFont() async {
  final root = Platform.environment['FLUTTER_ROOT'] ?? '/home/ehsan/flutter';
  final file = File(
    '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  final bytes = file.readAsBytesSync();
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.view(bytes.buffer)));
  await loader.load();
}

void main() {
  testWidgets('app_icon', (t) async {
    await _loadIconFont();
    await _render(t, 'app_icon.png', roundedSquare: true);
  });

  testWidgets('app_icon_ios', (t) async {
    await _loadIconFont();
    // iOS masks the icon to a rounded square and forbids alpha, so this one is
    // full-bleed gradient + heart (no transparency).
    await _render(t, 'app_icon_ios.png', roundedSquare: false);
  });
}

Future<void> _render(
  WidgetTester tester,
  String name, {
  required bool roundedSquare,
}) async {
  tester.view.physicalSize = const Size(_canvas, _canvas);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final key = GlobalKey();
  final square = _canvas * 0.82;
  final radius = square * 0.28;

  await tester.pumpWidget(
    MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: key,
          child: SizedBox(
            width: _canvas,
            height: _canvas,
            child: Center(
              child: Container(
                width: roundedSquare ? square : _canvas,
                height: roundedSquare ? square : _canvas,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient(),
                  borderRadius:
                      roundedSquare ? BorderRadius.circular(radius) : null,
                ),
                child: Center(
                  child: Icon(
                    Icons.favorite,
                    size: (roundedSquare ? square : _canvas) * 0.48,
                    color: AppTheme.textOnPhoto,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 50));

  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData!.buffer.asUint8List();
  });
  if (bytes == null) return;

  Directory('assets/icon').createSync(recursive: true);
  File('assets/icon/$name').writeAsBytesSync(bytes);
  // ignore: avoid_print
  print('wrote assets/icon/$name (${bytes.length} bytes)');
}
