// 用例：停止分贝监听
import '../repositories/noise_repository.dart';

class StopListening {
  final NoiseRepository repo;
  StopListening(this.repo);

  Future<void> call() => repo.stop();
}
