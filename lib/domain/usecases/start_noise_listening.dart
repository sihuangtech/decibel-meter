// 用例：开始分贝监听（重命名避免与 provider 内部符号冲突）
import '../repositories/noise_repository.dart';

class StartNoiseListening {
  final NoiseRepository repo;
  StartNoiseListening(this.repo);

  Future<void> call() => repo.start();
}
