// 用例：清空测量记录
import '../repositories/measurement_repository.dart';

class ClearMeasurements {
  final MeasurementRepository repo;
  ClearMeasurements(this.repo);

  Future<int> call() => repo.clear();
}
