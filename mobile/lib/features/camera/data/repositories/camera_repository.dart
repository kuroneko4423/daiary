import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CameraRepository {
  final ImagePicker _imagePicker;

  CameraRepository() : _imagePicker = ImagePicker();

  Future<String?> importFromGallery() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 4096,
      maxHeight: 4096,
      imageQuality: 95,
    );
    return pickedFile?.path;
  }

  Future<String> savePhoto(String sourcePath) async {
    final directory = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${directory.path}/photos');
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }

    final extension = sourcePath.contains('.')
        ? sourcePath.substring(sourcePath.lastIndexOf('.'))
        : '.jpg';
    final fileName =
        'photo_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destPath = '${photosDir.path}/$fileName';

    await File(sourcePath).copy(destPath);
    return destPath;
  }
}
