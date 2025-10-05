// 应用通用失败类型定义（领域无关的错误聚合）
// 说明：在全局用例、仓储与数据源之间传递明确的错误语义，便于 UI 友好提示
class AppFailure {
  // 人类可读的错误信息（用于 UI 展示）
  final String message;

  // 可选：错误码或分组标签（便于分类与统计）
  final String? code;

  // 可选：原始异常（调试/日志用途）
  final Object? cause;
  final StackTrace? stackTrace;

  const AppFailure(this.message, {this.code, this.cause, this.stackTrace});

  @override
  String toString() => 'AppFailure(code: $code, message: $message)';

  // 常见错误工厂
  factory AppFailure.permissionDenied([String? detail]) => AppFailure(
    '权限被拒绝${detail != null ? "：$detail" : ""}',
    code: 'permission_denied',
  );

  factory AppFailure.platformNotSupported([String? platform]) => AppFailure(
    '当前平台暂不支持音频分贝采集${platform != null ? "：$platform" : ""}',
    code: 'platform_unsupported',
  );

  factory AppFailure.serviceUnavailable([String? detail]) => AppFailure(
    '服务不可用${detail != null ? "：$detail" : ""}',
    code: 'service_unavailable',
  );

  factory AppFailure.unexpected(Object error, [StackTrace? st]) =>
      AppFailure('发生未知错误', code: 'unexpected', cause: error, stackTrace: st);
}
