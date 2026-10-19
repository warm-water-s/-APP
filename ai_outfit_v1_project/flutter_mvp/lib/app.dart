import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'theme/app_theme.dart';
import 'ui/pages/home_page.dart';
import 'ui/pages/outfits_page.dart';
import 'ui/pages/profile_page.dart';
import 'ui/pages/wardrobe_page.dart';
import 'ui/pages/welcome_page.dart';

/// APP 根组件。AppState 在此创建，保证四个 Tab 共享同一份穿搭 / 衣橱 / 收藏状态。
class AiOutfitApp extends StatefulWidget {
  const AiOutfitApp({super.key, this.appState, this.initialTab = 0});

  /// 便于测试注入独立的 AppState；为空时由 APP 自己创建并释放。
  final AppState? appState;

  /// 调试 / 截图入口可直接打开指定 Tab；正式启动使用默认值 0。
  final int initialTab;

  @override
  State<AiOutfitApp> createState() => _AiOutfitAppState();
}

class _AiOutfitAppState extends State<AiOutfitApp> {
  late final AppState _appState;
  late final bool _ownsState;

  @override
  void initState() {
    super.initState();
    _appState = widget.appState ?? AppState();
    _ownsState = widget.appState == null;
  }

  @override
  void dispose() {
    if (_ownsState) _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 智能衣橱',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: AnimatedBuilder(
        animation: _appState,
        builder: (context, _) {
          if (!_appState.welcomeSeen) {
            return WelcomePage(appState: _appState);
          }
          return AppShell(
            appState: _appState,
            initialTab: widget.initialTab,
          );
        },
      ),
    );
  }
}

/// 四个一级导航：首页 / 衣橱 / 穿搭 / 我的。
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.appState, this.initialTab = 0});

  final AppState appState;
  final int initialTab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialTab.clamp(0, 3).toInt();

  late final List<Widget> _pages = <Widget>[
    HomePage(
      appState: widget.appState,
      onOpenSaved: () => _openTab(2),
    ),
    WardrobePage(
      appState: widget.appState,
      onOpenHome: () => _openTab(0),
    ),
    OutfitsPage(
      appState: widget.appState,
      onOpenHome: () => _openTab(0),
    ),
    ProfilePage(
      appState: widget.appState,
      onOpenHome: () => _openTab(0),
    ),
  ];

  void _openTab(int index) {
    if (_index == index) return;
    setState(() => _index = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _openTab,
        destinations: const <NavigationDestination>[
          NavigationDestination(
            key: Key('tab-home'),
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '首页',
          ),
          NavigationDestination(
            key: Key('tab-wardrobe'),
            icon: Icon(Icons.checkroom_outlined),
            selectedIcon: Icon(Icons.checkroom),
            label: '衣橱',
          ),
          NavigationDestination(
            key: Key('tab-outfits'),
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: '穿搭',
          ),
          NavigationDestination(
            key: Key('tab-profile'),
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
