// 仓储接口：定义噪声测量相关的领域操作
// 说明：上层用例依赖此接口，屏蔽具体数据源实现
import '../entities/noise_sample.dart';

abstract class NoiseRepository {
  /// 开始监听分贝流
  Future<void> start();

  /// 停止监听
  Future<void> stop();

  /// 获取实时分贝流
  Stream<NoiseSample> stream();
}
