// 本地数据库（加密版）：基于 sqflite_sqlcipher + flutter_secure_storage
// 说明：首次运行会生成随机密钥并保存到系统安全存储；数据库使用该密钥进行透明加密。
// 注意：如需从旧未加密数据库迁移，请在后续版本加入迁移逻辑（此处先行启用加密存储）。
import 'dart:math';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import '../../models/measurement_record.dart';

class AppDatabase {
  static Database? _db;
  static const _dbFile = 'decibel_meter_enc.db'; // 加密库文件
  static const _kDbKey = 'db_key_v1'; // 安全存储中的密钥键名

  /// 获取数据库实例（单例）
  static Future<Database> instance() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, _dbFile);

    // 生成或读取持久化密钥（长度32-48的随机字符串）
    final storage = const FlutterSecureStorage();
    var key = await storage.read(key: _kDbKey);
    if (key == null || key.isEmpty) {
      key = _generateKey(40);
      await storage.write(key: _kDbKey, value: key);
    }

    _db = await openDatabase(
      dbPath,
      password: key,
      version: 1,
      onCreate: (db, version) async {
        // 测量记录表
        await db.execute('''
          CREATE TABLE ${MeasurementRecord.table} (
            ${MeasurementRecord.colId} INTEGER PRIMARY KEY AUTOINCREMENT,
            ${MeasurementRecord.colTs} INTEGER NOT NULL,
            ${MeasurementRecord.colDb} REAL NOT NULL,
            ${MeasurementRecord.colAvg} REAL,
            ${MeasurementRecord.colMax} REAL,
            ${MeasurementRecord.colMin} REAL,
            ${MeasurementRecord.colWeight} TEXT NOT NULL,
            ${MeasurementRecord.colResp} TEXT NOT NULL,
            ${MeasurementRecord.colNote} TEXT
          );
        ''');

        // 录音记录表（如已存在将忽略）
        await db.execute('''
          CREATE TABLE IF NOT EXISTS recordings(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            path TEXT NOT NULL,
            duration_ms INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            note TEXT
          );
        ''');
      },
    );
    return _db!;
  }

  /// 生成随机密钥（仅包含安全可打印字符）
  static String _generateKey(int length) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_@#%+=';
    final rnd = Random.secure();
    return List.generate(
      length,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }
}
