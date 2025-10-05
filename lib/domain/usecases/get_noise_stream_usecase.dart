// 用例：获取分贝流（重命名避免与其它命名冲突）
import '../entities/noise_sample.dart';
import '../repositories/noise_repository.dart';

class GetNoiseStreamUseCase {
  final NoiseRepository repo;
  GetNoiseStreamUseCase(this.repo);

  Stream<NoiseSample> call() => repo.stream();
}
