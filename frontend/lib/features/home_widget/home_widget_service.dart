import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/widgets/verse_card.dart';
import '../verses/data/models/daily_verse.dart';

part 'home_widget_service.g.dart';

/// A home-screen widget size. [key] must match the image key read by the Android provider.
enum VerseWidgetSize {
  small('verse_image_small', Size(170, 170), 'VerseWidgetSmall'),
  medium('verse_image_medium', Size(340, 170), 'VerseWidgetMedium'),
  large('verse_image_large', Size(340, 340), 'VerseWidgetLarge');

  const VerseWidgetSize(this.key, this.logicalSize, this.androidProvider);

  final String key;
  final Size logicalSize;
  final String androidProvider;
}

class HomeWidgetService {
  HomeWidgetService(this._dio);

  final Dio _dio;
  String? _lastSyncedDate;

  static const _androidPackage = 'com.londonglobaledventures.soulverse.widgets';

  /// Renders today's verse for every widget size and refreshes the widgets.
  /// Failures are logged, never thrown: the widget is a nice-to-have, not app-critical.
  Future<void> sync(DailyVerse daily) async {
    if (!Platform.isAndroid || _lastSyncedDate == daily.date) return;
    try {
      await HomeWidget.saveWidgetData('verse_text', daily.verse.text);
      await HomeWidget.saveWidgetData('verse_reference', daily.verse.reference);

      final background = await _loadImage(daily.template.imageUrl);
      try {
        for (final size in VerseWidgetSize.values) {
          await HomeWidget.renderFlutterWidget(
            SizedBox.fromSize(
              size: size.logicalSize,
              child: VerseCard(
                verse: daily.verse,
                template: daily.template,
                borderRadius: BorderRadius.circular(20),
                background: RawImage(image: background, fit: BoxFit.cover),
              ),
            ),
            key: size.key,
            logicalSize: size.logicalSize,
            pixelRatio: 2.5,
          );
        }
      } finally {
        background.dispose();
      }

      for (final size in VerseWidgetSize.values) {
        await HomeWidget.updateWidget(
          qualifiedAndroidName: '$_androidPackage.${size.androidProvider}',
        );
      }
      _lastSyncedDate = daily.date;
    } catch (e, stack) {
      debugPrint('Home widget sync failed: $e\n$stack');
    }
  }

  // Offscreen rendering paints a single frame, so the image must be decoded up front.
  Future<ui.Image> _loadImage(String url) async {
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final codec = await ui.instantiateImageCodec(
      Uint8List.fromList(response.data!),
      targetWidth: 1024,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();
    return frame.image;
  }
}

// Plain Dio: the API client's logger would print the image bytes.
@Riverpod(keepAlive: true)
HomeWidgetService homeWidgetService(Ref ref) => HomeWidgetService(Dio());
