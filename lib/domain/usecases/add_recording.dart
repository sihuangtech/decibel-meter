// 用例：新增录音记录
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class AddRecording {
  final RecordingRepository repo;
  AddRecording(this.repo);
  Future<int> call(Recording r) => repo.add(r);
}