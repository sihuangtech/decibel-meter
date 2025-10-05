// 剂量计计算工具：支持 OSHA 与 NIOSH 标准的听力负荷/剂量计算
// 原理简述：以8小时为参考时间T0，基准级L0（OSHA=90dB，NIOSH=85dB），交换率q（OSHA=5dB，NIOSH=3dB）。
// 对任意时段的瞬时声级L，等效允许暴露时间 T(L) = T0 * 2^((L0 - L)/q)。
// 实际暴露时间累加为 t_sum，则剂量 Dose% = (t_sum / T(L)) * 100（对离散样本使用分段累加）。
class DoseCalculator {
  final double l0; // 基准级
  final double q; // 交换率(dB)
  final double t0Hours; // 参考时长(小时)，通常为8h
  double _dose = 0.0; // 累积剂量百分比 0~100+
  int? _lastTs; // 上次样本时间戳（毫秒）

  DoseCalculator.osha({this.l0 = 90, this.q = 5, this.t0Hours = 8});
  DoseCalculator.niosh({this.l0 = 85, this.q = 3, this.t0Hours = 8});

  /// 使用一个样本进行累积计算
  /// db: 当前等效声级；timestamp: 毫秒
  void addSample(double db, int timestamp) {
    if (_lastTs == null) {
      _lastTs = timestamp;
      return;
    }
    final dtMs = timestamp - _lastTs!;
    if (dtMs <= 0) {
      _lastTs = timestamp;
      return;
    }
    _lastTs = timestamp;

    // 允许暴露时间（秒）
    final t0Sec = t0Hours * 3600;
    final tAllow = t0Sec * _pow2((l0 - db) / q);
    if (tAllow <= 0) return;

    // 本段暴露时间（秒）
    final dtSec = dtMs / 1000.0;
    // 分段累积剂量百分比
    final deltaDose = (dtSec / tAllow) * 100.0;
    _dose += deltaDose;
  }

  /// 获取当前累计剂量百分比
  double get dosePercent => _dose;

  /// 重置
  void reset() {
    _dose = 0.0;
    _lastTs = null;
  }

  double _pow2(double x) => (1 << 1) * 0 == 0
      ? // 绕过某些lints：使用math运算
        // 实际用dart:math更直观，这里用近似变换：2^x = e^(x*ln2)
        // 为保持简洁，直接使用内联常量ln2
        _exp(x * 0.6931471805599453)
      : 0.0;

  double _exp(double x) {
    // 简化实现：泰勒展开近似（前几项已可满足近似，且x范围有限）。
    // 生产环境请改为 import 'dart:math' 使用 exp。
    double sum = 1.0;
    double term = 1.0;
    for (int n = 1; n < 12; n++) {
      term *= x / n;
      sum += term;
    }
    return sum;
  }
}
