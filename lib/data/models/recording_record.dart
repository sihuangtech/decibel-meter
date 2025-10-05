// 数据模型：录音记录表映射
import '../../domain/entities/recording.dart';

class RecordingRecord {
  static const table = 'recordings';
  static const colId = 'id';
  static const colPath = 'path';
  static const colDur = 'duration_ms';
  static const colCreated = 'created_at';
  static const colNote = 'note';

  final int? id;
  final String path;
  final int durationMs;
  final int createdAt;
  final String? note;

  const RecordingRecord({
    this.id,
    required this.path,
    required this.durationMs,
    required this.createdAt,
    this.note,
  });

  Map<String, Object?> toMap() => {
    colId: id,
    colPath: path,
    colDur: durationMs,
    colCreated: createdAt,
    colNote: note,
  };

  factory RecordingRecord.fromMap(Map<String, Object?> map) => RecordingRecord(
    id: map[colId] as int?,
    path: map[colPath] as String,
    durationMs: map[colDur] as int,
    createdAt: map[colCreated] as int,
    note: map[colNote] as String?,
  );

  Recording toEntity() => Recording(
    id: id,
    path: path,
    durationMs: durationMs,
    createdAt: createdAt,
    note: note,
  );

  static RecordingRecord fromEntity(Recording r) => RecordingRecord(
    id: r.id,
    path: r.path,
    durationMs: r.durationMs,
    createdAt: r.createdAt,
    note: r.note,
  );
}
