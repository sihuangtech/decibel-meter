// SPL 柱状指示（增强版）：动态标尺、颜色分区、无障碍语义
import 'package:flutter/material.dart';

class SplGauge extends StatelessWidget {
  final double? db;
  const SplGauge({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    final v = (db ?? 0).clamp(0, 120);
    final ratio = v / 120.0;

    Color color;
    if (ratio >= 0.83) {
      color = Theme.of(context).colorScheme.error;
    } else if (ratio >= 0.66) {
      color = Colors.orange;
    } else {
      color = Theme.of(context).colorScheme.primary;
    }

    return LayoutBuilder(
      builder: (ctx, c) {
        final h = ((c.maxHeight.isFinite ? c.maxHeight : 160.0).clamp(
          120.0,
          240.0,
        )).toDouble();
        return Semantics(
          label: '瞬时声压级',
          value: '${v.toStringAsFixed(1)} 分贝',
          increasedValue: '高于 ${(ratio * 100).toStringAsFixed(0)}% 刻度',
          child: SizedBox(
            height: h,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // 背景刻度
                Positioned.fill(child: CustomPaint(painter: _ScalePainter())),
                // 柱状
                Container(
                  width: 28,
                  height: h - 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).dividerColor),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      curve: Curves.easeOut,
                      width: double.infinity,
                      height: (h - 20) * ratio,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ),
                // 顶部读数
                Positioned(
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${v.toStringAsFixed(1)} dB',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ScalePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;

    // 0-120 dB 每 10 dB 刻度
    final total = 120;
    final usableH = size.height - 20;
    for (int i = 0; i <= total; i += 10) {
      final y = usableH * (1 - i / total) + 20;
      final len = (i % 20 == 0) ? 10.0 : 6.0;
      canvas.drawLine(
        Offset(size.width / 2 - len, y),
        Offset(size.width / 2 + len, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
