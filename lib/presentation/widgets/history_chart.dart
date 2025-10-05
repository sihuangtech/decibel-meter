// 历史曲线组件：使用 fl_chart 绘制最近分贝折线
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/measurement.dart';

class HistoryChart extends StatelessWidget {
  final List<Measurement> data;
  const HistoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const SizedBox(height: 140, child: Center(child: Text('暂无数据')));
    }
    final spots = <FlSpot>[];
    // 使用索引作为X轴，简单等间距绘制
    for (var i = 0; i < data.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[i].decibel));
    }

    return SizedBox(
      height: 140,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2,
              dotData: const FlDotData(show: false),
            ),
          ],
          minY: 20,
          maxY: 120,
        ),
      ),
    );
  }
}
