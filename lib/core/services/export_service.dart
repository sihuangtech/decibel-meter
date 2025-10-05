// 导出服务：将测量记录导出为 CSV/JSON 到应用文档目录
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../domain/entities/measurement.dart';

class ExportService {
  /// 导出为 CSV，返回文件路径
  static Future<String> exportCsv(
    List<Measurement> list, {
    String fileName = 'measurements.csv',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);
    final sink = File(path).openWrite();
    // 表头
    sink.writeln(
      'id,timestamp,decibel,average,max,min,weighting,response,note',
    );
    for (final m in list) {
      sink.writeln(
        '${m.id ?? ""},${m.timestamp},${m.decibel.toStringAsFixed(2)},'
        '${m.average?.toStringAsFixed(2) ?? ""},'
        '${m.max?.toStringAsFixed(2) ?? ""},'
        '${m.min?.toStringAsFixed(2) ?? ""},'
        '${m.weighting},${m.response},${m.note ?? ""}',
      );
    }
    await sink.flush();
    await sink.close();
    return path;
  }

  /// 导出为 JSON，返回文件路径
  static Future<String> exportJson(
    List<Measurement> list, {
    String fileName = 'measurements.json',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);
    final jsonList = list
        .map(
          (m) => {
            'id': m.id,
            'timestamp': m.timestamp,
            'decibel': m.decibel,
            'average': m.average,
            'max': m.max,
            'min': m.min,
            'weighting': m.weighting,
            'response': m.response,
            'note': m.note,
          },
        )
        .toList();
    final jsonStr = const JsonEncoder.withIndent('  ').convert(jsonList);
    await File(path).writeAsString(jsonStr);
    return path;
  }

  /// 直接分享现有文件（CSV/JSON）
  /// 调用方需确保文件已存在且可读
  static Future<void> shareFile(String path) async {
    // 这里仅提供占位接口；若需使用 share_plus，可在调用处直接调用 Share.shareXFiles
    // 保持核心服务不引入 UI 依赖，便于复用与测试
    // 例如：Share.shareXFiles([XFile(path)]);
  }
}
