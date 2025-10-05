// 用例：查询测量记录列表（可选限制/时间条件）
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

class GetMeasurements {
  final MeasurementRepository repo;
  GetMeasurements(this.repo);

  Future<List<Measurement>> call({int? limit, int? sinceTs}) =>
      repo.list(limit: limit, sinceTs: sinceTs);
}
