// 录音服务：封装 record 录音并保存到应用文档目录
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class RecordingService {
  final AudioRecorder _rec = AudioRecorder();
  String? _currentPath;
  DateTime? _startAt;

  Future<bool> hasPermission() => _rec.hasPermission();

  Future<String> start() async {
    final ok = await hasPermission();
    if (!ok) {
      throw Exception('录音权限被拒绝');
    }
    final dir = await getApplicationDocumentsDirectory();
    final ts = DateTime.now();
    _startAt = ts;
    final fname = 'rec_${ts.millisecondsSinceEpoch}.m4a';
    final full = p.join(dir.path, 'recordings');
    await Directory(full).create(recursive: true);
    final out = p.join(full, fname);
    await _rec.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: out,
    );
    _currentPath = out;
    return out;
  }

  Future<({String path, int durationMs})> stop() async {
    final path = await _rec.stop();
    final end = DateTime.now();
    final start = _startAt ?? end;
    final dur = end.difference(start).inMilliseconds;
    _currentPath = path ?? _currentPath;
    return (path: _currentPath!, durationMs: dur);
  }
}
