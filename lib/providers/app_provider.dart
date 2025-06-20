import 'dart:io';
import 'package:flutter/material.dart';
import '../models/app_state.dart';
import '../services/firebase_service.dart';
import '../services/camera_service.dart';
import '../services/audio_service.dart';

class AppProvider extends ChangeNotifier {
  AppState _state = AppState();
  
  final FirebaseService _firebaseService = FirebaseService();
  final CameraService _cameraService = CameraService();
  final AudioService _audioService = AudioService();

  AppState get state => _state;

  Future<void> capturePhoto() async {
    try {
      print('capturePhoto called');
      _updateState(_state.copyWith(status: AppStatus.capturing));
      
      print('Calling camera service...');
      final imageFile = await _cameraService.capturePhoto();
      if (imageFile == null) {
        print('No image captured (user cancelled)');
        _updateState(_state.copyWith(status: AppStatus.ready));
        return;
      }
      
      print('Image captured: ${imageFile.path}');
      _updateState(_state.copyWith(
        status: AppStatus.uploading,
        capturedImage: imageFile,
        uploadProgress: 0.0,
      ));
      
      await _uploadAndProcess(imageFile);
      
    } catch (e) {
      print('Error in capturePhoto: $e');
      _handleError('写真の撮影に失敗しました: ${e.toString()}');
    }
  }

  Future<void> _uploadAndProcess(File imageFile) async {
    try {
      print('Starting upload process...');
      final imageUrl = await _firebaseService.uploadImage(
        imageFile,
        onProgress: (progress) {
          print('Upload progress: $progress');
          _updateState(_state.copyWith(uploadProgress: progress));
        },
      );
      
      print('Upload complete. Image URL: $imageUrl');
      _updateState(_state.copyWith(status: AppStatus.processing));
      
      print('Starting text recognition...');
      final recognizedText = await _firebaseService.recognizeText(imageUrl);
      
      print('Recognized text: $recognizedText');
      if (recognizedText.isEmpty) {
        throw Exception('テキストが認識できませんでした');
      }
      
      _updateState(_state.copyWith(
        status: AppStatus.playing,
        recognizedText: recognizedText,
      ));
      
      print('Starting audio playback...');
      await _audioService.playText(
        recognizedText,
        onComplete: () {
          print('Audio playback complete');
          _updateState(_state.copyWith(status: AppStatus.ready));
        },
      );
      
    } catch (e) {
      print('Error in _uploadAndProcess: $e');
      _handleError(e.toString());
    }
  }

  void stopPlayback() {
    _audioService.stop();
    _updateState(_state.copyWith(status: AppStatus.ready));
  }

  void _handleError(String message) {
    _updateState(_state.copyWith(
      status: AppStatus.ready,
      errorMessage: message,
    ));
  }

  void clearError() {
    _updateState(_state.copyWith(clearError: true));
  }

  void _updateState(AppState newState) {
    _state = newState;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}