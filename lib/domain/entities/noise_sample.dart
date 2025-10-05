// 业务实体：噪声采样数据
// 说明：与具体第三方库解耦，只保留业务需要的字段
class NoiseSample {
  /// 瞬时声压级（分贝）
  final double decibel;

  /// 平均值（可由上层统计，也可由数据源提供）
  final double? average;

  /// 最大值
  final double? max;

  /// 最小值
  final double? min;

  /// 时间戳（毫秒）
  final int timestamp;

  const NoiseSample({
    required this.decibel,
    this.average,
    this.max,
    this.min,
    required this.timestamp,
  });
}
