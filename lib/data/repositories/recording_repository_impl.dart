// 仓储实现：基于 sqflite 的录音列表

import '../../domain/entities/recording.dart';
import '../../domain/repositories/recording_repository.dart';
import '../datasources/local/app_database.dart';
import '../models/recording_record.dart';

class RecordingRepositoryImpl implements RecordingRepository {
  @override
  Future<int> add(Recording r) async {
    final db = await AppDatabase.instance();
    return db.insert(
      RecordingRecord.table,
      RecordingRecord.fromEntity(r).toMap(),
    );
  }

  @override
  Future<List<Recording>> list({int? limit}) async {
    final db = await AppDatabase.instance();
    final rows = await db.query(
      RecordingRecord.table,
      orderBy: '${RecordingRecord.colCreated} DESC',
      limit: limit,
    );
    return rows.map((e) => RecordingRecord.fromMap(e).toEntity()).toList();
  }

  @override
  Future<int> remove(int id) async {
    final db = await AppDatabase.instance();
    return db.delete(RecordingRecord.table, where: 'id=?', whereArgs: [id]);
  }
}
