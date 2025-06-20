import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/app_state.dart';
import '../widgets/camera_button.dart';
import '../widgets/photo_preview.dart';
import '../widgets/loading_indicator.dart';
import '../widgets/text_display.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastErrorMessage;
  bool _isSnackBarShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      provider.addListener(_handleErrors);
    });
  }

  void _handleErrors() {
    final provider = context.read<AppProvider>();
    final errorMessage = provider.state.errorMessage;

    // Reset _lastErrorMessage when error is cleared
    if (errorMessage == null) {
      _lastErrorMessage = null;
      return;
    }

    // Only show SnackBar if:
    // 1. There's a new error message
    // 2. It's different from the last one we showed
    // 3. We're not already showing a SnackBar
    if (errorMessage != _lastErrorMessage && !_isSnackBarShowing) {
      _lastErrorMessage = errorMessage;
      _isSnackBarShowing = true;

      // Hide any existing SnackBar before showing new one
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(color: Colors.white)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
              onVisible: () {
                // Clear the error after showing the SnackBar
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    provider.clearError();
                  }
                });
              },
            ),
          )
          .closed
          .then((_) {
            if (mounted) {
              _isSnackBarShowing = false;
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('よみあげくん'), centerTitle: true, backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: SafeArea(
        child: Consumer<AppProvider>(
          builder: (context, provider, child) {
            final state = provider.state;

            switch (state.status) {
              case AppStatus.ready:
                return const CameraButton();

              case AppStatus.capturing:
                return const LoadingIndicator(message: '写真を撮影中...');

              case AppStatus.uploading:
                return Column(
                  children: [
                    Expanded(child: PhotoPreview(imageFile: state.capturedImage!)),
                    LoadingIndicator(message: 'アップロード中...', progress: state.uploadProgress),
                  ],
                );

              case AppStatus.processing:
                return Column(
                  children: [
                    Expanded(child: PhotoPreview(imageFile: state.capturedImage!)),
                    const LoadingIndicator(message: 'テキストを認識中...'),
                  ],
                );

              case AppStatus.playing:
                return Column(
                  children: [
                    Expanded(child: PhotoPreview(imageFile: state.capturedImage!)),
                    Expanded(child: TextDisplay(text: state.recognizedText!)),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton(
                        onPressed: provider.stopPlayback,
                        style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('終了する', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                  ],
                );
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    final provider = context.read<AppProvider>();
    provider.removeListener(_handleErrors);
    super.dispose();
  }
}
