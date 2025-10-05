// 波形组件（增强版）：支持语义、渐变、响应式高度（仍为分贝近似；真实PCM在移动端由 AnalyzerProvider 驱动）
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> recentDb; // 最近N个分贝值
  const WaveformWidget({super.key, required this.recentDb});

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < recentDb.length; i++)
        FlSpot(i.toDouble(), recentDb[i]),
    ];
    return LayoutBuilder(
      builder: (ctx, c) {
        final h = ((c.maxHeight.isFinite ? c.maxHeight : 160.0).clamp(
          120.0,
          240.0,
        )).toDouble();
        final cs = Theme.of(context).colorScheme;
        return Semantics(
          label: '实时波形',
          hint: '展示最近的声压级变化趋势',
          child: SizedBox(
            height: h,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                titlesData: FlTitlesData(show: false),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    dotData: const FlDotData(show: false),
                    gradient: LinearGradient(colors: [cs.primary, cs.tertiary]),
                    barWidth: 2.5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
