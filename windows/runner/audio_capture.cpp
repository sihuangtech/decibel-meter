#include "audio_capture.h"
#include <flutter/event_channel.h>
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>
#include <flutter/encodable_value.h>

#include <mmdeviceapi.h>
#include <audioclient.h>
#include <avrt.h>
#include <wrl/client.h>
#include <atomic>
#include <thread>
#include <vector>
#include <functional>
#include <cstdint>

using Microsoft::WRL::ComPtr;

namespace {
class WasapiCapture {
 public:
  WasapiCapture() = default;
  ~WasapiCapture() { Stop(); }

  bool Start(int sample_rate, int buffer_size) {
    if (running_) return true;
    sample_rate_ = sample_rate;
    buffer_size_ = buffer_size;
    running_ = true;
    worker_ = std::thread([this]() { this->Run(); });
    return true;
  }

  void Stop() {
    if (!running_) return;
    running_ = false;
    if (worker_.joinable()) worker_.join();
    if (audio_client_) audio_client_->Stop();
    capture_client_.Reset();
    audio_client_.Reset();
    device_.Reset();
  }

  void SetSink(std::function<void(const float*, size_t)> sink) { sink_ = std::move(sink); }

 private:
  void Run() {
    // 初始化 COM 在线程内
    CoInitializeEx(nullptr, COINIT_MULTITHREADED);

    // 设备枚举
    ComPtr<IMMDeviceEnumerator> enumerator;
    if (FAILED(CoCreateInstance(__uuidof(MMDeviceEnumerator), nullptr, CLSCTX_ALL,
                                IID_PPV_ARGS(&enumerator)))) {
      running_ = false;
      CoUninitialize();
      return;
    }
    if (FAILED(enumerator->GetDefaultAudioEndpoint(eCapture, eCommunications, &device_))) {
      // 退回到 eMultimedia
      if (FAILED(enumerator->GetDefaultAudioEndpoint(eCapture, eMultimedia, &device_))) {
        running_ = false;
        CoUninitialize();
        return;
      }
    }

    // 激活 IAudioClient
    if (FAILED(device_->Activate(__uuidof(IAudioClient), CLSCTX_ALL, nullptr,
                                 &audio_client_))) {
      running_ = false;
      CoUninitialize();
      return;
    }

    // 期望格式：Float32/单声道
    WAVEFORMATEX* mix = nullptr;
    if (FAILED(audio_client_->GetMixFormat(&mix))) {
      running_ = false;
      CoUninitialize();
      return;
    }

    // 尝试配置为单声道/Float32/指定采样率（必要时让系统转换）
    WAVEFORMATEX desire = {};
    desire.wFormatTag = WAVE_FORMAT_IEEE_FLOAT;
    desire.nChannels = 1;
    desire.nSamplesPerSec = sample_rate_;
    desire.wBitsPerSample = 32;
    desire.nBlockAlign = (desire.nChannels * desire.wBitsPerSample) / 8;
    desire.nAvgBytesPerSec = desire.nSamplesPerSec * desire.nBlockAlign;

    REFERENCE_TIME hnsBuffer = 20 * 10000; // 20ms
    if (FAILED(audio_client_->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                         AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                                         hnsBuffer, 0, &desire, nullptr))) {
      // 回退到混音格式
      if (FAILED(audio_client_->Initialize(AUDCLNT_SHAREMODE_SHARED,
                                           AUDCLNT_STREAMFLAGS_EVENTCALLBACK,
                                           hnsBuffer, 0, mix, nullptr))) {
        CoTaskMemFree(mix);
        running_ = false;
        CoUninitialize();
        return;
      }
    }
    CoTaskMemFree(mix);

    if (FAILED(audio_client_->GetService(IID_PPV_ARGS(&capture_client_)))) {
      running_ = false;
      CoUninitialize();
      return;
    }

    // 事件通知
    HANDLE event_handle = CreateEvent(nullptr, FALSE, FALSE, nullptr);
    audio_client_->SetEventHandle(event_handle);

    // 启动
    if (FAILED(audio_client_->Start())) {
      CloseHandle(event_handle);
      running_ = false;
      CoUninitialize();
      return;
    }

    // 优先级提升
    DWORD task_index = 0;
    HANDLE hTask = AvSetMmThreadCharacteristics(L"Pro Audio", &task_index);

    std::vector<float> ring;
    ring.reserve(static_cast<size_t>(buffer_size_));

