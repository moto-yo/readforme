import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AudioService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> playText(String text, {Function()? onComplete}) async {
    // Check if user is authenticated
    if (_auth.currentUser == null) {
      throw Exception('ユーザー認証が必要です。再度お試しください。');
    }

    try {
      final callable = _functions.httpsCallable('textToSpeechFunction');
      final result = await callable.call({'text': text});
      
      final audioUrl = result.data['audioUrl'] as String;
      
      // Listen for playback completion
      if (onComplete != null) {
        _audioPlayer.onPlayerComplete.listen((event) {
          onComplete();
        });
      }
      
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      throw Exception('音声再生に失敗しました: ${e.toString()}');
    }
  }

  void stop() {
    _audioPlayer.stop();
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}