import 'package:flutter/material.dart';

import '../../data/app_state.dart';
import '../../data/demo_catalog.dart';
import '../../theme/app_theme.dart';
import 'privacy_page.dart';
import 'style_preferences_page.dart';
import 'welcome_page.dart';

/// UI-14 我的 / 个人中心。
class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.appState,
    required this.onOpenHome,
  });

  final AppState appState;
  final VoidCallback onOpenHome;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        appState,
        appState.wardrobe,
        appState.savedOutfits,
      ]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '我的',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              4,
              AppSpacing.page,
              32,
            ),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: AppColors.avatarStage,
                      child: const Icon(
                        Icons.person_outline,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '演示用户',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            '未连接账号系统 · 衣橱与收藏保存在本机',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _StatCard(
                      label: '衣橱单品',
                      value: '${appState.wardrobe.length}',
                      icon: Icons.checkroom,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: '收藏穿搭',
                      value: '${appState.savedOutfits.length}',
                      icon: Icons.favorite_border,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      label: '偏好风格',
                      value: '${appState.preferredStyles.length}',
                      icon: Icons.palette_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _MenuTile(
                key: const Key('profile-styles'),
                icon: Icons.tune,
                title: '风格偏好',
                subtitle: appState.preferredStyles.isEmpty
                    ? '未选择；仍可使用全部风格'
                    : appState.preferredStyles
                        .map((id) => styleNames[id] ?? id)
                        .join('、'),
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => StylePreferencesPage(appState: appState),
                    ),
                  );
                },
              ),
              _MenuTile(
                key: const Key('profile-privacy'),
                icon: Icons.privacy_tip_outlined,
                title: '隐私与数据说明',
                subtitle: '图片、AI 服务与账号数据边界',
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => PrivacyPage(appState: appState),
                    ),
                  );
                },
              ),
              _MenuTile(
                key: const Key('profile-guide'),
                icon: Icons.menu_book_outlined,
                title: '新手引导',
                subtitle: '重新查看 2D 衣橱介绍',
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => WelcomePage(
                        appState: appState,
                        forceShow: true,
                      ),
                    ),
                  );
                },
              ),
              _MenuTile(
                key: const Key('profile-about'),
                icon: Icons.info_outline,
                title: '关于演示版本',
                subtitle: 'V1.0 技术验证 · 数据保存在本机',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'AI 智能衣橱',
                    applicationVersion: '0.3.0（技术验证）',
                    children: const <Widget>[
                      Text(
                        '2D 虚拟换装 MVP。衣橱与收藏保存在本机；推荐与演示服装是本地规则数据，'
                        '不连接真实 AI、电商或后端服务。',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                key: const Key('profile-home'),
                onPressed: onOpenHome,
                icon: const Icon(Icons.home_outlined),
                label: const Text('回到首页继续搭配'),
              ),
              const SizedBox(height: 18),
              const Text(
                '当前版本不强制上传真人照片，也不采集身材信息。'
                '所有推荐仅基于你录入的衣橱数据。',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.55,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, size: 21, color: AppColors.primary),
        title: Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
