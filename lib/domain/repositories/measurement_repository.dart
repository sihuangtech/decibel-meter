// 仓储接口：测量记录的增删查
import '../entities/measurement.dart';

abstract class MeasurementRepository {
  Future<int> add(Measurement m);
  Future<List<Measurement>> list({int? limit, int? sinceTs});
  Future<int> clear();
}
