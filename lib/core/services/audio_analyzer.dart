// 音频分析服务：窗口化原始 PCM，计算波形与频谱（内置 FFT 实现）
// 说明：
// - 输入：Float32List 单声道样本（线性 PCM，范围约 -1~1）
// - 处理：滑动窗口、汉宁窗、快速傅里叶变换（Radix-2 Cooley–Tukey）
// - 输出：
//   * waveformStream: 最近一帧时域数据（-1~1）
//   * spectrumStream: 频谱幅度（dBFS 近似）
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

class AudioAnalyzer {
  final int sampleRate;
  final int fftSize; // 典型 1024/2048，需为2的幂
  final int hopSize; // 帧移（小于等于 fftSize）
  final _waveController = StreamController<Float32List>.broadcast();
  final _specController = StreamController<Float32List>.broadcast();

  // 汉宁窗
  late final Float32List _window;
  // 环形缓冲
  late final Float32List _ring;
  int _ringWrite = 0;
  bool _initialized = false;

  Stream<Float32List> get waveformStream => _waveController.stream;
  Stream<Float32List> get spectrumStream => _specController.stream;

  AudioAnalyzer({this.sampleRate = 44100, this.fftSize = 1024, int? hop})
    : hopSize = hop ?? 512 {
    if (!_isPowerOfTwo(fftSize)) {
      throw ArgumentError('fftSize 必须是 2 的幂');
    }
    _initWindow();
    _ring = Float32List(fftSize * 4);
  }

  bool _isPowerOfTwo(int n) => n > 0 && (n & (n - 1)) == 0;

  void _initWindow() {
    _window = Float32List(fftSize);
    for (int n = 0; n < fftSize; n++) {
      _window[n] = 0.5 * (1 - math.cos(2 * math.pi * n / (fftSize - 1)));
    }
    _initialized = true;
  }

  // 输入一块连续样本，内部聚合至足够长度再做分析
  void addPcm(Float32List mono) {
    if (!_initialized) return;
    // 写入环形缓冲
    for (final v in mono) {
      _ring[_ringWrite] = v;
      _ringWrite = (_ringWrite + 1) % _ring.length;
    }
    // 触发分析（简单策略：每来一批都触发一次）
    _analyzeFrame();
  }

  void _analyzeFrame() {
    // 从环形缓冲中取出末尾 fftSize 个样本
    final frame = Float32List(fftSize);
    int idx = (_ringWrite - fftSize) % _ring.length;
    if (idx < 0) idx += _ring.length;
    for (int i = 0; i < fftSize; i++) {
      frame[i] = _ring[(idx + i) % _ring.length];
    }

    // 输出波形
    _waveController.add(frame);

    // 加窗
    final windowed = Float32List(fftSize);
    for (int i = 0; i < fftSize; i++) {
      windowed[i] = frame[i] * _window[i];
    }

    // FFT（就地算法：real/imag）
    final real = List<double>.from(windowed);
    final imag = List<double>.filled(fftSize, 0.0);
    _fftRadix2(real, imag);

    // 仅保留正频率 bins (N/2)
    final bins = fftSize ~/ 2;
    final mag = Float32List(bins);
    for (int k = 0; k < bins; k++) {
      final re = real[k];
      final im = imag[k];
      final amp = math.sqrt(re * re + im * im) / (fftSize / 2.0); // 归一化
      mag[k] = (20 * math.log(amp + 1e-12) / math.ln10);
    }
    _specController.add(mag);
  }

  // 基于 Cooley–Tukey 的迭代 Radix-2 FFT
  void _fftRadix2(List<double> real, List<double> imag) {
    final n = real.length;
    // 位反转置换
    int j = 0;
    for (int i = 0; i < n; i++) {
      if (i < j) {
        final tr = real[j];
        real[j] = real[i];
        real[i] = tr;
        final ti = imag[j];
        imag[j] = imag[i];
        imag[i] = ti;
      }
      int m = n >> 1;
      while (m >= 1 && j >= m) {
        j -= m;
        m >>= 1;
      }
      j += m;
    }
    // 蝶形运算
    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * math.pi / len;
      final wlenCos = math.cos(ang);
      final wlenSin = math.sin(ang);
      for (int i = 0; i < n; i += len) {
        double wcos = 1.0, wsin = 0.0;
        for (int k = 0; k < len ~/ 2; k++) {
          final uRe = real[i + k];
          final uIm = imag[i + k];
          final vRe =
              real[i + k + len ~/ 2] * wcos - imag[i + k + len ~/ 2] * wsin;
          final vIm =
              real[i + k + len ~/ 2] * wsin + imag[i + k + len ~/ 2] * wcos;
          real[i + k] = uRe + vRe;
          imag[i + k] = uIm + vIm;
          real[i + k + len ~/ 2] = uRe - vRe;
          imag[i + k + len ~/ 2] = uIm - vIm;
          // 旋转因子递推
          final nwcos = wcos * wlenCos - wsin * wlenSin;
          final nwsin = wcos * wlenSin + wsin * wlenCos;
          wcos = nwcos;
          wsin = nwsin;
        }
      }
    }
  }

  Future<void> dispose() async {
    await _waveController.close();
    await _specController.close();
  }
}
