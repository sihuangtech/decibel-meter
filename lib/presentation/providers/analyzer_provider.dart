// Provider：管理 PCM 捕获与实时分析（波形/频谱）
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/datasources/audio/pcm_capture.dart';
import '../../core/services/audio_analyzer.dart';
import '../../core/errors/app_failure.dart';

class AnalyzerProvider with ChangeNotifier {
  final PcmCaptureSource source;
  final AudioAnalyzer analyzer;

  StreamSubscription<Float32List>? _pcmSub;
  StreamSubscription<Float32List>? _waveSub;
  StreamSubscription<Float32List>? _specSub;

  Float32List? waveform; // 最近一帧时域
  Float32List? spectrum; // 最近一帧频谱
  String? errorText;
  bool running = false;

  AnalyzerProvider({required this.source, required this.analyzer});

  Future<void> start() async {
    if (running) return;
    errorText = null;
    await source.start();
    _pcmSub = source.pcmStream.listen(
      (pcm) {
        analyzer.addPcm(pcm);
      },
      onError: (e) {
        errorText = e is AppFailure ? e.message : '捕获失败';
        notifyListeners();
      },
    );

    _waveSub = analyzer.waveformStream.listen((w) {
      waveform = w;
      running = true;
      notifyListeners();
    });
    _specSub = analyzer.spectrumStream.listen((s) {
      spectrum = s;
      running = true;
      notifyListeners();
    });
  }

  Future<void> stop() async {
    await _pcmSub?.cancel();
    await _waveSub?.cancel();
    await _specSub?.cancel();
    await source.stop();
    running = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    analyzer.dispose();
    super.dispose();
  }
}
