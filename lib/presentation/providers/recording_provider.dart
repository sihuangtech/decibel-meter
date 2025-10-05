// 录音 Provider：录音控制、写库与列表刷新、播放控制
import 'package:flutter/foundation.dart';
import '../../core/services/recording_service.dart';
import '../../core/services/player_service.dart';
import '../../domain/entities/recording.dart';
import '../../domain/usecases/add_recording.dart';
import '../../domain/usecases/list_recordings.dart';
import '../../domain/usecases/delete_recording.dart';

class RecordingProvider with ChangeNotifier {
  final RecordingService rec;
  final PlayerService player;
  final AddRecording addRecording;
  final ListRecordings listRecordings;
  final DeleteRecording deleteRecording;

  bool isRecording = false;
  List<Recording> items = const [];

  RecordingProvider({
    required this.rec,
    required this.player,
    required this.addRecording,
    required this.listRecordings,
    required this.deleteRecording,
  });

  Future<void> refresh() async {
    items = await listRecordings();
    notifyListeners();
  }

  Future<void> start() async {
    await rec.start();
    isRecording = true;
    notifyListeners();
  }

  Future<void> stopAndSave() async {
    final res = await rec.stop();
    isRecording = false;
    final r = Recording(
      path: res.path,
      durationMs: res.durationMs,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    await addRecording(r);
    await refresh();
  }

  Future<void> play(String path) => player.play(path);
  Future<void> stopPlay() => player.stop();

  Future<void> remove(int id) async {
    await deleteRecording(id);
    await refresh();
  }

  void disposePlayer() => player.dispose();
}