// 播放服务：封装 just_audio 播放本地文件
import 'package:just_audio/just_audio.dart';

class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Future<void> play(String filePath) async {
    await _player.setFilePath(filePath);
    await _player.play();
  }

  Future<void> stop() => _player.stop();
  Future<void> pause() => _player.pause();
  void dispose() => _player.dispose();
}
