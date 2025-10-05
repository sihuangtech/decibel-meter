// 噪音类型识别（启发式占位）：基于分贝水平与波动判断交通/人声/机械等
import 'package:flutter/foundation.dart';
import '../../domain/entities/noise_sample.dart';

enum NoiseType { traffic, speech, mechanical, ambient, unknown }

class NoiseClassifierProvider with ChangeNotifier {
  NoiseType current = NoiseType.unknown;
  double _prev = 0;
  int _count = 0;

  void onSample(NoiseSample s) {
    final db = s.decibel;
    final delta = (db - _prev).abs();
    // 简化启发式：
    // - 高均值且波动小：mechanical
    // - 中等水平且周期波动：speech (粗略)
    // - 高水平且波动中等：traffic
    // - 低水平：ambient
    NoiseType t = NoiseType.unknown;
    if (db < 45) {
      t = NoiseType.ambient;
    } else if (db >= 80 && delta < 3) {
      t = NoiseType.mechanical;
    } else if (db >= 70 && delta < 6) {
      t = NoiseType.traffic;
    } else if (db >= 50 && delta >= 6) {
      t = NoiseType.speech;
    }
    _prev = db;
    _count++;
    if (_count % 3 == 0) {
      current = t;
      notifyListeners();
    }
  }
}
