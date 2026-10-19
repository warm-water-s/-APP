import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../domain/garment.dart';
import '../../domain/outfit_state.dart';
import '../../theme/app_theme.dart';
import '../avatar_canvas.dart';
import 'login_page.dart';

/// UI-01 欢迎与首次引导。
class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.appState,
    this.forceShow = false,
  });

  final AppState appState;

  /// 从“我的 → 新手引导”再次打开时，进入按钮只关闭当前页面。
  final bool forceShow;

  void _enter(BuildContext context) {
    if (forceShow) {
      Navigator.of(context).pop();
      return;
    }
    appState.markWelcomeSeen();
  }

  Future<void> _login(BuildContext context) async {
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const LoginPage()),
    );
    if (loggedIn == true && context.mounted) {
      _enter(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closet = <String, Garment>{
      for (final garment in demoGarments) garment.id: garment,
    };
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            18,
            AppSpacing.page,
            24,
          ),
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.checkroom,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'AI 智能衣橱',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.avatarStage,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Text(
                    'V1.0 技术验证',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.primaryActive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.avatarStage,
                borderRadius: BorderRadius.circular(AppRadius.avatar),
              ),
              child: Center(
                child: AvatarCanvas(
                  outfit: CurrentOutfit(),
                  closet: closet,
                  onSlotTap: (_) {},
                  showHotspots: false,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '穿你拥有的，\n搭你喜欢的。',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
            ),
            const SizedBox(height: 10),
            const Text(
              '把你的真实衣橱变成 2D 穿搭工作台：固定一件衣服、选择风格，'
              '只从你已有的单品里找到下一套搭配。',
              style: TextStyle(
                fontSize: 13,
                height: 1.65,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              key: const Key('welcome-start'),
              onPressed: () => _enter(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(forceShow ? '返回' : '直接体验演示衣橱'),
            ),
            const SizedBox(height: 8),
            TextButton(
              key: const Key('welcome-login'),
              onPressed: () => _login(context),
              child: const Text('登录 / 注册（演示）'),
            ),
            const SizedBox(height: 10),
            const Text(
              '当前为本地演示版本：不连接真实账号、云端衣橱或 AI 服务。'
              '示例服装不会被伪装成你的真实衣物。',
              style: TextStyle(
                fontSize: 10,
                height: 1.55,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
