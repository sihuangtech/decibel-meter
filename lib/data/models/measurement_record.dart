// 数据模型：测量记录的持久化映射（与数据库表结构一一对应）
import '../../domain/entities/measurement.dart';

class MeasurementRecord {
  static const table = 'measurements';
  static const colId = 'id';
  static const colTs = 'timestamp';
  static const colDb = 'decibel';
  static const colAvg = 'average';
  static const colMax = 'max';
  static const colMin = 'min';
  static const colWeight = 'weighting';
  static const colResp = 'response';
  static const colNote = 'note';

  final int? id;
  final int timestamp;
  final double decibel;
  final double? average;
  final double? max;
  final double? min;
  final String weighting;
  final String response;
  final String? note;

  const MeasurementRecord({
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

  Map<String, Object?> toMap() => {
    colId: id,
    colTs: timestamp,
    colDb: decibel,
    colAvg: average,
    colMax: max,
    colMin: min,
    colWeight: weighting,
    colResp: response,
    colNote: note,
  };

  factory MeasurementRecord.fromMap(Map<String, Object?> map) =>
      MeasurementRecord(
        id: map[colId] as int?,
        timestamp: map[colTs] as int,
        decibel: (map[colDb] as num).toDouble(),
        average: (map[colAvg] as num?)?.toDouble(),
        max: (map[colMax] as num?)?.toDouble(),
        min: (map[colMin] as num?)?.toDouble(),
        weighting: map[colWeight] as String,
        response: map[colResp] as String,
        note: map[colNote] as String?,
      );

  Measurement toEntity() => Measurement(
    id: id,
    timestamp: timestamp,
    decibel: decibel,
    average: average,
    max: max,
    min: min,
    weighting: weighting,
    response: response,
    note: note,
  );

  static MeasurementRecord fromEntity(Measurement m) => MeasurementRecord(
    id: m.id,
    timestamp: m.timestamp,
    decibel: m.decibel,
    average: m.average,
    max: m.max,
    min: m.min,
    weighting: m.weighting,
    response: m.response,
    note: m.note,
  );
}
