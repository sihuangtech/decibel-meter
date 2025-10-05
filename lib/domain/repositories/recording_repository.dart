// 仓储接口：录音记录的增删查
import '../entities/recording.dart';

abstract class RecordingRepository {
  Future<int> add(Recording r);
  Future<List<Recording>> list({int? limit});
  Future<int> remove(int id);
}
