// 参考信息页：常见噪声等级与健康提示（静态示例，可扩展为富内容）
import 'package:flutter/material.dart';

class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = <Map<String, String>>[
      {'name': '图书馆', 'db': '30-40 dB', 'tip': '对听力几乎无风险，长期可接受。'},
      {'name': '正常交谈', 'db': '60-65 dB', 'tip': '一般不会造成听力损伤。'},
      {'name': '街道噪声', 'db': '70-85 dB', 'tip': '持续暴露应注意时间，避免超过建议时长。'},
      {'name': '地铁/交通', 'db': '85-95 dB', 'tip': '长时间处于该环境建议佩戴耳塞。'},
      {'name': '音乐会', 'db': '95-110 dB', 'tip': '短时间可接受，建议佩戴听力防护。'},
      {'name': '机械噪声', 'db': '100-120 dB', 'tip': '建议佩戴防护，严格控制暴露时间。'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('参考信息')),
      body: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            title: Text(it['name']!),
            subtitle: Text('${it['db']}｜${it['tip']}'),
            leading: const Icon(Icons.info_outline),
          );
        },
      ),
    );
  }
}