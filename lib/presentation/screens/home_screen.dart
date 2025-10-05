// 首页界面：展示当前/最小/最大/平均分贝，提供开始/停止、校准与设置项（加权/响应速度占位）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/providers/noise_provider.dart';
import '../../presentation/providers/history_provider.dart';
import '../../presentation/providers/dose_provider.dart';
import '../../presentation/widgets/history_chart.dart';
import '../../presentation/widgets/waveform_widget.dart';
import '../../presentation/widgets/spectrum_widget.dart';
import '../../presentation/widgets/spl_gauge.dart';
import '../../presentation/providers/analyzer_provider.dart';
import '../../core/utils/platform_utils.dart';
import '../../core/services/export_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<NoiseProvider>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('分贝测量仪')),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
              children: [
                if (vm.errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      vm.errorText!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (PlatformUtils.isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '提示：当前为桌面平台，默认实现暂不支持实时分贝采集，可在数据源处替换为桌面实现。',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                // 设置行：加权/响应速度（占位）
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Weighting>(
                        initialValue: vm.weighting,
                        decoration: const InputDecoration(
                          labelText: '加权模式',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: Weighting.a,
                            child: Text('A 加权'),
                          ),
                          DropdownMenuItem(
                            value: Weighting.c,
                            child: Text('C 加权'),
                          ),
                          DropdownMenuItem(
                            value: Weighting.z,
                            child: Text('Z 加权'),
                          ),
                        ],
                        onChanged: (v) => v != null ? vm.setWeighting(v) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ResponseSpeed>(
                        initialValue: vm.responseSpeed,
                        decoration: const InputDecoration(
                          labelText: '响应速度',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: ResponseSpeed.fast,
                            child: Text('快速'),
                          ),
                          DropdownMenuItem(
                            value: ResponseSpeed.slow,
                            child: Text('慢速'),
                          ),
                        ],
                        onChanged: (v) =>
                            v != null ? vm.setResponseSpeed(v) : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 最近分贝迷你曲线图
                const SizedBox(height: 12),
                Consumer<HistoryProvider>(
                  builder: (_, hp, __) => HistoryChart(data: hp.recent),
                ),
                const SizedBox(height: 12),
                // 真实波形/频谱/SPL 指示
                Consumer<AnalyzerProvider>(
                  builder: (_, ap, __) {
                    // 回退：若未运行或无数据，用历史分贝近似
                    final fallback = context.read<HistoryProvider>().recent;
                    final List<double> recent = fallback.isNotEmpty
                        ? fallback.map((e) => (e as num).toDouble()).toList()
                        : (vm.currentDb != null
                              ? List<double>.filled(64, vm.currentDb!)
                              : <double>[]);
                    final List<double> wave = ap.running && ap.waveform != null
                        ? ap.waveform!.toList()
                        : recent;
                    final List<double> spec = ap.running && ap.spectrum != null
                        ? ap.spectrum!.toList()
                        : recent;
                    return Row(
                      children: [
                        SizedBox(width: 200, height: 160, child: WaveformWidget(recentDb: wave)),
                        const SizedBox(width: 8),
                        SizedBox(width: 200, height: 160, child: SpectrumWidget(windowDb: spec)),
                        const SizedBox(width: 8),
                        SizedBox(width: 36, height: 160, child: SplGauge(db: vm.currentDb)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          '当前分贝 (dB)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.currentDb?.toStringAsFixed(1) ?? '--',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 剂量计（OSHA/NIOSH）
                Consumer<DoseProvider>(
                  builder: (_, dp, __) {
                    Color colorFor(double v) {
                      if (v >= dp.dangerThreshold) {
                        return Theme.of(context).colorScheme.error;
                      }
                      if (v >= dp.warnThreshold) {
                        return Colors.orange;
                      }
                      return Theme.of(context).colorScheme.primary;
                    }

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('OSHA 剂量'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dp.oshaDose.toStringAsFixed(1)} %',
                                    style: TextStyle(
                                      color: colorFor(dp.oshaDose),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('NIOSH 剂量'),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dp.nioshDose.toStringAsFixed(1)} %',
                                    style: TextStyle(
                                      color: colorFor(dp.nioshDose),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: '重置剂量',
                              onPressed: dp.reset,
                              icon: const Icon(Icons.refresh),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(child: _StatTile(label: '最小', value: vm.minDb)),
                    const SizedBox(width: 8),
                    Flexible(child: _StatTile(label: '平均', value: vm.avgDb)),
                    const SizedBox(width: 8),
                    Flexible(child: _StatTile(label: '最大', value: vm.maxDb)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: ElevatedButton.icon(
                        onPressed: vm.isListening
                            ? null
                            : () => vm.requestPermissionAndStart(),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('开始'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: FilledButton.icon(
                        onPressed: vm.isListening ? () => vm.stop() : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 记录开关 + 导出/清空
                Consumer<HistoryProvider>(
                  builder: (_, hp, __) => Column(
                    children: [
                      SwitchListTile(
                        title: const Text('记录历史'),
                        value: hp.recording,
                        onChanged: (v) => hp.setRecording(v),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Flexible(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final messenger = ScaffoldMessenger.of(context);
                                // 导出最近200条为CSV，同时提供JSON示例（此处导出CSV）
                                final list = await hp.loadHistory(limit: 200);
                                if (list.isEmpty) {
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('无可导出的数据')),
                                  );
                                  return;
                                }
                                messenger.showSnackBar(
                                  const SnackBar(content: Text('正在导出，请稍候…')),
                                );
                                try {
                                  final path = await ExportService.exportCsv(list);
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('已导出到：$path')),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  messenger.showSnackBar(
                                    const SnackBar(content: Text('导出失败')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.ios_share),
                              label: const Text('导出'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                await hp.clearAll();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('已清空历史')),
                                );
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('清空'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Flexible(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // 简易校准示例
                          showDialog(
                            context: context,
                            builder: (ctx) {
                              double offset = vm.calibrationOffset;
                              return AlertDialog(
                                title: const Text('麦克风校准'),
                                content: StatefulBuilder(
                                  builder: (ctx, setState) => Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '当前偏移：${offset.toStringAsFixed(1)} dB',
                                      ),
                                      Slider(
                                        min: -20,
                                        max: 20,
                                        divisions: 80,
                                        value: offset,
                                        onChanged: (v) =>
                                            setState(() => offset = v),
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('取消'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      vm.setCalibrationOffset(offset);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('保存'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(Icons.tune),
                        label: const Text('校准'),
                      ),
                    ),
                  ],
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

class _StatTile extends StatelessWidget {
  final String label;
  final double? value;
  const _StatTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(label),
            const SizedBox(height: 4),
            Text(
              value?.toStringAsFixed(1) ?? '--',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
