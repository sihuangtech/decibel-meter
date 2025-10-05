// 用例：开始分贝监听
import '../repositories/noise_repository.dart';

class StartListening {
  final NoiseRepository repo;
  StartListening(this.repo);

  Future<void> call() => repo.start();
}
