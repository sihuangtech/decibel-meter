// 用例：删除录音记录
import '../repositories/recording_repository.dart';

class DeleteRecording {
  final RecordingRepository repo;
  DeleteRecording(this.repo);
  Future<int> call(int id) => repo.remove(id);
}