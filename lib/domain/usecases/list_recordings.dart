// 用例：查询录音列表
import '../entities/recording.dart';
import '../repositories/recording_repository.dart';

class ListRecordings {
  final RecordingRepository repo;
  ListRecordings(this.repo);
  Future<List<Recording>> call({int? limit}) => repo.list(limit: limit);
}