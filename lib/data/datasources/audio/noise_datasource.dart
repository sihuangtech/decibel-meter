// 数据源：基于 noise_meter 的移动端实现 + 桌面端友好提示
// 说明：noise_meter 5.1.0 提供 NoiseMeter.noise 流与 NoiseReading(meanDecibel/maxDecibel)
// 当前不直接支持 dBA/dBC/dBZ 加权与快/慢响应，接口处先保留参数占位，后续可替换更专业实现
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:noise_meter/noise_meter.dart';
import '../../../core/utils/platform_utils.dart';
import '../../../domain/entities/noise_sample.dart';
import '../../../core/errors/app_failure.dart';

/// 数据源抽象
abstract class NoiseDataSource {
  Future<void> start();
  Future<void> stop();
  Stream<NoiseSample> stream();
}

/// 移动端实现（iOS/Android 使用 noise_meter）
/// 桌面平台返回友好错误，可在后续替换为桌面端实现
class NoiseDataSourceImpl implements NoiseDataSource {
  final _controller = StreamController<NoiseSample>.broadcast();

  // 可选占位：加权与响应速度（当前 noise_meter 未直接支持）
  final String weighting; // 'A' | 'C' | 'Z'
  final String response; // 'fast' | 'slow'

  NoiseMeter? _noiseMeter;
  StreamSubscription<NoiseReading>? _sub;

  NoiseDataSourceImpl({this.weighting = 'A', this.response = 'fast'});

  @override
  Future<void> start() async {
    if (!PlatformUtils.isMobile) {
      _controller.addError(
        AppFailure.platformNotSupported(
          PlatformUtils.isDesktop ? 'Desktop' : 'Unknown',
        ),
      );
      return;
    }
    if (_sub != null) return;

    // 创建 NoiseMeter 并订阅其 noise 流
    _noiseMeter ??= NoiseMeter();
    _sub = _noiseMeter!.noise.listen(
      (NoiseReading reading) {
        // 映射为领域实体：将平均分贝作为“当前值”，最大分贝作为 max
        final sample = NoiseSample(
          decibel: reading.meanDecibel,
          average: reading.meanDecibel,
          max: reading.maxDecibel,
          min: null,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );
        _controller.add(sample);
      },
      onError: (e, st) {
        debugPrint('NoiseMeter error: $e');
        _controller.addError(AppFailure.unexpected(e, st));
      },
    );
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  @override
  Stream<NoiseSample> stream() => _controller.stream;

  // 资源释放（可在应用退出或 Provider dispose 时调用）
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
