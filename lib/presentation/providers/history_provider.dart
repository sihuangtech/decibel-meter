// 历史记录 Provider：控制是否记录、接收分贝流并持久化，提供最近的曲线数据
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/noise_sample.dart';
import '../../domain/usecases/get_noise_stream_usecase.dart';
import '../../domain/usecases/save_measurement.dart';
import '../../domain/usecases/get_measurements.dart';
import '../../domain/usecases/clear_measurements.dart';
import '../providers/noise_provider.dart';

class HistoryProvider extends ChangeNotifier {
  final GetNoiseStreamUseCase getNoiseStream;
  final SaveMeasurement saveMeasurement;
  final GetMeasurements getMeasurements;
  final ClearMeasurements clearMeasurements;

  bool recording = false; // 是否记录到数据库
  final List<Measurement> recent = []; // 最近N条用于画图
  StreamSubscription<NoiseSample>? _sub;
  int _lastSavedTs = 0;

  // 设置快照来源（加权/响应），简单从 NoiseProvider 读取
  Weighting weighting;
  ResponseSpeed response;

  HistoryProvider({
    required this.getNoiseStream,
    required this.saveMeasurement,
    required this.getMeasurements,
    required this.clearMeasurements,
    this.weighting = Weighting.a,
    this.response = ResponseSpeed.fast,
  });

  void attachSettings(Weighting w, ResponseSpeed r) {
    weighting = w;
    response = r;
  }

  Future<void> start(GetNoiseStreamUseCase streamUseCase) async {
    // 订阅实时流，仅当 recording=true 时写库；同时维护内存 recent
    _sub ??= streamUseCase().listen((s) async {
      final m = Measurement(
        timestamp: s.timestamp,
        decibel: s.decibel,
        average: s.average,
        max: s.max,
        min: s.min,
        weighting: _weightingStr(),
        response: _responseStr(),
      );
      _pushRecent(m);
      if (recording) {
        // 限制保存频率：每 >=1000ms 保存一条，避免过多数据
        if (m.timestamp - _lastSavedTs >= 1000) {
          _lastSavedTs = m.timestamp;
          await saveMeasurement(m);
        }
      }
      notifyListeners();
    });
  }

  void _pushRecent(Measurement m, {int maxLen = 120}) {
    recent.add(m);
    if (recent.length > maxLen) {
      recent.removeAt(0);
    }
  }

  void setRecording(bool v) {
    recording = v;
    notifyListeners();
  }

  Future<List<Measurement>> loadHistory({int? limit}) =>
      getMeasurements(limit: limit);

  Future<void> clearAll() async {
    await clearMeasurements();
    recent.clear();
    notifyListeners();
  }

  String _weightingStr() => switch (weighting) {
    Weighting.a => 'A',
    Weighting.c => 'C',
    Weighting.z => 'Z',
  };

  String _responseStr() => switch (response) {
    ResponseSpeed.fast => 'fast',
    ResponseSpeed.slow => 'slow',
  };

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
