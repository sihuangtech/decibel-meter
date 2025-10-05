// 用例：保存一条测量记录
import '../entities/measurement.dart';
import '../repositories/measurement_repository.dart';

class SaveMeasurement {
  final MeasurementRepository repo;
  SaveMeasurement(this.repo);

  Future<int> call(Measurement m) => repo.add(m);
}
