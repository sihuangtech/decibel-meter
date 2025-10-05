[中文文档（Chinese Version）](./README_zh-CN.md)

Decibel Meter (Flutter) — Cross‑platform SPL analyzer

Overview
Decibel Meter is a cross‑platform Flutter application (Android, iOS, macOS, Windows, Linux) for real‑time sound pressure level (SPL) measurements, visualization, and data management.

Key Features
- Real-time SPL (approx. 20–160 dB), modes: dBA/dBC/dBZ, fast/slow response, calibration offset
- Visualization: waveform, spectrum (FFT), SPL bar, history charts
- Data management: measurement logs (SQLite), CSV/JSON export, audio recording & playback, sharing
- Dose meter: OSHA/NIOSH exposure estimation and warnings
- Settings: weighting/response, calibration, theme, autosave, retention days
- Accessibility and responsive UI for multiple form factors
- Data security: encrypted SQLite (SQLCipher) + secure key storage


Project Structure
lib/
  main.dart
  core/
  data/
    datasources/
      audio/ (PCM capture for mobile/macOS + desktop channels)
      local/ (AppDatabase with SQLCipher)
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
    widgets/ (waveform, spectrum, SPL gauge)
    theme/
  config/

Dependencies (pub)
- Audio: noise_meter, flutter_audio_capture, record
- State: provider
- Persistence: sqflite_sqlcipher, shared_preferences, flutter_secure_storage, path_provider, path
- Charts/UI: fl_chart, syncfusion_flutter_charts, google_fonts, flutter_svg
- Utils: intl, uuid

Install
- Ensure Flutter SDK installed (3.22+ recommended)
- Fetch packages:
  flutter pub get
- If starting from scratch:
  flutter pub add noise_meter permission_handler provider shared_preferences sqflite_sqlcipher path_provider fl_chart syncfusion_flutter_charts record path google_fonts flutter_svg intl uuid flutter_secure_storage

Platform Permissions
- Android: RECORD_AUDIO, WRITE_EXTERNAL_STORAGE (if needed for export/recordings)
- iOS/macOS: NSMicrophoneUsageDescription (Info.plist)
- macOS: com.apple.security.device.audio-input (entitlements)
- Windows/Linux: microphone access via OS; build links native audio backends

Build & Run
- Android: flutter run -d android
- iOS: flutter run -d ios (Xcode setup required)
- macOS: flutter run -d macos
- Windows: flutter run -d windows
- Linux:
  - Install dev libs: sudo apt-get install -y libpulse-dev
  - Run: flutter run -d linux

Notes for Desktop Native Audio
- macOS: Uses AVAudioEngine via channels audio_capture_ctrl/audio_capture_stream
- Windows: Uses WASAPI (shared mode) in runner; CMake links mmdevapi, audioclient, avrt, ole32
- Linux: Uses PulseAudio simple API; CMake links pulse, pulse-simple
- The Dart side reuses a single channel-based PCM data source for macOS/Windows/Linux

Security & Privacy
- Database: SQLCipher via sqflite_sqlcipher
- Key management: flutter_secure_storage
- Do not log secrets, avoid exporting sensitive data without user consent

Testing & Quality
- Flutter analyze should be clean
- Add unit/widget/integration tests for providers, services, and critical flows
- Performance: verify UI smoothness under continuous audio capture

Roadmap
- Real ML-based noise classification (TFLite/on-device)
- Desktop enhancements (device selection, buffer tuning)
- Advanced visualization styles and accessibility audits
- Automated tests and CI
- Data migration from unencrypted DB (if upgrading)

License
This project is licensed under the Apache License 2.0. See the LICENSE file for details.

Contributing
PRs are welcome. Please follow Flutter style and project conventions.

Contact
Create an issue for bugs/requests.