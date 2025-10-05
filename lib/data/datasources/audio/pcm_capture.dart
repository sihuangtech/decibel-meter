// 数据源：原始 PCM 捕获
// 说明：移动端使用 flutter_audio_capture，桌面端使用原生实现
import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_capture/flutter_audio_capture.dart';
import 'package:decibel_meter/core/utils/platform_utils.dart';
import 'package:decibel_meter/core/errors/app_failure.dart';

// 桌面平台原生实现
import 'pcm_capture_macos.dart';
import 'pcm_capture_linux.dart';
import 'pcm_capture_windows.dart';

/// PCM 捕获配置
class PcmCaptureConfig {
  final int sampleRate; // 采样率，建议 44100/48000
  final int bufferSize; // 每次回调的样本数（每通道）
  final int channels; // 声道数（1/2）
  const PcmCaptureConfig({
    this.sampleRate = 44100,
    this.bufferSize = 2048,
    this.channels = 1,
  });
}

/// 统一的 PCM 捕获数据源接口：便于跨平台注入
abstract class PcmCaptureSource {
  /// PCM 单声道流（Float32List）
  Stream<Float32List> get pcmStream;

  /// 启动采集
  Future<void> start();

  /// 停止采集
  Future<void> stop();

  /// 释放资源
  Future<void> dispose();
}

/// PCM 捕获数据源工厂：根据平台返回合适的实现
class PcmCaptureDataSource implements PcmCaptureSource {
  final PcmCaptureConfig config;
  late final PcmCaptureSource _impl;

  PcmCaptureDataSource({this.config = const PcmCaptureConfig()}) {
    // 根据平台选择合适的实现
    if (PlatformUtils.isMobile) {
      _impl = _PcmCaptureMobileDataSource(config: config);
    } else if (Platform.isMacOS) {
      _impl = PcmCaptureMacOSDataSource();
    } else if (Platform.isLinux) {
      _impl = PcmCaptureLinuxDataSource();
    } else if (Platform.isWindows) {
      _impl = PcmCaptureWindowsDataSource();
    } else {
      throw AppFailure.platformNotSupported('Unknown platform');
    }
  }

  @override
  Stream<Float32List> get pcmStream => _impl.pcmStream;

  @override
  Future<void> start() => _impl.start();

  @override
  Future<void> stop() => _impl.stop();

  @override
  Future<void> dispose() => _impl.dispose();
}

/// PCM 捕获数据源（移动端实现）：输出 Float32List（单声道）样本流
class _PcmCaptureMobileDataSource implements PcmCaptureSource {
  final PcmCaptureConfig config;
  final _controller = StreamController<Float32List>.broadcast();
  final FlutterAudioCapture _audioCapture = FlutterAudioCapture();
  bool _running = false;

  @override
  Stream<Float32List> get pcmStream => _controller.stream;

  _PcmCaptureMobileDataSource({required this.config});

  @override
  Future<void> start() async {
    if (_running) return;
    if (!PlatformUtils.isMobile) {
      _controller.addError(AppFailure.platformNotSupported('Desktop'));
      return;
    }
    try {
      // 回调：从原始字节转为 Float32List（注意平台端一般以32位浮点输出）
      Future<void> onAudioData(dynamic obj) async {
        try {
          if (obj is! Uint8List) return;
          final byteData = ByteData.view(obj.buffer);
          final len = byteData.lengthInBytes ~/ 4;
          final floats = Float32List(len);
          for (int i = 0; i < len; i++) {
            floats[i] = byteData.getFloat32(i * 4, Endian.little);
          }
          // 若是双声道，可在此做 downmix：L/R 平均
          if (config.channels == 2) {
            final mono = Float32List(len ~/ 2);
            for (int i = 0, j = 0; j < mono.length; i += 2, j++) {
              mono[j] = (floats[i] + floats[i + 1]) * 0.5;
            }
            _controller.add(mono);
          } else {
            _controller.add(floats);
          }
        } catch (e, st) {
          debugPrint('PCM convert error: $e');
          _controller.addError(AppFailure.unexpected(e, st));
        }
      }

      Future<void> onError(Object e) async {
        _controller.addError(AppFailure.unexpected(e));
      }

      await _audioCapture.start(
        onAudioData,
        onError,
        sampleRate: config.sampleRate,
        bufferSize: config.bufferSize,
      );
      _running = true;
    } on PlatformException catch (e, st) {
      _controller.addError(AppFailure.unexpected(e, st));
    }
  }

  @override
  Future<void> stop() async {
    if (!_running) return;
    try {
      await _audioCapture.stop();
    } catch (_) {}
    _running = false;
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }
}
