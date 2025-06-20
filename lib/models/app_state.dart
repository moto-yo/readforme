import 'dart:io';

enum AppStatus {
  ready,
  capturing,
  uploading,
  processing,
  playing,
}

class AppState {
  final AppStatus status;
  final File? capturedImage;
  final String? recognizedText;
  final String? errorMessage;
  final double uploadProgress;

  AppState({
    this.status = AppStatus.ready,
    this.capturedImage,
    this.recognizedText,
    this.errorMessage,
    this.uploadProgress = 0.0,
  });

  AppState copyWith({
    AppStatus? status,
    File? capturedImage,
    String? recognizedText,
    String? errorMessage,
    double? uploadProgress,
    bool clearError = false,
  }) {
    return AppState(
      status: status ?? this.status,
      capturedImage: capturedImage ?? this.capturedImage,
      recognizedText: recognizedText ?? this.recognizedText,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }
}