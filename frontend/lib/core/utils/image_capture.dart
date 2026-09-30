import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Renders the [RepaintBoundary] behind [key] to PNG, scaled so the image is [targetWidth] px wide.
Future<Uint8List> captureBoundaryAsPng(
  GlobalKey key, {
  double targetWidth = 1080,
}) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage(
    pixelRatio: targetWidth / boundary.size.width,
  );
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}
