// 录音列表页面：开始/停止录音、播放/删除、分享
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/recording_provider.dart';

class RecordingsScreen extends StatelessWidget {
  const RecordingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RecordingProvider>(
      builder: (_, vm, __) {
        return Scaffold(
          appBar: AppBar(title: const Text('录音与播放')),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: vm.isRecording ? null : () => vm.start(),
                        icon: const Icon(Icons.fiber_manual_record),
                        label: const Text('开始录音'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: vm.isRecording
                            ? () => vm.stopAndSave()
                            : null,
                        icon: const Icon(Icons.stop),
                        label: const Text('停止并保存'),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: vm.refresh,
                  child: ListView.builder(
                    itemCount: vm.items.length,
                    itemBuilder: (_, i) {
                      final it = vm.items[i];
                      return ListTile(
                        title: Text(it.path.split('/').last),
                        subtitle: Text(
                          '时长 ${(it.durationMs / 1000).toStringAsFixed(1)} s',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.play_arrow),
                              onPressed: () => vm.play(it.path),
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () => SharePlus.instance.share(
                                ShareParams(files: [XFile(it.path)]),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => vm.remove(it.id!),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
