#pragma once
// Windows 音频采集（WASAPI）：注册 Flutter 通道 + 采集默认麦克风 PCM(Float32)
// 避免在头文件中包含 Flutter 头，改用前置声明，降低编辑器索引报错概率
namespace flutter { class BinaryMessenger; }

// 传入 BinaryMessenger 注册 EventChannel/MethodChannel
void RegisterAudioCapture(flutter::BinaryMessenger* messenger);