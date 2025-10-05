// 设置页：主题/加权/响应/校准偏移/保存策略，持久化保存 + 无障碍语义
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/noise_provider.dart';
import '../../core/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NoiseProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        semanticChildCount: 4,
        padding: const EdgeInsets.all(16),
        children: [
          // 校准偏移
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '麦克风校准偏移（dB）',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  StatefulBuilder(
                    builder: (ctx, setState) => Column(
                      children: [
                        Text(vm.calibrationOffset.toStringAsFixed(1)),
                        Slider(
                          min: -20,
                          max: 20,
                          divisions: 80,
                          value: vm.calibrationOffset,
                          onChanged: (v) =>
                              setState(() => vm.setCalibrationOffset(v)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 加权/响应
          Card(
            semanticContainer: true,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('测量设置', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
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
                          onChanged: (v) async {
                            if (v != null) {
                              vm.setWeighting(v);
                              await SettingsService.saveWeighting(
                                _mapWeight(v),
                              );
                            }
                          },
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
                          onChanged: (v) async {
                            if (v != null) {
                              vm.setResponseSpeed(v);
                              await SettingsService.saveResponse(_mapResp(v));
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 主题模式 + 数据保存策略
          Card(
            semanticContainer: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('主题模式')),
                      FutureBuilder<int>(
                        future: SettingsService.readDarkMode(),
                        builder: (ctx, snap) {
                          final value = snap.data ?? 0;
                          return DropdownButton<int>(
                            value: value,
                            items: const [
                              DropdownMenuItem(value: 0, child: Text('跟随系统')),
                              DropdownMenuItem(value: 1, child: Text('浅色')),
                              DropdownMenuItem(value: 2, child: Text('深色')),
                            ],
                            onChanged: (v) async {
                              if (v == null) return;
                              await SettingsService.saveDarkMode(v);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(content: Text('主题将于下次重启后应用')),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  FutureBuilder<bool>(
                    future: SettingsService.readAutoSaveHistory(),
                    builder: (ctx, snap) {
                      final enabled = snap.data ?? true;
                      return SwitchListTile(
                        title: const Text('自动保存测量到历史'),
                        value: enabled,
                        onChanged: (v) async {
                          await SettingsService.saveAutoSaveHistory(v);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text(v ? '已开启自动保存' : '已关闭自动保存'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                  FutureBuilder<int>(
                    future: SettingsService.readRetentionDays(),
                    builder: (ctx, snap) {
                      final days = (snap.data ?? 30).clamp(0, 365);
                      return Row(
                        children: [
                          const Expanded(child: Text('历史保留天数')),
                          SizedBox(
                            width: 140,
                            child: SliderTheme(
                              data: const SliderThemeData(
                                showValueIndicator: ShowValueIndicator.onDrag,
                              ),
                              child: Slider(
                                min: 0,
                                max: 365,
                                divisions: 73,
                                value: days.toDouble(),
                                label: days == 0 ? '无限制' : '$days 天',
                                onChanged: (_) {},
                                onChangeEnd: (v) =>
                                    SettingsService.saveRetentionDays(
                                      v.round(),
                                    ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 下拉映射工具：Provider 枚举 <-> 存储字符串
  String _mapWeight(Weighting w) {
    switch (w) {
      case Weighting.a:
        return 'A';
      case Weighting.c:
        return 'C';
      case Weighting.z:
        return 'Z';
    }
  }

  String _mapResp(ResponseSpeed r) {
    switch (r) {
      case ResponseSpeed.fast:
        return 'fast';
      case ResponseSpeed.slow:
        return 'slow';
    }
  }
}
