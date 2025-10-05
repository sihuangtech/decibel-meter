[English Version (英文文档)](./README.md)

分贝测量仪（Flutter）— 跨平台声压级分析

简介
分贝测量仪（decibel_meter）是一款基于 Flutter 的跨平台应用（Android、iOS、macOS、Windows、Linux），用于实时分贝（SPL）测量、可视化与数据管理。

核心功能
- 实时分贝测量：约 20–160 dB，支持 dBA/dBC/dBZ，加权与响应（快速/慢速），麦克风校准偏移
- 可视化：实时波形、频谱（FFT）、SPL 柱状条、历史曲线
- 数据管理：测量记录（SQLite）、CSV/JSON 导出、录音与播放、分享
- 剂量计：OSHA/NIOSH 听力负荷评估与预警
- 设置中心：加权/响应、校准、主题模式、自动保存、历史保留天数
- 无障碍与响应式：适配多终端（移动/桌面）
- 数据安全：SQLCipher 加密数据库 + 安全密钥存储


项目结构（节选）
lib/
  main.dart
  core/
  data/
    datasources/
      audio/            # 各平台 PCM 捕获/桥接
      local/            # 加密数据库
    models/
    repositories/
    services/
  domain/
    entities/
    repositories/
    usecases/
  presentation/
    providers/
    screens/
    widgets/           # 波形/频谱/SPL 组件
    theme/
  config/

依赖（通过命令行添加）
flutter pub add noise_meter permission_handler
flutter pub add provider
flutter pub add sqflite_sqlcipher shared_preferences flutter_secure_storage path_provider path
flutter pub add fl_chart syncfusion_flutter_charts
flutter pub add record
flutter pub add google_fonts flutter_svg
flutter pub add intl uuid

平台权限与配置
- Android：RECORD_AUDIO，必要时外部存储写权限
- iOS/macOS：Info.plist 添加 NSMicrophoneUsageDescription
- macOS：entitlements 启用 com.apple.security.device.audio-input
- Windows/Linux：原生工程内接入麦克风（WASAPI/PulseAudio）

运行与构建
- 获取依赖：flutter pub get
- Android：flutter run -d android
- iOS：flutter run -d ios（需 Xcode 配置）
- macOS：flutter run -d macos（首次允许麦克风）
- Windows：flutter run -d windows
- Linux：
  - 安装依赖：sudo apt-get update && sudo apt-get install -y libpulse-dev
  - 运行：flutter run -d linux

重要说明（桌面原生音频）
- 通道命名统一：
  - 方法通道：audio_capture_ctrl（start/stop，接受 sampleRate/bufferSize）
  - 事件通道：audio_capture_stream（持续发送 PCM 浮点数据）
- Dart 侧数据源统一复用通道实现（macOS/Windows/Linux 使用相同的 Dart 封装），AnalyzerProvider 读取 Stream<Float32List> 即可。
- 若本机编辑器对 C/C++ 报“找不到头文件”，通常是本地索引未带上 CMake 的 include/link 参数（假阳性）。请以 flutter run/build 的实际输出为准；如构建失败，请把日志贴给我们定位修复（可能需要补充系统开发库或调整 CMake）。

数据安全与隐私
- 数据库：采用 sqflite_sqlcipher，加密文件 decibel_meter_enc.db
- 密钥：首次启动随机生成并保存在 flutter_secure_storage
- 不记录隐私数据与密钥；导出/分享需用户主动触发

测试与质量
- flutter analyze 保持 0 问题
- 建议补充单元/Widget/集成测试（Provider、Service、数据导出等）
- 性能优化：保持 UI 绘制流畅；音频捕获线程与主线程隔离

路线图
- 噪音分类 AI：接入 TFLite 或端侧推理
- 桌面音频增强：设备选择、缓冲优化
- 可视化样式与无障碍细化
- 自动化测试与 CI
- 未加密数据库迁移策略

常见问题
1) 桌面构建头文件错误？
   多为编辑器索引假阳性。请以 flutter run/build 输出为准；Linux 需安装 libpulse-dev。

2) 频谱/波形无变化？
   确认已授予麦克风权限；在桌面端检查系统输入设备与音量。

3) 导出路径与分享失败？
   确认写入权限；在 iOS 需使用系统分享面板，在 Android 12+ 适配存储策略。

贡献与开源
- 欢迎 PR，遵循 Flutter 官方风格与项目现有约定
- 许可证：本项目采用 Apache License 2.0，详见 LICENSE

联系
- 如需问题反馈或功能请求，请提交 Issue。