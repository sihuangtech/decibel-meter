// 平台工具：用于区分是否为移动端平台（Android/iOS）
// 中文说明：noise_meter 主要在移动端可用，桌面端需替代方案或给出提示
import 'dart:io' show Platform;

class PlatformUtils {
  static bool get isMobile => Platform.isAndroid || Platform.isIOS;
  static bool get isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}
