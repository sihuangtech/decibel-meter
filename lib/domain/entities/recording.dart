// 业务实体：录音记录（文件路径/时长/创建时间）
// 说明：与播放和分享等功能解耦，聚焦元数据管理
class Recording {
  final int? id; // 自增ID
  final String path; // 文件绝对路径
  final int durationMs; // 时长（毫秒）
  final int createdAt; // 创建时间戳（毫秒）
  final String? note; // 备注（可选）

  const Recording({
    this.id,
    required this.path,
    required this.durationMs,
    required this.createdAt,
    this.note,
  });

  Recording copyWith({
    int? id,
    String? path,
    int? durationMs,
    int? createdAt,
    String? note,
  }) => Recording(
    id: id ?? this.id,
    path: path ?? this.path,
    durationMs: durationMs ?? this.durationMs,
    createdAt: createdAt ?? this.createdAt,
    note: note ?? this.note,
  );
}
