// 设置服务：基于 shared_preferences 持久化应用设置（校准/加权/响应/主题/保存策略）
import 'package:shared_preferences/shared_preferences.dart';

/// 统一管理应用配置的读写服务
/// - 校准偏移：double
/// - 加权模式：'A' | 'C' | 'Z'
/// - 响应速度：'fast' | 'slow'
/// - 主题模式：0=跟随系统,1=浅色,2=深色
/// - 自动保存：bool
/// - 历史保留天数：int（0 表示不限制）
/// 后续可扩展更多设置项
class SettingsService {
  static const _kCalibration = 'calibration_offset';
  static const _kWeighting = 'weighting'; // A/C/Z
  static const _kResponse = 'response'; // fast/slow
  static const _kDarkMode = 'dark_mode'; // 0=system,1=light,2=dark
  static const _kAutoSave = 'auto_save_history'; // 是否自动保存测量
  static const _kRetentionDays = 'history_retention_days'; // 保留天数

  // 校准
  static Future<void> saveCalibration(double v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setDouble(_kCalibration, v);
  }

  static Future<double> readCalibration() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getDouble(_kCalibration) ?? 0.0;
  }

  // 加权
  static Future<void> saveWeighting(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWeighting, v);
  }

  static Future<String> readWeighting() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kWeighting) ?? 'A';
  }

  // 响应
  static Future<void> saveResponse(String v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kResponse, v);
  }

  static Future<String> readResponse() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kResponse) ?? 'fast';
  }

  // 主题
  static Future<void> saveDarkMode(int v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kDarkMode, v);
  }

  static Future<int> readDarkMode() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kDarkMode) ?? 0;
  }

  // 自动保存测量
  static Future<void> saveAutoSaveHistory(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kAutoSave, v);
  }

  static Future<bool> readAutoSaveHistory() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kAutoSave) ?? true;
  }

  // 历史保留天数
  static Future<void> saveRetentionDays(int days) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_kRetentionDays, days);
  }

  static Future<int> readRetentionDays() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(_kRetentionDays) ?? 30;
  }
}
