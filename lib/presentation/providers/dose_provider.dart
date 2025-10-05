// 剂量计 Provider：根据实时分贝流累计 OSHA 与 NIOSH 剂量百分比，提供阈值告警
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../core/utils/dose_calculator.dart';
import '../../domain/entities/noise_sample.dart';
import '../../domain/usecases/get_noise_stream_usecase.dart';

class DoseProvider extends ChangeNotifier {
  final GetNoiseStreamUseCase getNoiseStream;
  final DoseCalculator _osha = DoseCalculator.osha();
  final DoseCalculator _niosh = DoseCalculator.niosh();
  StreamSubscription<NoiseSample>? _sub;

  // 实时剂量百分比（0~100+）
  double oshaDose = 0.0;
  double nioshDose = 0.0;

  // 告警阈值（百分比）
  double warnThreshold = 50.0; // 提示
  double dangerThreshold = 100.0; // 警告

  bool _listening = false;

  DoseProvider(this.getNoiseStream);

  void start() {
    if (_listening) return;
    _sub = getNoiseStream().listen(
      (s) {
        _osha.addSample(s.decibel, s.timestamp);
        _niosh.addSample(s.decibel, s.timestamp);
        oshaDose = _osha.dosePercent;
        nioshDose = _niosh.dosePercent;
        _listening = true;
        notifyListeners();
      },
      onError: (_) {
        _listening = false;
        notifyListeners();
      },
    );
  }

  void reset() {
    _osha.reset();
    _niosh.reset();
    oshaDose = 0.0;
    nioshDose = 0.0;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
