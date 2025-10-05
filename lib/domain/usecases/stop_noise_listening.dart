// 用例：停止分贝监听（重命名避免冲突）
import '../repositories/noise_repository.dart';

class StopNoiseListening {
  final NoiseRepository repo;
  StopNoiseListening(this.repo);

  Future<void> call() => repo.stop();
}
