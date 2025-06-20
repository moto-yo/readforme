import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CameraService {
  final ImagePicker _picker = ImagePicker();

  Future<File?> capturePhoto() async {
    try {
      print('CameraService.capturePhoto called');
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      
      if (photo != null) {
        print('Photo captured successfully: ${photo.path}');
        return File(photo.path);
      }
      print('Photo capture cancelled');
      return null;
    } catch (e) {
      print('Camera error: $e');
      throw Exception('カメラへのアクセスに失敗しました: ${e.toString()}');
    }
  }
}