// 权限服务：统一处理跨平台麦克风权限申请与检查
// 说明：对上层隐藏具体平台差异，UI 只需调用 requestMicrophonePermission 即可
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// 申请麦克风权限，返回是否已授权
  static Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  /// 检查麦克风权限是否已授权
  static Future<bool> hasMicrophonePermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
}
