// 主题配置：Material3，支持深浅色
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      brightness: Brightness.light,
      fontFamily: 'NotoSansSC',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'NotoSansSC'),
    );
  }

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.teal,
        brightness: Brightness.dark,
      ),
      brightness: Brightness.dark,
      fontFamily: 'NotoSansSC',
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'NotoSansSC'),
    );
  }
}
