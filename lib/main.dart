// 应用入口：注册 Provider，加载主题与首页
// 说明：此为最小可运行骨架，已接入权限申请与实时分贝显示（移动端）
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' show Platform;

import 'presentation/theme/app_theme.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/providers/noise_provider.dart';
import 'presentation/providers/history_provider.dart';
import 'presentation/providers/dose_provider.dart';
import 'presentation/screens/settings_screen.dart';
import 'presentation/screens/reference_screen.dart';
import 'presentation/providers/analyzer_provider.dart';
import 'data/datasources/audio/pcm_capture.dart';
import 'data/datasources/audio/pcm_capture_macos.dart';
import 'core/services/audio_analyzer.dart';
import 'data/repositories/measurement_repository_impl.dart';
import 'domain/usecases/save_measurement.dart';
import 'domain/usecases/get_measurements.dart';
import 'domain/usecases/clear_measurements.dart';

import 'data/datasources/audio/noise_datasource.dart';
import 'data/repositories/noise_repository_impl.dart';
import 'domain/usecases/start_noise_listening.dart';
import 'domain/usecases/stop_noise_listening.dart';
import 'domain/usecases/get_noise_stream_usecase.dart';

void main() {
  // 确保 Flutter 框架已初始化
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DecibelApp());
}

class DecibelApp extends StatelessWidget {
  const DecibelApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 组装依赖（最简易 DI）
    final dataSource = NoiseDataSourceImpl();
    final repo = NoiseRepositoryImpl(dataSource);
    final start = StartNoiseListening(repo);
    final stop = StopNoiseListening(repo);
    final stream = GetNoiseStreamUseCase(repo);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => NoiseProvider(
            startListening: start,
            stopListening: stop,
            getNoiseStream: stream,
          ),
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            final hp = HistoryProvider(
              getNoiseStream: stream,
              saveMeasurement: SaveMeasurement(MeasurementRepositoryImpl()),
              getMeasurements: GetMeasurements(MeasurementRepositoryImpl()),
              clearMeasurements: ClearMeasurements(MeasurementRepositoryImpl()),
            );
            // 绑定设置快照（简化从 NoiseProvider 读取）
            final np = ctx.read<NoiseProvider>();
            hp.attachSettings(np.weighting, np.responseSpeed);
            // 启动订阅
            hp.start(stream);
            return hp;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final dp = DoseProvider(stream);
            dp.start();
            return dp;
          },
        ),
        ChangeNotifierProvider(
          create: (_) {
            final PcmCaptureSource source = Platform.isMacOS
                ? PcmCaptureMacOSDataSource()
                : (Platform.isWindows || Platform.isLinux)
                ? PcmCaptureDataSource()  // 桌面平台使用统一的移动端实现
                : PcmCaptureDataSource();
            final ap = AnalyzerProvider(
              source: source,
              analyzer: AudioAnalyzer(sampleRate: 44100, fftSize: 1024),
            );
            ap.start();
            return ap;
          },
        ),
      ],
      child: MaterialApp(
        title: '分贝测量仪',
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: ThemeMode.system,
        home: AppShell(
          home: const HomeScreen(),
          settings: const SettingsScreen(),
          reference: const ReferenceScreen(),
        ),
      ),
    );
  }
}

// 为了兼容模板测试 test/widget_test.dart 中对 MyApp 的引用
class MyApp extends DecibelApp {
  const MyApp({super.key});
}

// 应用外壳：底部导航切换 主页/设置/参考
class AppShell extends StatefulWidget {
  final Widget home;
  final Widget settings;
  final Widget reference;
  const AppShell({
    super.key,
    required this.home,
    required this.settings,
    required this.reference,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [widget.home, widget.settings, widget.reference];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '主页',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '设置',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: '参考',
          ),
        ],
      ),
    );
  }
}