    while (running_) {
      DWORD wait = WaitForSingleObject(event_handle, 1000);
      if (wait != WAIT_OBJECT_0) continue;

      UINT32 packet = 0;
      if (FAILED(capture_client_->GetNextPacketSize(&packet))) continue;

      while (packet && running_) {
        BYTE* data = nullptr;
        UINT32 frames = 0;
        DWORD flags = 0;
        WAVEFORMATEX* fmt = nullptr;

        if (FAILED(capture_client_->GetBuffer(&data, &frames, &flags, nullptr, nullptr))) break;

        // 将缓冲转换/下混为单声道 Float32
        const float* in = reinterpret_cast<const float*>(data);
        size_t channels = 1; // 共享模式下通常与 mix 格式一致，但此处按 Float32 单声道处理
        size_t count = frames; // 单声道帧数即样本数

        // 累积到 ring 并按 buffer_size_ 分包下发
        for (size_t i = 0; i < count; ++i) {
          float v = in[i * channels];
          ring.push_back(v);
          if (ring.size() >= static_cast<size_t>(buffer_size_)) {
            if (sink_) sink_(ring.data(), ring.size());
            ring.clear();
          }
        }

        capture_client_->ReleaseBuffer(frames);
        if (FAILED(capture_client_->GetNextPacketSize(&packet))) break;
      }
    }

    if (hTask) AvRevertMmThreadCharacteristics(hTask);
    audio_client_->Stop();
    CloseHandle(event_handle);
    CoUninitialize();
  }

  std::function<void(const float*, size_t)> sink_;
  std::atomic<bool> running_{false};
  int sample_rate_{44100};
  int buffer_size_{1024};
  std::thread worker_;
  ComPtr<IMMDevice> device_;
  ComPtr<IAudioClient> audio_client_;
  ComPtr<IAudioCaptureClient> capture_client_;
};

class StreamHandler : public flutter::StreamHandler<flutter::EncodableValue> {
 public:
  explicit StreamHandler(WasapiCapture* cap) : cap_(cap) {}
 protected:
  // 保存 sink
  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnListenInternal(
      const flutter::EncodableValue*, std::unique_ptr<flutter::EventSink<flutter::EncodableValue>>&& sink) override {
    sink_ = std::move(sink);
    cap_->SetSink([this](const float* data, size_t n) {
      if (!sink_) return;
      auto bytes = reinterpret_cast<const uint8_t*>(data);
      std::vector<uint8_t> buf(bytes, bytes + n * sizeof(float));
      // 按标准字节数组下发（对应 Dart 侧的 Uint8List）
      sink_->Success(flutter::EncodableValue(std::move(buf)));
    });
    return nullptr;
  }

  std::unique_ptr<flutter::StreamHandlerError<flutter::EncodableValue>> OnCancelInternal(
      const flutter::EncodableValue*) override {
    sink_.reset();
    return nullptr;
  }

 private:
  WasapiCapture* cap_;
  std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> sink_;
};
}  // namespace

void RegisterAudioCapture(flutter::BinaryMessenger* messenger) {
  static WasapiCapture capture;

  // EventChannel：推送 PCM
  auto event_channel = std::make_unique<flutter::EventChannel<flutter::EncodableValue>>(
      messenger, "audio_capture_stream", &flutter::StandardMethodCodec::GetInstance());
  event_channel->SetStreamHandler(std::make_unique<StreamHandler>(&capture));

  // MethodChannel：控制 start/stop
  auto method_channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      messenger, "audio_capture_ctrl", &flutter::StandardMethodCodec::GetInstance());
  method_channel->SetMethodCallHandler([&capture](const auto& call, auto result) {
    const auto& method = call.method_name();
    if (method == "start") {
      int sample_rate = 44100;
      int buffer_size = 1024;
      if (auto args = std::get_if<flutter::EncodableMap>(call.arguments())) {
        if (auto it = args->find(flutter::EncodableValue("sampleRate")); it != args->end()) {
          sample_rate = std::get<int>(it->second);
        }
        if (auto it = args->find(flutter::EncodableValue("bufferSize")); it != args->end()) {
          buffer_size = std::get<int>(it->second);
        }
      }
      capture.Start(sample_rate, buffer_size);
      result->Success(flutter::EncodableValue(true));
    } else if (method == "stop") {
      capture.Stop();
      result->Success(flutter::EncodableValue(true));
    } else {
      result->NotImplemented();
    }
  });
}