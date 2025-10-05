// 仓储实现：基于 sqflite 的测量记录存取
import '../../domain/entities/measurement.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/measurement_record.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  @override
  Future<int> add(Measurement m) async {
    final db = await AppDatabase.instance();
    return db.insert(
      MeasurementRecord.table,
      MeasurementRecord.fromEntity(m).toMap(),
    );
  }

  @override
  Future<List<Measurement>> list({int? limit, int? sinceTs}) async {
    final db = await AppDatabase.instance();
    final where = sinceTs != null ? '${MeasurementRecord.colTs} >= ?' : null;
    final whereArgs = sinceTs != null ? [sinceTs] : null;
    final maps = await db.query(
      MeasurementRecord.table,
      orderBy: '${MeasurementRecord.colTs} DESC',
      limit: limit,
      where: where,
      whereArgs: whereArgs,
    );
    return maps.map((e) => MeasurementRecord.fromMap(e).toEntity()).toList();
  }

  @override
  Future<int> clear() async {
    final db = await AppDatabase.instance();
    return db.delete(MeasurementRecord.table);
  }
}
