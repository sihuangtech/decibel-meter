// Windows 原始 PCM 捕获数据源：使用原生音频采集
// 说明：使用原生方法通道和事件通道进行音频采集
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'pcm_capture.dart';

class PcmCaptureWindowsDataSource implements PcmCaptureSource {
  static const _event = EventChannel('audio_capture_stream');
  static const _method = MethodChannel('audio_capture_ctrl');

  final _controller = StreamController<Float32List>.broadcast();
  StreamSubscription? _sub;
  bool _running = false;

  @override
  Stream<Float32List> get pcmStream => _controller.stream;

  @override
  Future<void> start() async {
    const sampleRate = 44100;
    const bufferSize = 1024;
    if (_running) return;
    try {
      _sub = _event.receiveBroadcastStream().listen(
        (event) {
          if (event is Float32List) {
            _controller.add(event);
          } else if (event is Uint8List) {
            final bd = ByteData.sublistView(event);
            _controller.add(bd.buffer.asFloat32List());
          } else {
            // 忽略未知类型
          }
        },
        onError: (e, st) {
          if (!_controller.isClosed) {
            _controller.addError(e, st);
          }
        },
      );
      await _method.invokeMethod('start', {
        'sampleRate': sampleRate,
        'bufferSize': bufferSize,
      });
      _running = true;
    } on PlatformException catch (e, st) {
      _controller.addError(e, st);
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    try {
      await _method.invokeMethod('stop');
    } catch (_) {}
    await _sub?.cancel();
    _sub = null;
    _running = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}