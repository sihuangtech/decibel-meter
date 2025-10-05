// 业务实体：测量记录（用于历史存储/导出/可视化）
class Measurement {
  /// 记录唯一标识（自增或UUID），这里用可选int以配合sqflite自增
  final int? id;

  /// 时间戳（毫秒）
  final int timestamp;

  /// 瞬时分贝值
  final double decibel;

  /// 平均/最大/最小（可选）
  final double? average;
  final double? max;
  final double? min;

  /// 设置快照（占位：加权与响应）
  final String weighting; // 'A' | 'C' | 'Z'
  final String response; // 'fast' | 'slow'
  /// 备注（预留）
  final String? note;

  const Measurement({
    this.id,
    required this.timestamp,
    required this.decibel,
    this.average,
    this.max,
    this.min,
    required this.weighting,
    required this.response,
    this.note,
  });
}
