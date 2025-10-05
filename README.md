# Decibel Meter (Flutter) — Cross‑platform SPL analyzer

[中文文档（Chinese Version）](./README_zh-CN.md)

## Overview

Decibel Meter is a cross‑platform Flutter application (Android, iOS, macOS, Windows, Linux) for real‑time sound pressure level (SPL) measurements, visualization, and data management.

## Key Features

- **Real-time SPL Measurement**: Approx. 20–160 dB range with dBA/dBC/dBZ modes, fast/slow response, and calibration offset
- **Rich Visualization**: Real-time waveform, spectrum (FFT), SPL bar, and history charts
- **Data Management**: Measurement logs (SQLite), CSV/JSON export, audio recording & playback, sharing capabilities
- **Dose Meter**: OSHA/NIOSH exposure estimation and warnings
- **Flexible Settings**: Weighting/response options, calibration, theme selection, autosave, retention days
- **Accessibility**: Responsive UI for multiple form factors
- **Data Security**: Encrypted SQLite (SQLCipher) + secure key storage


## Project Structure

```
lib/
├── main.dart
├── core/
├── data/
│   ├── datasources/
│   │   ├── audio/          # PCM capture for mobile/macOS + desktop channels
│   │   └── local/          # AppDatabase with SQLCipher
│   ├── models/
│   ├── repositories/
│   └── services/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    ├── widgets/            # waveform, spectrum, SPL gauge
    └── theme/
```

## Dependencies

### Audio
- `noise_meter`
- `flutter_audio_capture`
- `record`

### State Management
- `provider`

### Persistence
- `sqflite_sqlcipher`
- `shared_preferences`
- `flutter_secure_storage`
- `path_provider`
- `path`

### Charts & UI
- `fl_chart`
- `syncfusion_flutter_charts`
- `google_fonts`
- `flutter_svg`

### Utilities
- `intl`
- `uuid`

## Installation

### Prerequisites
- Flutter SDK (3.22+ recommended)

### Setup
```bash
# Fetch packages
flutter pub get

# If starting from scratch
flutter pub add noise_meter permission_handler provider shared_preferences sqflite_sqlcipher path_provider fl_chart syncfusion_flutter_charts record path google_fonts flutter_svg intl uuid flutter_secure_storage
```

## Platform Permissions

### Android
- `RECORD_AUDIO`
- `WRITE_EXTERNAL_STORAGE` (if needed for export/recordings)

### iOS/macOS
- `NSMicrophoneUsageDescription` (Info.plist)

### macOS
- `com.apple.security.device.audio-input` (entitlements)

### Windows/Linux
- Microphone access via OS; build links native audio backends

## Build & Run

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios  # Xcode setup required
```

### macOS
```bash
flutter run -d macos
```

### Windows
```bash
flutter run -d windows
```

### Linux
```bash
# Install dev libs
sudo apt-get install -y libpulse-dev

# Run
flutter run -d linux
```

## Desktop Native Audio Implementation

### macOS
- Uses AVAudioEngine via channels `audio_capture_ctrl`/`audio_capture_stream`

### Windows
- Uses WASAPI (shared mode) in runner
- CMake links: `mmdevapi`, `audioclient`, `avrt`, `ole32`

### Linux
- Uses PulseAudio simple API
- CMake links: `pulse`, `pulse-simple`

### Unified Dart Interface
- The Dart side reuses a single channel-based PCM data source for macOS/Windows/Linux

## Security & Privacy

### Database Security
- SQLCipher via `sqflite_sqlcipher`

### Key Management
- `flutter_secure_storage` for secure key storage

### Best Practices
- Do not log secrets
- Avoid exporting sensitive data without user consent

## Testing & Quality

### Code Quality
- `flutter analyze` should be clean

### Testing Strategy
- Add unit/widget/integration tests for providers, services, and critical flows

### Performance
- Verify UI smoothness under continuous audio capture

## Roadmap

- [ ] Real ML-based noise classification (TFLite/on-device)
- [ ] Desktop enhancements (device selection, buffer tuning)
- [ ] Advanced visualization styles and accessibility audits
- [ ] Automated tests and CI
- [ ] Data migration from unencrypted DB (if upgrading)

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for details.

## Contributing

PRs are welcome. Please follow Flutter style and project conventions.

## Contact

Create an issue for bugs/requests.