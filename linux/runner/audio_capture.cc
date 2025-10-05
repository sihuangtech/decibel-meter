// Linux 音频采集（PulseAudio）：注册 EventChannel/MethodChannel 并推送 Float32 PCM
#include <flutter_linux/flutter_linux.h>
#include <pulse/simple.h>
#include <pulse/error.h>
#include <atomic>
#include <thread>
#include <vector>
#include <cstdint>

static std::atomic<bool> g_running{false};
static std::thread g_worker;

static void start_capture(FlBinaryMessenger* messenger, int sample_rate, int buffer_size) {
  if (g_running) return;
  g_running = true;

  // EventChannel: audio_capture_stream
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlEventChannel) event_channel = fl_event_channel_new(messenger, "audio_capture_stream", FL_METHOD_CODEC(codec));
  static FlEventSink* sink = nullptr;
  fl_event_channel_set_stream_handlers(
      event_channel,
      [](FlEventChannel*, FlValue*, gpointer, GError**) -> FlEventStreamHandlerFunctions {
        return {
          // on_listen
          [](FlValue*, FlEventSink* s, gpointer) -> gboolean { sink = s; return TRUE; },
          // on_cancel
          [](FlValue*, gpointer) -> gboolean { sink = nullptr; return TRUE; },
          nullptr
        };
      },
      nullptr, nullptr);

  // MethodChannel: audio_capture_ctrl
  g_autoptr(FlMethodChannel) method_channel = fl_method_channel_new(messenger, "audio_capture_ctrl", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(method_channel, [](FlMethodChannel*, FlMethodCall* call, gpointer) {
    const gchar* method = fl_method_call_get_name(call);
    if (g_strcmp0(method, "stop") == 0) {
      g_running = false;
      g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
      fl_method_call_respond_success(call, result, nullptr);
      return;
    }
    if (g_strcmp0(method, "start") == 0) {
      // 已在外部启动线程，直接返回
      g_autoptr(FlValue) result = fl_value_new_bool(TRUE);
      fl_method_call_respond_success(call, result, nullptr);
      return;
    }
    fl_method_call_respond_not_implemented(call, nullptr);
  }, nullptr, nullptr);

  // 采集线程
  g_worker = std::thread([sample_rate, buffer_size]() {
    pa_sample_spec ss;
    ss.format = PA_SAMPLE_FLOAT32LE;
    ss.rate = sample_rate;
    ss.channels = 1;

    int error = 0;
    pa_simple* s = pa_simple_new(nullptr, "decibel_meter", PA_STREAM_RECORD, nullptr, "record", &ss, nullptr, nullptr, &error);
    if (!s) {
      g_running = false;
      return;
    }

    std::vector<float> buf(buffer_size);
    while (g_running) {
      if (pa_simple_read(s, buf.data(), buf.size() * sizeof(float), &error) < 0) {
        break;
      }
      if (sink) {
        // 将 float 数组作为二进制传递，由 Dart 侧转换为 Float32List
        GBytes* bytes = g_bytes_new(buf.data(), buf.size() * sizeof(float));
        g_autoptr(FlValue) data = fl_value_new_uint8_list_from_bytes(bytes);
        FlValue* event = fl_value_new_map();
        // 直接下发二进制
        fl_event_sink_success(sink, data, nullptr);
        g_bytes_unref(bytes);
      }
    }

    pa_simple_free(s);
  });
}

extern "C" void RegisterAudioCaptureLinux(FlBinaryMessenger* messenger, int sample_rate, int buffer_size) {
  start_capture(messenger, sample_rate, buffer_size);
}

extern "C" void StopAudioCaptureLinux() {
  g_running = false;
  if (g_worker.joinable()) g_worker.join();
}