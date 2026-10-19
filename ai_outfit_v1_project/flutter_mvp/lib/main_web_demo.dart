import 'package:flutter/material.dart';

import 'app.dart';
import 'data/app_state.dart';

/// 仅供 Web 截图 / 冒烟验证使用的入口。
///
/// 正式移动端入口是 `main.dart`；本文件通过 URL 参数跳过欢迎页或直接打开指定 Tab，
/// 方便无头浏览器在真实 Flutter Web 渲染下截图。不参与 Android/iOS 发布包。
void main() {
  final params = Uri.base.queryParameters;
  final tab = int.tryParse(params['tab'] ?? '') ?? 0;
  final state = AppState();
  if (params['welcome'] != '1') {
    state.markWelcomeSeen();
  }
  runApp(AiOutfitApp(appState: state, initialTab: tab));
}
