import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  User? get currentUser => _auth.currentUser;

  Future<String> uploadImage(File imageFile, {Function(double)? onProgress}) async {
    if (currentUser == null) {
      throw Exception('ユーザー認証が必要です。アプリを再起動してください。');
    }

    final userId = currentUser!.uid;
    print('Using UID: $userId');

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'image_$timestamp.jpg';
    final path = 'uploads/$userId/$fileName';
    print('Uploading to path: $path');

    final ref = _storage.ref(path);

    final uploadTask = ref.putFile(imageFile);

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress(progress);
      });
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();
    print('Upload successful. URL: $downloadUrl');

    return downloadUrl;
  }

  Future<String> recognizeText(String imageUrl) async {
    // Check if user is authenticated
    if (currentUser == null) {
      throw Exception('ユーザー認証が必要です。再度お試しください。');
    }

    try {
      print('Calling recognizeText function with URL: $imageUrl');
      final callable = _functions.httpsCallable('generateOcm');
      final result = await callable.call({'imageUrl': imageUrl});

      print('Recognition result: ${result.data}');

      return result.data['text'] as String;
    } catch (e) {
      print('Error in recognizeText: $e');

      if (e is FirebaseFunctionsException) {
        print('Functions error code: ${e.code}');
        print('Functions error details: ${e.details}');

        throw Exception('OCR処理に失敗しました: ${e.message}');
      }

      throw Exception('サーバーエラーが発生しました: $e');
    }
  }
}
