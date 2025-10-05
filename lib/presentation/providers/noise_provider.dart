// Provider 状态：管理权限、监听状态与统计数据 + 加权/响应速度占位
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/errors/app_failure.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/settings_service.dart';
import '../../domain/entities/noise_sample.dart';
import '../../domain/usecases/get_noise_stream_usecase.dart';
import '../../domain/usecases/start_noise_listening.dart';
import '../../domain/usecases/stop_noise_listening.dart';

/// 分贝加权模式占位（底层库暂不支持，保留设置以便后续实现）
enum Weighting { a, c, z }

/// 响应速度占位（底层库暂不支持，保留设置以便后续实现）
enum ResponseSpeed { fast, slow }

class NoiseProvider extends ChangeNotifier {
  final StartNoiseListening startListening;
  final StopNoiseListening stopListening;
  final GetNoiseStreamUseCase getNoiseStream;

  StreamSubscription<NoiseSample>? _sub;

  // 状态字段
  bool isListening = false;
  double? currentDb;
  double? minDb;
  double? maxDb;
  double? avgDb;
  String? errorText;

  // 校准偏移（dB）
  double calibrationOffset = 0.0;

  // 设置：加权与响应速度（占位）
  Weighting weighting = Weighting.a;
  ResponseSpeed responseSpeed = ResponseSpeed.fast;

  NoiseProvider({
    required this.startListening,
    required this.stopListening,
    required this.getNoiseStream,
  }) {
    _loadSettings();
  }

  /// 申请权限并开始监听
  Future<void> requestPermissionAndStart() async {
    errorText = null;
    final granted = await PermissionService.requestMicrophonePermission();
    if (!granted) {
      errorText = AppFailure.permissionDenied('需要麦克风权限').message;
      notifyListeners();
      return;
    }
    await start();
  }

  /// 开始
  Future<void> start() async {
    try {
      await startListening();
      _sub ??= getNoiseStream().listen(
        (sample) {
          final db = (sample.decibel + calibrationOffset);
          currentDb = db;
          // 简易统计：从流中聚合（生产中可使用加权窗口/滤波）
          if (minDb == null || db < (minDb ?? db)) minDb = db;
          if (maxDb == null || db > (maxDb ?? db)) maxDb = db;
          // 简化平均：滚动平均（此处仅示例，后续可替换为加权/时间窗口）
          if (avgDb == null) {
            avgDb = db;
          } else {
            avgDb = (avgDb! * 0.9) + (db * 0.1);
          }
          isListening = true;
          notifyListeners();
        },
        onError: (e, _) {
          errorText = e is AppFailure ? e.message : '采集出错';
          isListening = false;
          notifyListeners();
        },
      );
    } catch (e) {
      errorText = '启动失败';
      isListening = false;
      notifyListeners();
    }
  }

  /// 停止
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    try {
      await stopListening();
    } catch (_) {}
    isListening = false;
    notifyListeners();
  }

  /// 设置校准偏移
  void setCalibrationOffset(double offset) {
    calibrationOffset = offset;
    // 持久化校准偏移
    SettingsService.saveCalibration(offset);
    notifyListeners();
  }

  /// 设置加权模式（占位）
  void setWeighting(Weighting w) {
    weighting = w;
    // 持久化加权模式
    final str = switch (w) {
      Weighting.a => 'A',
      Weighting.c => 'C',
      Weighting.z => 'Z',
    };
    SettingsService.saveWeighting(str);
    notifyListeners();
  }

  /// 设置响应速度（占位）
  void setResponseSpeed(ResponseSpeed r) {
    responseSpeed = r;
    // 持久化响应速度
    final str = switch (r) {
      ResponseSpeed.fast => 'fast',
      ResponseSpeed.slow => 'slow',
    };
    SettingsService.saveResponse(str);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // 私有：加载持久化设置
  Future<void> _loadSettings() async {
    try {
      calibrationOffset = await SettingsService.readCalibration();
      final w = (await SettingsService.readWeighting()).toUpperCase();
      weighting = switch (w) {
        'C' => Weighting.c,
        'Z' => Weighting.z,
        _ => Weighting.a,
      };
      final r = (await SettingsService.readResponse()).toLowerCase();
      responseSpeed = r == 'slow' ? ResponseSpeed.slow : ResponseSpeed.fast;
      notifyListeners();
    } catch (_) {
      // 忽略读取失败，保持默认
    }
  }
}
