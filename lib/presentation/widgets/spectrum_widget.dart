// 频谱组件（增强版）：增加语义与渐变、响应式高度；移动端真实频谱由 AnalyzerProvider 提供
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpectrumWidget extends StatelessWidget {
  final List<double> windowDb; // 最近窗口的分贝或频谱幅度（0-120近似）
  const SpectrumWidget({super.key, required this.windowDb});

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(42);
    final bands = 24;
    final cs = Theme.of(context).colorScheme;

    final values = List<double>.generate(bands, (i) {
      final base = windowDb.isEmpty ? 0 : windowDb.last;
      final jitter = rnd.nextDouble() * 4 - 2;
      return (base + jitter).clamp(0, 120).toDouble();
    });

    final rods = <BarChartGroupData>[
      for (var i = 0; i < bands; i++)
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: values[i],
              width: 6,
              gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(4),
              ),
            ),
          ],
        ),
    ];

    return LayoutBuilder(
      builder: (ctx, c) {
        final h = ((c.maxHeight.isFinite ? c.maxHeight : 160.0).clamp(
          120.0,
          240.0,
        )).toDouble();
        return Semantics(
          label: '实时频谱',
          hint: '展示频带能量分布',
          child: SizedBox(
            height: h,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: rods,
              ),
            ),
          ),
        );
      },
    );
  }
}
