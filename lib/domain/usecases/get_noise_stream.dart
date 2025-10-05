// 用例：获取分贝流
import '../entities/noise_sample.dart';
import '../repositories/noise_repository.dart';

class GetNoiseStream {
  final NoiseRepository repo;
  GetNoiseStream(this.repo);

  Stream<NoiseSample> call() => repo.stream();
}
