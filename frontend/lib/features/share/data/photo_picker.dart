import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'photo_picker.g.dart';

/// Lets the user choose a photo from their gallery for a verse background.
class PhotoPicker {
  final _picker = ImagePicker();

  /// Returns the chosen photo's file path, or null if the user cancelled.
  Future<String?> pickFromGallery() async {
    // Large enough for a sharp 1080x1920 export without loading huge originals.
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2160,
      maxHeight: 3840,
      imageQuality: 92,
    );
    return file?.path;
  }
}

@riverpod
PhotoPicker photoPicker(Ref ref) => PhotoPicker();
