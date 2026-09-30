import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';

part 'share_service.g.dart';

enum ShareTarget {
  whatsapp('com.whatsapp', 'WhatsApp'),
  instagram('com.instagram.android', 'Instagram');

  const ShareTarget(this.androidPackage, this.label);

  final String androidPackage;
  final String label;
}

enum SaveResult { saved, permissionDenied, failed }

class ShareService {
  static const _channel = MethodChannel('soulverse/share');

  Future<SaveResult> saveToGallery(Uint8List png) async {
    try {
      if (!await Gal.hasAccess() && !await Gal.requestAccess()) {
        return SaveResult.permissionDenied;
      }
      await Gal.putImageBytes(png, name: _fileName());
      return SaveResult.saved;
    } on GalException catch (e) {
      return e.type == GalExceptionType.accessDenied
          ? SaveResult.permissionDenied
          : SaveResult.failed;
    }
  }

  /// Opens [target] directly on Android. Returns false when it isn't installed or on iOS,
  /// where apps can't be targeted directly — the caller then falls back to [shareToSystem].
  Future<bool> shareToApp(
    ShareTarget target,
    Uint8List png, {
    String? text,
  }) async {
    if (!Platform.isAndroid) return false;
    final file = await _writeTemp(png);
    final opened = await _channel.invokeMethod<bool>('shareImageToApp', {
      'package': target.androidPackage,
      'path': file.path,
      'text': text,
    });
    return opened ?? false;
  }

  Future<void> shareToSystem(Uint8List png, {String? text}) async {
    final file = await _writeTemp(png);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: text,
      ),
    );
  }

  // Must match the cache-path in android/app/src/main/res/xml/verse_share_paths.xml.
  Future<File> _writeTemp(Uint8List png) async {
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/verse_share',
    );
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    return File('${dir.path}/${_fileName()}.png').writeAsBytes(png);
  }

  String _fileName() => 'soulverse_${DateTime.now().millisecondsSinceEpoch}';
}

@riverpod
ShareService shareService(Ref ref) => ShareService();
