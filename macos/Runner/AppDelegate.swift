import Cocoa
import FlutterMacOS
import AVFoundation

@main
class AppDelegate: FlutterAppDelegate {
  private var eventChannel: FlutterEventChannel?
  private var methodChannel: FlutterMethodChannel?
  private let streamHandler = MacAudioStreamHandler()

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {
    super.applicationDidFinishLaunching(notification)

    guard
      let controller = mainFlutterWindow?.contentViewController as? FlutterViewController
    else { return }

    let messenger = controller.engine.binaryMessenger

    // 事件通道：连续推送 Float32 PCM
    eventChannel = FlutterEventChannel(name: "audio_capture_stream", binaryMessenger: messenger)
    eventChannel?.setStreamHandler(streamHandler)

    // 方法通道：控制 start/stop
    methodChannel = FlutterMethodChannel(name: "audio_capture_ctrl", binaryMessenger: messenger)
    methodChannel?.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        let args = call.arguments as? [String: Any]
        let sampleRate = (args?["sampleRate"] as? NSNumber)?.doubleValue ?? 44100.0
        let bufferSize = (args?["bufferSize"] as? NSNumber)?.intValue ?? 1024
        self.streamHandler.start(sampleRate: sampleRate, bufferSize: bufferSize) { ok, err in
          if let err = err {
            result(FlutterError(code: "start_failed", message: err.localizedDescription, details: nil))
          } else {
            result(ok)
          }
        }
      case "stop":
        self.streamHandler.stop()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

// 处理 AVAudioEngine 采集、推流
class MacAudioStreamHandler: NSObject, FlutterStreamHandler {
  private let engine = AVAudioEngine()
  private var sink: FlutterEventSink?
  private var running = false
  private var desiredSampleRate: Double = 44100.0
  private var desiredBufferSize: AVAudioFrameCount = 1024

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    sink = events
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    sink = nil
    return nil
  }

  func start(sampleRate: Double, bufferSize: Int, completion: @escaping (Bool, Error?) -> Void) {
    if running {
      completion(true, nil)
      return
    }
    desiredSampleRate = sampleRate
    desiredBufferSize = AVAudioFrameCount(bufferSize)

    do {
      // 请求麦克风权限
      var granted = false
      let sem = DispatchSemaphore(value: 0)
      AVCaptureDevice.requestAccess(for: .audio) { ok in
        granted = ok
        sem.signal()
      }
      _ = sem.wait(timeout: .now() + 2.0)
      if !granted {
        completion(false, NSError(domain: "AudioCapture", code: 1, userInfo: [NSLocalizedDescriptionKey: "麦克风权限被拒绝"]))
        return
      }

      let input = engine.inputNode
      let inputFormat = input.outputFormat(forBus: 0)

      // 目标格式：单声道 Float32，指定采样率
      let targetFormat = AVAudioFormat(commonFormat: .pcmFormatFloat32,
                                       sampleRate: desiredSampleRate,
                                       channels: 1,
                                       interleaved: false)!

      // 在输入节点上安装 tap
      input.removeTap(onBus: 0)
      input.installTap(onBus: 0, bufferSize: desiredBufferSize, format: inputFormat) { [weak self] buffer, _ in
        guard let self = self else { return }
        self.processBuffer(buffer: buffer, targetFormat: targetFormat)
      }

      // 配置并启动引擎
      engine.prepare()
      try engine.start()
      running = true
      completion(true, nil)
    } catch {
      completion(false, error)
    }
  }

  func stop() {
    if running {
      engine.inputNode.removeTap(onBus: 0)
      engine.stop()
      running = false
    }
  }

  private func processBuffer(buffer: AVAudioPCMBuffer, targetFormat: AVAudioFormat) {
    guard let sink = sink else { return }

    // 变换格式为目标采样率/单声道/Float32
    let converter = AVAudioConverter(from: buffer.format, to: targetFormat)
    let outCapacity = AVAudioFrameCount(targetFormat.sampleRate / 100) // ~10ms
    guard let outBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outCapacity) else { return }

    var error: NSError?
    converter?.convert(to: outBuffer, error: &error, withInputFrom: { inNumPackets, outStatus in
      outStatus.pointee = .haveData
      return buffer
    })

    if let error = error {
      sink(FlutterError(code: "convert_failed", message: error.localizedDescription, details: nil))
      return
    }

    let frames = Int(outBuffer.frameLength)
    guard frames > 0, let channelData = outBuffer.floatChannelData else { return }

    // 仅取第 0 声道
    let ptr = channelData[0]
    let data = Data(bytes: ptr, count: frames * MemoryLayout<Float>.size)

    // 通过标准消息编码发送 Float32List
    let typed = FlutterStandardTypedData(float32: data)
    sink(typed)
  }
}